//
//  JsonValueTests.swift
//  
//

import XCTest
@testable import JsonModel

final class JsonValueTests: XCTestCase {
    
    func testNSString_jsonObject() {
        let obj = NSString(string: "foo")
        let json = obj.jsonObject()
        XCTAssertEqual(json as? String, "foo")
        XCTAssertTrue(JSONSerialization.isValidJSONObject([json]))
    }

    func testString_jsonObject() {
        let obj = "foo"
        let json = obj.jsonObject()
        XCTAssertEqual(json as? String, "foo")
        XCTAssertTrue(JSONSerialization.isValidJSONObject([json]))
    }
    
    func testNSNumber_jsonObject() {
        let obj = NSNumber(value: 4)
        let json = obj.jsonObject()
        XCTAssertEqual((json as? NSNumber)?.intValue, 4)
        XCTAssertTrue(JSONSerialization.isValidJSONObject([json]))
    }
    
    func testInt_jsonObject() {
        let obj: Int = 4
        let json = obj.jsonObject()
        XCTAssertEqual((json as? NSNumber)?.intValue, 4)
        XCTAssertTrue(JSONSerialization.isValidJSONObject([json]))
    }

    func testInt8_jsonObject() {
        let obj: Int8 = 4
        let json = obj.jsonObject()
        XCTAssertEqual((json as? NSNumber)?.intValue, 4)
        XCTAssertTrue(JSONSerialization.isValidJSONObject([json]))
    }

    func testInt16_jsonObject() {
        let obj: Int16 = 4
        let json = obj.jsonObject()
        XCTAssertEqual((json as? NSNumber)?.intValue, 4)
        XCTAssertTrue(JSONSerialization.isValidJSONObject([json]))
    }

    func testInt32_jsonObject() {
        let obj: Int32 = 4
        let json = obj.jsonObject()
        XCTAssertEqual((json as? NSNumber)?.intValue, 4)
        XCTAssertTrue(JSONSerialization.isValidJSONObject([json]))
    }

    func testInt64_jsonObject() {
        let obj: Int64 = 4
        let json = obj.jsonObject()
        XCTAssertEqual((json as? NSNumber)?.intValue, 4)
        XCTAssertTrue(JSONSerialization.isValidJSONObject([json]))
    }

    func testUInt_jsonObject() {
        let obj: UInt = 4
        let json = obj.jsonObject()
        XCTAssertEqual((json as? NSNumber)?.intValue, 4)
        XCTAssertTrue(JSONSerialization.isValidJSONObject([json]))
    }

    func testUInt8_jsonObject() {
        let obj: UInt8 = 4
        let json = obj.jsonObject()
        XCTAssertEqual((json as? NSNumber)?.intValue, 4)
        XCTAssertTrue(JSONSerialization.isValidJSONObject([json]))
    }

    func testUInt16_jsonObject() {
        let obj: UInt16 = 4
        let json = obj.jsonObject()
        XCTAssertEqual((json as? NSNumber)?.intValue, 4)
        XCTAssertTrue(JSONSerialization.isValidJSONObject([json]))
    }

    func testUInt32_jsonObject() {
        let obj: UInt32 = 4
        let json = obj.jsonObject()
        XCTAssertEqual((json as? NSNumber)?.intValue, 4)
        XCTAssertTrue(JSONSerialization.isValidJSONObject([json]))
    }

    func testUInt64_jsonObject() {
        let obj: UInt64 = 4
        let json = obj.jsonObject()
        XCTAssertEqual((json as? NSNumber)?.intValue, 4)
        XCTAssertTrue(JSONSerialization.isValidJSONObject([json]))
    }

    func testBool_jsonObject() {
        let obj: Bool = true
        let json = obj.jsonObject()
        XCTAssertEqual((json as? NSNumber)?.boolValue, true)
        XCTAssertTrue(JSONSerialization.isValidJSONObject([json]))
    }

    func testDouble_jsonObject() {
        let obj: Double = 1.4
        let json = obj.jsonObject()
        XCTAssertEqual((json as? NSNumber)?.doubleValue, 1.4)
        XCTAssertTrue(JSONSerialization.isValidJSONObject([json]))
    }
    
    func testFloat_jsonObject() {
        let obj: Float = 1.4
        let json = obj.jsonObject()
        XCTAssertEqual((json as? NSNumber)?.floatValue, 1.4)
        XCTAssertTrue(JSONSerialization.isValidJSONObject([json]))
    }
    
    func testNSNull_jsonObject() {
        let obj: NSNull = NSNull()
        let json = obj.jsonObject()
        XCTAssertNotNil(json as? NSNull)
        XCTAssertTrue(JSONSerialization.isValidJSONObject([json]))
    }
    
