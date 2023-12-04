import XCTest
@testable import SwiftRison

final class DecoderTests: XCTestCase {
    
    func testDecodeBasicTypes() throws {
        struct AllTheTypes: Codable {
            var bool: Bool
            var string: String
            var double: Double
            var float: Float
            var int: Int
            var int8: Int8
            var int16: Int16
            var int32: Int32
            var int64: Int64
            var uint: UInt
            var uint8: UInt8
            var uint16: UInt16
            var uint32: UInt32
            var uint64: UInt64
        }
        
        let risonString = "(bool:!t,string:yass,double:2.2,float:1.1,int:-1,int8:-8,int16:-16,int32:-32,int64:-64,uint:1,uint8:8,uint16:16,uint32:32,uint64:64)"
        
        let decoder = RisonDecoder(risonString: risonString)
        let theDecoded = try AllTheTypes(from: decoder)

        XCTAssertEqual(theDecoded.bool, true)
        XCTAssertEqual(theDecoded.string, "yass")
        XCTAssertEqual(theDecoded.double, 2.2)
        XCTAssertEqual(theDecoded.float, 1.1)
        XCTAssertEqual(theDecoded.int, -1)
        XCTAssertEqual(theDecoded.int8, -8)
        XCTAssertEqual(theDecoded.int16, -16)
        XCTAssertEqual(theDecoded.int32, -32)
        XCTAssertEqual(theDecoded.int64, -64)
        XCTAssertEqual(theDecoded.uint, 1)
        XCTAssertEqual(theDecoded.uint8, 8)
        XCTAssertEqual(theDecoded.uint16, 16)
        XCTAssertEqual(theDecoded.uint32, 32)
        XCTAssertEqual(theDecoded.uint64, 64)
    }
    
    func testDecodeNil() throws {
        struct AllTheTypes: Codable {
            var bool: Bool?
            var string: String?
            var double: Double?
            var float: Float?
            var int: Int?
            var int8: Int8?
            var int16: Int16?
            var int32: Int32?
            var int64: Int64?
            var uint: UInt?
            var uint8: UInt8?
            var uint16: UInt16?
            var uint32: UInt32?
            var uint64: UInt64?
        }

        let risonString = "(bool:!n,string:!n,int16:16)"

        let decoder = RisonDecoder(risonString: risonString)
        let theDecoded = try AllTheTypes(from: decoder)
        XCTAssertNil(theDecoded.bool)
        XCTAssertNil(theDecoded.string)
        XCTAssertNil(theDecoded.double)
        XCTAssertNil(theDecoded.float)
        XCTAssertNil(theDecoded.int)
        XCTAssertNil(theDecoded.int8)
        XCTAssertEqual(theDecoded.int16, 16)
        XCTAssertNil(theDecoded.int32)
        XCTAssertNil(theDecoded.int64)
        XCTAssertNil(theDecoded.uint)
        XCTAssertNil(theDecoded.uint8)
        XCTAssertNil(theDecoded.uint16)
        XCTAssertNil(theDecoded.uint32)
        XCTAssertNil(theDecoded.uint64)
    }

    func testDecodeEnum() throws {
        // swiftlint:disable nesting
        struct ObjectWithEnum: Codable {
            enum State: String, Codable {
                case active, canceled
            }
            var state: State
            var email: String
        }
        // swiftlint:enable nesting
        let risonString = "(state:active,email:test%40email.com)"

        let decoder = RisonDecoder(risonString: risonString)
        let obj = try ObjectWithEnum(from: decoder)
        
        XCTAssertEqual(obj.email, "test%40email.com")
        XCTAssertEqual(obj.state, ObjectWithEnum.State.active)
    }

    func testDecodeObject() throws {
        struct Person: Codable {
            var name: String
        }
        struct ComplexType: Codable {
            var person: Person
            var email: String
        }
        let risonString = "(person:(name:mock),email:test%40email.com)"

        let decoder = RisonDecoder(risonString: risonString)
        let obj = try ComplexType(from: decoder)
        
        XCTAssertEqual(obj.email, "test%40email.com")
        XCTAssertEqual(obj.person.name, "mock")
    }

    func testDecodeArray() throws {
        let risonString = "!(a,b,c)"
        let decoder = RisonDecoder(risonString: risonString)
        
        let array = try [String](from: decoder)
        
        XCTAssertEqual(array.count, 3)
        XCTAssertEqual(array[0], "a")
        XCTAssertEqual(array[1], "b")
        XCTAssertEqual(array[2], "c")
    }

