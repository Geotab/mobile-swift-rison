// swift-format-ignore-file

import XCTest
@testable import SwiftRison

final class ParserTests: XCTestCase {
    
    func testParseObject() throws {
        let risonString = "(works:!t,name:mockName,price:1.01)"
        let parser = RisonParser(rison: risonString)
        let result = try parser.parse()
        let obj = result as! RisonObject
        XCTAssertEqual(obj["works"] as? Bool, true)
        XCTAssertEqual(obj["name"] as? String, "mockName")
        XCTAssertEqual(obj["price"] as? RisonNumber, 1.01)
    }
    
    func testParseArray() throws {
        let risonString = "!(!t,mockName,1.01)"
        let parser = RisonParser(rison: risonString)
        let result = try parser.parse()
        let array = result as! RisonArray
        XCTAssertEqual(array.count, 3)
        XCTAssertEqual(array[0] as? Bool, true)
        XCTAssertEqual(array[1] as? String, "mockName")
        XCTAssertEqual(array[2] as? RisonNumber, 1.01)
    }
    
    func testParseTypes() throws {
        let risonString = "(isTrue:!t,isFalse:!f,isNil:!n,string:yass,double:2.2,float:1.1,int:-1,int8:-8,int16:-16,int32:-32,int64:-64,uint:1,uint8:8,uint16:16,uint32:32,uint64:64)"
        let parser = RisonParser(rison: risonString)
        let result = try parser.parse()
        let obj = result as! RisonObject
        XCTAssertEqual(obj["isTrue"] as? Bool, true)
        XCTAssertEqual(obj["isFalse"] as? Bool, false)
        XCTAssertNotNil(obj["isNil"] as? RisonNil)
        XCTAssertEqual(obj["string"] as? String, "yass")
        XCTAssertEqual(obj["double"] as? RisonNumber, 2.2)
        XCTAssertEqual(obj["float"] as? RisonNumber, 1.1)
        XCTAssertEqual(obj["int"] as? RisonNumber, -1)
        XCTAssertEqual(obj["int8"] as? RisonNumber, -8)
        XCTAssertEqual(obj["int16"] as? RisonNumber, -16)
        XCTAssertEqual(obj["int32"] as? RisonNumber, -32)
        XCTAssertEqual(obj["int64"] as? RisonNumber, -64)
        XCTAssertEqual(obj["uint"] as? RisonNumber, 1)
        XCTAssertEqual(obj["uint8"] as? RisonNumber, 8)
        XCTAssertEqual(obj["uint16"] as? RisonNumber, 16)
        XCTAssertEqual(obj["uint32"] as? RisonNumber, 32)
        XCTAssertEqual(obj["uint64"] as? RisonNumber, 64)
    }
    
    func testParseNestedObject() throws {
        let risonString = "(person:(name:mockName),email:mock%40email.com)"
        let parser = RisonParser(rison: risonString)
        let result = try parser.parse()
        let obj = result as! RisonObject
        let person = obj["person"] as! RisonObject
        XCTAssertEqual(person["name"] as? String, "mockName")
        XCTAssertEqual(obj["email"] as? String, "mock%40email.com")
    }
    
    func testParseDeeplyNestedObject() throws {
        let risonString = "(A:(B:(C:(D:E,F:G)),H:(I:(J:K,L:M))))"
        let parser = RisonParser(rison: risonString)
        let result = try parser.parse()
        
        // visually this is what the object should look like
        //
        // A: {
        //    B: {
        //        C: {
        //            D: 'E',
        //            F: 'G'
        //        }
        //    },
        //    H: {
        //        I: {
        //            J:'K',
        //            L:'M'
        //        }
        //    }
        // }
        
        let obj = result as! RisonObject

        guard let A = obj["A"] as? RisonObject,
              let B = A["B"] as? RisonObject,
              let C = B["C"] as? RisonObject,
              let H = A["H"] as? RisonObject,
              let I = H["I"] as? RisonObject else {
            fatalError()
        }
        XCTAssertEqual(C["D"] as? String, "E")
        XCTAssertEqual(C["F"] as? String, "G")
        XCTAssertEqual(I["J"] as? String, "K")
        XCTAssertEqual(I["L"] as? String, "M")
    }
    
    func testParseObjectWithArray() throws {
        let risonString = "(array:!(1,2,3),email:mock%40email.com)"
        let parser = RisonParser(rison: risonString)
        let result = try parser.parse()
        
        let obj = result as! RisonObject
        let array = obj["array"] as! RisonArray
        
        XCTAssertEqual(array.count, 3)
        XCTAssertEqual(array[0] as? RisonNumber, 1)
        XCTAssertEqual(array[1] as? RisonNumber, 2)
        XCTAssertEqual(array[2] as? RisonNumber, 3)
        XCTAssertEqual(obj["email"] as? String, "mock%40email.com")
    }
    
    func testParseArrayOfObjects() throws {
        let risonString = "!((name:one),(name:two),(name:three))"
        let parser = RisonParser(rison: risonString)
        let result = try parser.parse()
        
        let array = result as! RisonArray
        XCTAssertEqual(array.count, 3)

        let one = array[0] as! RisonObject
        let two = array[1] as! RisonObject
        let three = array[2] as! RisonObject

        XCTAssertEqual(one["name"] as? String, "one")
        XCTAssertEqual(two["name"] as? String, "two")
        XCTAssertEqual(three["name"] as? String, "three")
    }
    
    func testParseCredentials() throws {
        let risonString = "(target:Drive,credentials:(database:\'geotabdemo\',sessionId:\'MOCK_7YdQq7Bd62_s_MOCK\',userName:\'samltest\'),server:\'localhost:10001\')"
        let parser = RisonParser(rison: risonString)
        let result = try parser.parse()
        
        let obj = result as! RisonObject
        XCTAssertEqual(obj["target"] as? String, "Drive")
        XCTAssertEqual(obj["server"] as? String, "localhost:10001")

        let creds = obj["credentials"] as! RisonObject
        XCTAssertEqual(creds["database"] as? String, "geotabdemo")
        XCTAssertEqual(creds["sessionId"] as? String, "MOCK_7YdQq7Bd62_s_MOCK")
        XCTAssertEqual(creds["userName"] as? String, "samltest")
    }
}