    func testNSDate_jsonObject() {
        let now = Date()
        let obj: NSDate = now as NSDate
        let json = obj.jsonObject()
        XCTAssertNotNil(json as? String)
        XCTAssertTrue(JSONSerialization.isValidJSONObject([json]))
    }
    
    func testDate_jsonObject() {
        let now = Date()
        let obj: Date = now
        let json = obj.jsonObject()
        XCTAssertNotNil(json as? String)
        XCTAssertTrue(JSONSerialization.isValidJSONObject([json]))
    }
    
    func testData_jsonObject() {
        let data = Data(base64Encoded: "ABC4")!
        let obj: Data = data
        let json = obj.jsonObject()
        XCTAssertEqual(json as? String, "ABC4")
        XCTAssertTrue(JSONSerialization.isValidJSONObject([json]))
    }
    
    func testNSData_jsonObject() {
        let data = Data(base64Encoded: "ABC4")!
        let obj: NSData = data as NSData
        let json = obj.jsonObject()
        XCTAssertEqual(json as? String, "ABC4")
        XCTAssertTrue(JSONSerialization.isValidJSONObject([json]))
    }
    
    func testUUID_jsonObject() {
        let uuid = UUID()
        let obj: UUID = uuid
        let json = obj.jsonObject()
        XCTAssertEqual(json as? String, uuid.uuidString)
        XCTAssertTrue(JSONSerialization.isValidJSONObject([json]))
    }
    
    func testNSUUID_jsonObject() {
        let uuid = UUID()
        let obj: NSUUID = uuid as NSUUID
        let json = obj.jsonObject()
        XCTAssertEqual(json as? String, uuid.uuidString)
        XCTAssertTrue(JSONSerialization.isValidJSONObject([json]))
    }
    
    func testURL_jsonObject() {
        let url = URL(string: "https://foo.org")!
        let obj: URL = url
        let json = obj.jsonObject()
        XCTAssertEqual(json as? String, "https://foo.org")
        XCTAssertTrue(JSONSerialization.isValidJSONObject([json]))
    }
    
    func testNSURL_jsonObject() {
        let url = URL(string: "https://foo.org")!
        let obj: NSURL = url as NSURL
        let json = obj.jsonObject()
        XCTAssertEqual(json as? String, "https://foo.org")
        XCTAssertTrue(JSONSerialization.isValidJSONObject([json]))
    }
    
    func testNSDictionary_jsonObject() {
        let date = Date()
        let url = URL(string: "https://foo.org")!
        let data = Data(base64Encoded: "ABC4")!
        let uuid = UUID()
        let barUUID = UUID()
        let gooUUID = UUID()
        
        let dictionary: [Int : Any ] = [
            0 : [ ["identifier" : "bar",
                   "items" : [ ["index" : NSNumber(value: 0)],
                               ["index" : NSNumber(value: 1)],
                               ["index" : NSNumber(value: 2)]]] as [String : Any],
                  ["identifier" : "goo"]
            ],
            1 : [ "date" : date, "url" : url, "data" : data, "uuid" : uuid, "null" : NSNull()] as [String : Any],
            2 : [ ["item" : "bar", "uuid" : barUUID] as [String : Any], ["item" : "goo", "uuid" : gooUUID]],
        ]
    
        let ns_json = (dictionary as NSDictionary).jsonObject()
        let json = dictionary.jsonObject()
        
        XCTAssertTrue(JSONSerialization.isValidJSONObject(json))
        XCTAssertTrue(JSONSerialization.isValidJSONObject(ns_json))
        
        let expectedDate = ISO8601TimestampFormatter.string(from: date)
        let expectedJSON: NSDictionary = [
            "0" : [ ["identifier" : "bar",
                   "items" : [ ["index" : NSNumber(value: 0)],
                               ["index" : NSNumber(value: 1)],
                               ["index" : NSNumber(value: 2)]]] as [String : Any],
                  ["identifier" : "goo"]
            ],
            "1" : [ "date" : expectedDate, "url" : "https://foo.org", "data" : "ABC4", "uuid" : uuid.uuidString, "null" : NSNull()] as [String : Any],
            "2" : [ ["item" : "bar", "uuid" : barUUID.uuidString,], ["item" : "goo", "uuid" : gooUUID.uuidString,]],
        ]
        
        XCTAssertEqual(ns_json as? NSDictionary, expectedJSON)
        XCTAssertEqual(json as? NSDictionary, expectedJSON)
    }
    
    func testSet_jsonObject() {
        let uuid1 = UUID()
        let uuid2 = UUID()
        let uuid3 = UUID()
        
        let obj = Set([uuid1, uuid2, uuid3])
        let json = obj.jsonObject()
        if let arr = json as? [JsonSerializable] {
            XCTAssertEqual(arr.count, 3)
        }
        else {
            XCTFail("\(json) not of expected cast.")
        }
        XCTAssertTrue(JSONSerialization.isValidJSONObject(json))
    }
}