    func testDecodeNilArray() throws {
        let risonString = "!(a,!n,c)"
        let decoder = RisonDecoder(risonString: risonString)
        
        let array = try [String?](from: decoder)
        
        XCTAssertEqual(array.count, 3)
        XCTAssertEqual(array[0], "a")
        XCTAssertNil(array[1])
        XCTAssertEqual(array[2], "c")
    }
    
    func testDecodeObjectWithArray() throws {
        struct Mock: Codable {
            var array: [Int]
            var email: String
        }
        let risonString = "(array:!(1,2,3),email:mock%40email.com)"

        let decoder = RisonDecoder(risonString: risonString)
        let obj = try Mock(from: decoder)
        
        XCTAssertEqual(obj.email, "mock%40email.com")
        XCTAssertEqual(obj.array.count, 3)
        XCTAssertEqual(obj.array[0], 1)
        XCTAssertEqual(obj.array[1], 2)
        XCTAssertEqual(obj.array[2], 3)
    }

    func testDecodeArrayOfObjects() throws {
        struct Mock: Codable {
            var name: String
        }
        let risonString = "!((name:one),(name:two),(name:three))"

        let decoder = RisonDecoder(risonString: risonString)
        let array = try [Mock](from: decoder)
        
        XCTAssertEqual(array.count, 3)
        XCTAssertEqual(array[0].name, "one")
        XCTAssertEqual(array[1].name, "two")
        XCTAssertEqual(array[2].name, "three")
    }
    
    func testDecodeCredentials() throws {

        struct Creds: Codable {
            var database: String
            var sessionId: String
            var userName: String
        }

        struct Mock: Codable {
            var target: String
            var server: String
            var credentials: Creds
        }
        
        let risonString = "(target:Drive,credentials:(database:\'geotabdemo\',sessionId:\'MOCK_7YdQq7Bd62_s_MOCK\',userName:\'samltest\'),server:\'localhost:10001\')"

        let decoder = RisonDecoder(risonString: risonString)
        let obj = try Mock(from: decoder)

        XCTAssertEqual(obj.target, "Drive")
        XCTAssertEqual(obj.server, "localhost:10001")
        XCTAssertEqual(obj.credentials.database, "geotabdemo")
        XCTAssertEqual(obj.credentials.sessionId, "MOCK_7YdQq7Bd62_s_MOCK")
        XCTAssertEqual(obj.credentials.userName, "samltest")
    }
    
    func testDecodeWithInheritenceSuperKey() throws {
        class Person : Codable {
            var name: String?
            private enum CodingKeys : String, CodingKey { case name }
            required init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                self.name = try container.decodeIfPresent(String.self, forKey: .name)
            }
        }
        
