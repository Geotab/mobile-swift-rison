import XCTest
@testable import SwiftRison

final class EncoderTests: XCTestCase {
    func testEncodeBasicTypes() throws {
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
        
        let value = AllTheTypes(bool: true,
                                string: "yass",
                                double: 2.2,
                                float: 1.1,
                                int: -1,
                                int8: -8,
                                int16: -16,
                                int32: -32,
                                int64: -64,
                                uint: 1,
                                uint8: 8,
                                uint16: 16,
                                uint32: 32,
                                uint64: 64)
        
        let encoder = RisonEncoder()
        try value.encode(to: encoder)
        var rison = encoder.risonString()
        
        let sortedKeyValuePairs = [
            "bool:!t",
            "double:2.2",
            "float:1.1",
            "int16:-16",
            "int32:-32",
            "int64:-64",
            "int8:-8",
            "int:-1",
            "string:yass",
            "uint16:16",
            "uint32:32",
            "uint64:64",
            "uint8:8",
            "uint:1",
        ]
        
        XCTAssertTrue(rison.hasPrefix("("))
        XCTAssertTrue(rison.hasSuffix(")"))
        
        rison.removeFirst()
        rison.removeLast()
        let sortedEncodedRison = rison.split(separator: ",").map({ String($0) }).sorted()
        
        XCTAssertEqual(sortedEncodedRison, sortedKeyValuePairs)
    }
    
    func testEncodeNil() throws {
        struct AllTheTypes: Codable {
            var bool: Bool?
            var string: String?
            var double: Double?
            
            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encodeNil(forKey: .bool)
                try container.encodeNil(forKey: .string)
                try container.encodeNil(forKey: .double)
            }
        }
        
        let value = AllTheTypes(bool: nil,
                                string: nil,
                                double: nil)
        
        
        let encoder = RisonEncoder()
        try value.encode(to: encoder)
        var rison = encoder.risonString()
        
        let sortedKeyValuePairs = [
            "bool:!n",
            "double:!n",
            "string:!n",
        ]
        
        XCTAssertTrue(rison.hasPrefix("("))
        XCTAssertTrue(rison.hasSuffix(")"))
        
        rison.removeFirst()
        rison.removeLast()
        let sortedEncodedRison = rison.split(separator: ",").map({ String($0) }).sorted()
        
