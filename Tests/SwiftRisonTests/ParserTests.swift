// swift-format-ignore-file

import XCTest
@testable import SwiftRison

final class ParserTests: XCTestCase {
    func testParseEmptyObject() throws {
        let risonString = "()"
        let parser = RisonParser(rison: risonString)
        let result = try parser.parse()
        XCTAssertTrue(result is RisonObject)
        XCTAssertEqual((result as! RisonObject).count, 0)
    }

    func testParseEmptyArray() throws {
        let risonString = "!()"
        let parser = RisonParser(rison: risonString)
        let result = try parser.parse()
        XCTAssertTrue(result is RisonArray)
        XCTAssertEqual((result as! RisonArray).count, 0)
    }

    func testParseTrue() throws {
        let risonString = "!t"
        let parser = RisonParser(rison: risonString)
        let result = try parser.parse()
        XCTAssertEqual(result as? Bool, true)
    }

    func testParseFalse() throws {
        let risonString = "!f"
        let parser = RisonParser(rison: risonString)
        let result = try parser.parse()
        XCTAssertEqual(result as? Bool, false)
    }

    func testParseNull() throws {
        let risonString = "!n"
        let parser = RisonParser(rison: risonString)
        let result = try parser.parse()
        XCTAssertNotNil(result as? RisonNil)
    }

    func testParseZero() throws {
        let risonString = "0"
        let parser = RisonParser(rison: risonString)
        let result = try parser.parse()
        XCTAssertEqual(result as? RisonNumber, 0)
    }

    func testParseNegativeInt() throws {
        let risonString = "-42"
        let parser = RisonParser(rison: risonString)
        let result = try parser.parse()
        XCTAssertEqual(result as? RisonNumber, -42)
    }

    func testParseFloat() throws {
        let risonString = "3.1415"
        let parser = RisonParser(rison: risonString)
        let result = try parser.parse()
        XCTAssertEqual(result as? RisonNumber, 3.1415)
    }

    func testParseSimpleString() throws {
        let risonString = "hello"
        let parser = RisonParser(rison: risonString)
        let result = try parser.parse()
        XCTAssertEqual(result as? String, "hello")
    }

    func testParseQuotedString() throws {
        let risonString = "'hello world'"
        let parser = RisonParser(rison: risonString)
        let result = try parser.parse()
        XCTAssertEqual(result as? String, "hello world")
    }

    func testParseStringWithSpecialChars() throws {
        let risonString = "'foo!!@bar'"
        let parser = RisonParser(rison: risonString)
        let result = try parser.parse()
        XCTAssertEqual(result as? String, "foo!@bar")
    }

    func testParsePercentEncodedString() throws {
        let risonString = "mock%20name"
        let parser = RisonParser(rison: risonString)
        let result = try parser.parse()
        XCTAssertEqual(result as? String, "mock%20name")
    }

    func testParseObjectWithMixedTypes() throws {
        let risonString = "(a:1,b:!t,c:'str',d:!n)"
        let parser = RisonParser(rison: risonString)
        let result = try parser.parse()
        let obj = result as! RisonObject
        XCTAssertEqual(obj["a"] as? RisonNumber, 1)
        XCTAssertEqual(obj["b"] as? Bool, true)
        XCTAssertEqual(obj["c"] as? String, "str")
        XCTAssertNotNil(obj["d"] as? RisonNil)
    }

    func testParseArrayWithMixedTypes() throws {
        let risonString = "!(1,!f,'abc',!n)"
        let parser = RisonParser(rison: risonString)
        let result = try parser.parse()
        let arr = result as! RisonArray
        XCTAssertEqual(arr[0] as? RisonNumber, 1)
        XCTAssertEqual(arr[1] as? Bool, false)
        XCTAssertEqual(arr[2] as? String, "abc")
        XCTAssertNotNil(arr[3] as? RisonNil)
    }

    func testParseNestedArray() throws {
        let risonString = "!(!(!t),!(!f))"
        let parser = RisonParser(rison: risonString)
        let result = try parser.parse()
        let arr2 = result as! RisonArray
        XCTAssertEqual((arr2[0] as! RisonArray)[0] as? Bool, true)
        XCTAssertEqual((arr2[1] as! RisonArray)[0] as? Bool, false)
    }

    func testParseNestedObjectVariant() throws {
        let risonString = "(outer:(inner:123))"
        let parser = RisonParser(rison: risonString)
        let result = try parser.parse()
        let obj2 = result as! RisonObject
        let inner = (obj2["outer"] as! RisonObject)["inner"] as? RisonNumber
        XCTAssertEqual(inner, 123)
    }

    func testParseObjectWithArrayValue() throws {
        let risonString = "(arr:!(a,b,c))"
        let parser = RisonParser(rison: risonString)
        let result = try parser.parse()
        let obj3 = result as! RisonObject
        let arr3 = obj3["arr"] as! RisonArray
        XCTAssertEqual(arr3[0] as? String, "a")
        XCTAssertEqual(arr3[1] as? String, "b")
        XCTAssertEqual(arr3[2] as? String, "c")
    }