        class Employee : Person {
            var employeeID: String?
            private enum CodingKeys : String, CodingKey { case employeeID = "emp_id" }
            required init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                try super.init(from: container.superDecoder())
                self.employeeID = try container.decodeIfPresent(String.self, forKey: .employeeID)
            }
        }
        
        let risonString = "(emp_id:mockID,super:(name:mockName))"

        let decoder = RisonDecoder(risonString: risonString)
        let employee = try Employee(from: decoder)

        XCTAssertEqual(employee.employeeID, "mockID")
        XCTAssertEqual(employee.name, "mockName")
    }
    
    func testDecodeWithInheritenceCustomSuperKey() throws {
        class Person : Codable {
            var name: String?
            private enum CodingKeys : String, CodingKey { case name }
            required init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                self.name = try container.decodeIfPresent(String.self, forKey: .name)
            }
        }
        
        class Employee : Person {
            var employeeID: String?
            private enum CodingKeys : String, CodingKey { case employeeID = "emp_id", person }
            required init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                try super.init(from: container.superDecoder(forKey: .person))
                self.employeeID = try container.decodeIfPresent(String.self, forKey: .employeeID)
            }
        }
        
        let risonString = "(emp_id:mockID,person:(name:mockName))"

        let decoder = RisonDecoder(risonString: risonString)
        let employee = try Employee(from: decoder)

        XCTAssertEqual(employee.employeeID, "mockID")
        XCTAssertEqual(employee.name, "mockName")
    }


    func testDecodeWithInheritenceUnkeyedSuper() throws {
        class Person : Codable {
            var name: String?
            required init(from decoder: Decoder) throws {
                var container = try decoder.unkeyedContainer()
                self.name = try container.decode(String.self)
            }
        }

        class Employee : Person {
            var employeeID: String?
            required init(from decoder: Decoder) throws {
                var container = try decoder.unkeyedContainer()
                try super.init(from: container.superDecoder())
                self.employeeID = try container.decode(String.self)
            }
        }

        let risonString = "!(!(mockName),mockID)"
        
        let decoder = RisonDecoder(risonString: risonString)
        let employee = try Employee(from: decoder)
        
        XCTAssertEqual(employee.employeeID, "mockID")
        XCTAssertEqual(employee.name, "mockName")
    }
    
    func testDecodeFlattenedObject() throws {
        struct Employee : Codable {
            var name: String?
            var employeeID: String?
            private enum CodingKeys: String, CodingKey { case employeeID = "emp_id", person }
            private enum PersonCodingKeys : String, CodingKey { case name }
            func encode(to encoder: Encoder) throws { fatalError() }
            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                let personContainer = try container.nestedContainer(keyedBy: PersonCodingKeys.self,
                                                                    forKey: .person)
                name = try personContainer.decodeIfPresent(String.self, forKey: .name)
                employeeID = try container.decodeIfPresent(String.self, forKey: .employeeID)
            }
        }
        
        let risonString = "(emp_id:mockID,person:(name:mockName))"
        
        let decoder = RisonDecoder(risonString: risonString)
        let employee = try Employee(from: decoder)
        
        XCTAssertEqual(employee.employeeID, "mockID")
        XCTAssertEqual(employee.name, "mockName")
    }
    
    func testDecodeFlattenedObjectUnkeyed() throws {
        struct Employee : Codable {
            var name: String?
            var employeeID: String?
            private enum CodingKeys: String, CodingKey { case employeeID = "emp_id", person }
            func encode(to encoder: Encoder) throws { fatalError() }
            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                var personContainer = try container.nestedUnkeyedContainer(forKey: .person)
                name = try personContainer.decode(String.self)
                employeeID = try container.decodeIfPresent(String.self, forKey: .employeeID)
            }
        }

        let risonString = "(emp_id:mockID,person:!(mockName))"

        let decoder = RisonDecoder(risonString: risonString)
        let employee = try Employee(from: decoder)

        XCTAssertEqual(employee.employeeID, "mockID")
        XCTAssertEqual(employee.name, "mockName")
    }
    
    func testDecodeFlattenedObjectFromUnkeyed() throws {
        struct Employee : Codable {
            var name: String?
            var employeeID: String?
            func encode(to encoder: Encoder) throws { fatalError() }
            init(from decoder: Decoder) throws {
                var container = try decoder.unkeyedContainer()
                employeeID = try container.decodeIfPresent(String.self)
                var personContainer = try container.nestedUnkeyedContainer()
                name = try personContainer.decodeIfPresent(String.self)
            }
        }

        let risonString = "!(mockID,!(mockName))"

        let decoder = RisonDecoder(risonString: risonString)
        let employee = try Employee(from: decoder)

        XCTAssertEqual(employee.employeeID, "mockID")
        XCTAssertEqual(employee.name, "mockName")
    }

    func testDecodeUnkeyedFlattenedObjectFromKeyed() throws {
        struct Employee : Codable {
            var name: String?
            var employeeID: String?
            private enum PersonCodingKeys : String, CodingKey { case name }
            func encode(to encoder: Encoder) throws { fatalError() }
            init(from decoder: Decoder) throws {
                var container = try decoder.unkeyedContainer()
                employeeID = try container.decodeIfPresent(String.self)
                let personContainer = try container.nestedContainer(keyedBy: PersonCodingKeys.self)
                name = try personContainer.decodeIfPresent(String.self, forKey: .name)
            }
        }

        let risonString = "!(mockID,(name:mockName))"

        let decoder = RisonDecoder(risonString: risonString)
        let employee = try Employee(from: decoder)

        XCTAssertEqual(employee.employeeID, "mockID")
        XCTAssertEqual(employee.name, "mockName")
    }

    func testDecodeORison() throws {
        struct Mock: Codable {
            var array: [Int]
            var email: String
        }
        let risonString = "array:!(1,2,3),email:mock%40email.com"

        let decoder = RisonDecoder(mode: .oRison, risonString: risonString)
        let obj = try Mock(from: decoder)
        
        XCTAssertEqual(obj.email, "mock%40email.com")
        XCTAssertEqual(obj.array.count, 3)
        XCTAssertEqual(obj.array[0], 1)
        XCTAssertEqual(obj.array[1], 2)
        XCTAssertEqual(obj.array[2], 3)
    }

    func testDecodeARison() throws {
        struct Mock: Codable {
            var name: String
        }
        let risonString = "(name:one),(name:two),(name:three)"

        let decoder = RisonDecoder(mode: .aRison, risonString: risonString)
        let array = try [Mock](from: decoder)

        XCTAssertEqual(array.count, 3)
        XCTAssertEqual(array[0].name, "one")
        XCTAssertEqual(array[1].name, "two")
        XCTAssertEqual(array[2].name, "three")
    }

}