        XCTAssertEqual(sortedEncodedRison, sortedKeyValuePairs)
    }
    
    func testEncodeEnum() throws {
        // swiftlint:disable nesting
        struct ObjectWithEnum: Codable {
            enum State: String, Codable {
                case active, canceled
            }
            var state: State
            var email: String
        }
        
        let value = ObjectWithEnum(state: .canceled, email: "mock@mock.com")
        let encoder = RisonEncoder()
        try value.encode(to: encoder)
        var rison = encoder.risonString()
        
        let sortedKeyValuePairs = [
            "email:mock@mock.com",
            "state:canceled",
        ]
        
        XCTAssertTrue(rison.hasPrefix("("))
        XCTAssertTrue(rison.hasSuffix(")"))
        
        rison.removeFirst()
        rison.removeLast()
        let sortedEncodedRison = rison.split(separator: ",").map({ String($0) }).sorted()
        
        XCTAssertEqual(sortedEncodedRison, sortedKeyValuePairs)
    }
    
    func testEncodeObject() throws {
        struct Person: Codable {
            var name: String
        }
        struct ComplexType: Codable {
            var person: Person
            var email: String
        }
        
        let value = ComplexType(person: Person(name: "mock"), email: "mock@mock.com")
        let encoder = RisonEncoder()
        try value.encode(to: encoder)
        var rison = encoder.risonString()
        
        let sortedKeyValuePairs = [
            "email:mock@mock.com",
            "person:(name:mock)",
        ]
        
        XCTAssertTrue(rison.hasPrefix("("))
        XCTAssertTrue(rison.hasSuffix(")"))
        
        rison.removeFirst()
        rison.removeLast()
        let sortedEncodedRison = rison.split(separator: ",").map({ String($0) }).sorted()
        
        XCTAssertEqual(sortedEncodedRison, sortedKeyValuePairs)
    }
    
    func testEncodeArray() throws {
        let value = ["c", "a", "b"]
        let encoder = RisonEncoder()
        
        try value.encode(to: encoder)
        
        XCTAssertEqual(encoder.risonString(), "!(c,a,b)")
    }
    
    func testEncodeNilArray() throws {
        var encoder = RisonEncoder()
        try [nil, "a", "b"].encode(to: encoder)
        XCTAssertEqual(encoder.risonString(), "!(!n,a,b)")
        
        encoder = RisonEncoder()
        try [nil, 1, 2].encode(to: encoder)
        XCTAssertEqual(encoder.risonString(), "!(!n,1,2)")
        
        encoder = RisonEncoder()
        try [nil, 1.1, 2.2].encode(to: encoder)
        XCTAssertEqual(encoder.risonString(), "!(!n,1.1,2.2)")
        
        encoder = RisonEncoder()
        try [nil, true, false].encode(to: encoder)
        XCTAssertEqual(encoder.risonString(), "!(!n,!t,!f)")
    }
    
    func testEncodeObjectWithArray() throws {
        struct Mock: Codable {
            var array: [Int]
            var email: String
        }
        let value = Mock(array: [1,2,3], email: "mock@mock.com")
        let encoder = RisonEncoder()
        
        try value.encode(to: encoder)
        
        let risonString = encoder.risonString()
        XCTAssertTrue(risonString.contains("email:mock@mock.com"))
        XCTAssertTrue(risonString.contains("array:!(1,2,3)"))
    }
    
    func testEncodeArrayOfObjects() throws {
        struct Mock: Codable {
            var name: String
        }
        let encoder = RisonEncoder()
        
        try [Mock(name:"one"), Mock(name: "two"), Mock(name: "three")].encode(to: encoder)
        
        XCTAssertEqual(encoder.risonString(), "!((name:one),(name:two),(name:three))")
    }
    
    func testEncodeWithInheritenceSuperKey() throws {
        class Person : Codable {
            var name: String?
            private enum CodingKeys : String, CodingKey { case name }
            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(name, forKey: .name)
            }
        }
        
        class Employee : Person {
            var employeeID: String?
            private enum CodingKeys : String, CodingKey { case employeeID = "emp_id" }
            override func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try super.encode(to: container.superEncoder())
                try container.encode(employeeID, forKey: .employeeID)
            }
        }
        
        let encoder = RisonEncoder()
        let employee = Employee()
        employee.name = "mockName"
        employee.employeeID = "mockID"
        
        try employee.encode(to: encoder)
        
        let sortedKeyValuePairs = [
            "emp_id:mockID",
            "super:(name:mockName)",
        ]
        
        var rison = encoder.risonString()
        
        XCTAssertTrue(rison.hasPrefix("("))
        XCTAssertTrue(rison.hasSuffix(")"))
        
        rison.removeFirst()
        rison.removeLast()
        let sortedEncodedRison = rison.split(separator: ",").map({ String($0) }).sorted()
        
        XCTAssertEqual(sortedEncodedRison, sortedKeyValuePairs)
    }
    
    func testEncodeWithInheritenceCustoSuperKey() throws {
        class Person : Codable {
            var name: String?
            private enum CodingKeys : String, CodingKey { case name }
            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(name, forKey: .name)
            }
        }
        
        class Employee : Person {
            var employeeID: String?
            private enum CodingKeys : String, CodingKey { case employeeID = "emp_id", person }
            override func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try super.encode(to: container.superEncoder(forKey: .person))
                try container.encode(employeeID, forKey: .employeeID)
            }
        }
        
        let encoder = RisonEncoder()
        let employee = Employee()
        employee.name = "mockName"
        employee.employeeID = "mockID"
        
        try employee.encode(to: encoder)

        let sortedKeyValuePairs = [
            "emp_id:mockID",
            "person:(name:mockName)",
        ]
        
        var rison = encoder.risonString()
        
        XCTAssertTrue(rison.hasPrefix("("))
        XCTAssertTrue(rison.hasSuffix(")"))
        
        rison.removeFirst()
        rison.removeLast()
        let sortedEncodedRison = rison.split(separator: ",").map({ String($0) }).sorted()
        
        XCTAssertEqual(sortedEncodedRison, sortedKeyValuePairs)
    }
    
    func testEncodeWithInheritenceUnkeyedSuper() throws {
        class Person : Codable {
            var name: String?
            func encode(to encoder: Encoder) throws {
                var container = encoder.unkeyedContainer()
                try container.encode(name)
            }
        }
        
        class Employee : Person {
            var employeeID: String?
            override func encode(to encoder: Encoder) throws {
                var container = encoder.unkeyedContainer()
                try super.encode(to: container.superEncoder())
                try container.encode(employeeID)
            }
        }
        
        let encoder = RisonEncoder()
        let employee = Employee()
        employee.name = "mockName"
        employee.employeeID = "mockID"
        
        try employee.encode(to: encoder)
        
        XCTAssertEqual(encoder.risonString(), "!(!(mockName),mockID)")
    }
    
    func testEncodeFlattenedObject() throws {
        struct Employee : Codable {
            var name: String?
            var employeeID: String?
            private enum CodingKeys: String, CodingKey { case employeeID = "emp_id", person }
            private enum PersonCodingKeys : String, CodingKey { case name }
            init(name: String? = nil, employeeID: String? = nil) {
                self.name = name
                self.employeeID = employeeID
            }
            init(from decoder: Decoder) throws { fatalError() }
            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                var personContainer = container.nestedContainer(keyedBy: PersonCodingKeys.self,
                                                                forKey: .person)
                try personContainer.encode(name, forKey: .name)
                try container.encode(employeeID, forKey: .employeeID)
            }
        }

        let encoder = RisonEncoder()
        let employee = Employee(name: "mockName", employeeID: "mockID")
        
        try employee.encode(to: encoder)
        
        let sortedKeyValuePairs = [
            "emp_id:mockID",
            "person:(name:mockName)",
        ]
        
        var rison = encoder.risonString()
        
        XCTAssertTrue(rison.hasPrefix("("))
        XCTAssertTrue(rison.hasSuffix(")"))
        
        rison.removeFirst()
        rison.removeLast()
        let sortedEncodedRison = rison.split(separator: ",").map({ String($0) }).sorted()
        
        XCTAssertEqual(sortedEncodedRison, sortedKeyValuePairs)
    }

    func testEncodeFlattenedObjectToUnkeyed() throws {
        struct Employee : Codable {
            var name: String?
            var employeeID: String?
            private enum CodingKeys: String, CodingKey { case employeeID = "emp_id", person }
            init(name: String? = nil, employeeID: String? = nil) {
                self.name = name
                self.employeeID = employeeID
            }
            init(from decoder: Decoder) throws { fatalError() }
            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                var personContainer = container.nestedUnkeyedContainer(forKey: .person)
                try personContainer.encode(name)
                try container.encode(employeeID, forKey: .employeeID)
            }
        }

        let encoder = RisonEncoder()
        let employee = Employee(name: "mockName", employeeID: "mockID")
        
        try employee.encode(to: encoder)
        
        let sortedKeyValuePairs = [
            "emp_id:mockID",
            "person:!(mockName)",
        ]
        
        var rison = encoder.risonString()
        
        XCTAssertTrue(rison.hasPrefix("("))
        XCTAssertTrue(rison.hasSuffix(")"))
        
        rison.removeFirst()
        rison.removeLast()
        let sortedEncodedRison = rison.split(separator: ",").map({ String($0) }).sorted()
        
        XCTAssertEqual(sortedEncodedRison, sortedKeyValuePairs)
    }

    func testUnkeyedEncodeFlattenedObject() throws {
        struct Employee : Codable {
            var name: String?
            var employeeID: String?
            private enum PersonCodingKeys : String, CodingKey { case name }
            func encode(to encoder: Encoder) throws {
                var container = encoder.unkeyedContainer()
                var personContainer = container.nestedContainer(keyedBy: PersonCodingKeys.self)
                try personContainer.encode(name, forKey: .name)
                try container.encode(employeeID)
            }
        }

        let encoder = RisonEncoder()
        let employee = Employee(name: "mockName", employeeID: "mockID")
        
        try employee.encode(to: encoder)
        
        XCTAssertEqual(encoder.risonString(), "!((name:mockName),mockID)")
    }

    func testUnkeyedEncodeFlattenedObjectToUnkeyed() throws {
        struct Employee : Codable {
            var name: String?
            var employeeID: String?
            func encode(to encoder: Encoder) throws {
                var container = encoder.unkeyedContainer()
                var personContainer = container.nestedUnkeyedContainer()
                try personContainer.encode(name)
                try container.encode(employeeID)
            }
        }

        let encoder = RisonEncoder()
        let employee = Employee(name: "mockName", employeeID: "mockID")
        
        try employee.encode(to: encoder)
        
        XCTAssertEqual(encoder.risonString(), "!(!(mockName),mockID)")
    }

    func testEncodeORison() throws {
        struct Mock: Codable {
            var array: [Int]
            var email: String
        }
        let value = Mock(array: [1,2,3], email: "mock@mock.com")
        let encoder = RisonEncoder(mode: .oRison)
        
        try value.encode(to: encoder)
        
        let risonString = encoder.risonString()
        
        XCTAssertFalse(risonString.hasPrefix("("))
        XCTAssertFalse(risonString.hasPrefix(")"))
        XCTAssertTrue(risonString.contains("email:mock@mock.com"))
        XCTAssertTrue(risonString.contains("array:!(1,2,3)"))
    }
    
    func testEncodeARison() throws {
        struct Mock: Codable {
            var name: String
        }
        let encoder = RisonEncoder(mode: .aRison)
        
        try [Mock(name:"one"), Mock(name: "two"), Mock(name: "three")].encode(to: encoder)
        
        XCTAssertEqual(encoder.risonString(), "(name:one),(name:two),(name:three)")
    }
    

}