    func testParseArrayOfObjectsVariant() throws {
        let risonString = "!((x:1),(y:2))"
        let parser = RisonParser(rison: risonString)
        let result = try parser.parse()
        let arr4 = result as! RisonArray
        XCTAssertEqual((arr4[0] as! RisonObject)["x"] as? RisonNumber, 1)
        XCTAssertEqual((arr4[1] as! RisonObject)["y"] as? RisonNumber, 2)
    }

    func testParseEmptyString() throws {
        let risonString = "''"
        let parser = RisonParser(rison: risonString)
        let result = try parser.parse()
        XCTAssertEqual(result as? String, "")
    }

    // MARK: - Escaped strings

    func testParseEscapedApostropheInString() throws {
        // Rison uses !' to escape a single quote inside quoted strings
        let risonString = "'it!'s ok'"
        let parser = RisonParser(rison: risonString)
        let result = try parser.parse()
        XCTAssertEqual(result as? String, "it's ok")
    }

    func testParseEscapedExclamationInString() throws {
        // Rison uses !! to escape an exclamation mark inside quoted strings
        let risonString = "'bang!!bang'"
        let parser = RisonParser(rison: risonString)
        let result = try parser.parse()
        XCTAssertEqual(result as? String, "bang!bang")
    }

    func testParseMixedEscapesInString() throws {
        // Both !! (for !) and !' (for ') in the same string
        let risonString = "'mix!! and !'quote'"
        let parser = RisonParser(rison: risonString)
        let result = try parser.parse()
        XCTAssertEqual(result as? String, "mix! and 'quote")
    }

    func testParseUnicodeString() throws {
        let risonString = "'héllo ☕️'"
        let parser = RisonParser(rison: risonString)
        let result = try parser.parse()
        XCTAssertEqual(result as? String, "héllo ☕️")
    }

    // MARK: - Complex objects

    func testParseComplexObjectWithEscapesAndNested() throws {
        let risonString = "(title:'O!'Reilly',paths:!('/a/b','/c/d'),options:(limit:100,offset:0,filters:!((k:'tag',op:'=',v:'hot !'n spicy'),(k:'size',op:'>',v:10))),emptyObj:(),emptyArr:!())"
        let parser = RisonParser(rison: risonString)
        let result = try parser.parse()
        let obj = result as! RisonObject

        XCTAssertEqual(obj["title"] as? String, "O'Reilly")

        let paths = obj["paths"] as! RisonArray
        XCTAssertEqual(paths.count, 2)
        XCTAssertEqual(paths[0] as? String, "/a/b")
        XCTAssertEqual(paths[1] as? String, "/c/d")

        let options = obj["options"] as! RisonObject
        XCTAssertEqual(options["limit"] as? RisonNumber, 100)
        XCTAssertEqual(options["offset"] as? RisonNumber, 0)

        let filters = options["filters"] as! RisonArray
        XCTAssertEqual(filters.count, 2)
        let f0 = filters[0] as! RisonObject
        let f1 = filters[1] as! RisonObject
        XCTAssertEqual(f0["k"] as? String, "tag")
        XCTAssertEqual(f0["op"] as? String, "=")
        XCTAssertEqual(f0["v"] as? String, "hot 'n spicy")
        XCTAssertEqual(f1["k"] as? String, "size")
        XCTAssertEqual(f1["op"] as? String, ">")
        XCTAssertEqual(f1["v"] as? RisonNumber, 10)

        XCTAssertTrue(obj["emptyObj"] is RisonObject)
        XCTAssertEqual((obj["emptyArr"] as! RisonArray).count, 0)
    }

    func testParseObjectWithQuotedKeys() throws {
        let risonString = "('spaced key':1,'hy-phen':2,'dot.key':3)"
        let parser = RisonParser(rison: risonString)
        let result = try parser.parse()
        let obj = result as! RisonObject
        XCTAssertEqual(obj["spaced key"] as? RisonNumber, 1)
        XCTAssertEqual(obj["hy-phen"] as? RisonNumber, 2)
        XCTAssertEqual(obj["dot.key"] as? RisonNumber, 3)
    }
    
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
    
    func testParseCredsWithApostrophes() throws {
        let risonString = "(credentials:(database:mock,sessionId:abc123,userName:'test!'ios@mock.org'),server:my.geotab.com)"
        let parser = RisonParser(rison: risonString)
        let result = try parser.parse()
        
        let obj = result as! RisonObject
        XCTAssertEqual(obj["server"] as? String, "my.geotab.com")

        let creds = obj["credentials"] as! RisonObject
        XCTAssertEqual(creds["database"] as? String, "mock")
        XCTAssertEqual(creds["sessionId"] as? String, "abc123")
        XCTAssertEqual(creds["userName"] as? String, "test'ios@mock.org")
    }
}
