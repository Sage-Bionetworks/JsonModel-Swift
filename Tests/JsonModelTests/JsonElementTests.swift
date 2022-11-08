//
//  JsonElementTests.swift
//  

import XCTest
@testable import JsonModel

final class JsonElementTests: XCTestCase {

    func testString() {
        let original = JsonElement("foo")
        XCTAssertEqual(JsonElement.string("foo"), original)
        XCTAssertNotEqual(JsonElement.string("boo"), original)
        
        let factory = SerializationFactory.defaultFactory
        let decoder = factory.createJSONDecoder()
        do {
            let object = try decoder.decode(SampleType.self, from: original)
            XCTAssertEqual(SampleType(rawValue: "foo"), object)
            
            let encoded = try object.jsonElement()
            XCTAssertEqual(original, encoded)
            
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    func testInt() {
        let original = JsonElement(3)
        XCTAssertEqual(JsonElement.integer(3), original)
        XCTAssertNotEqual(JsonElement.number(3.2), original)
        XCTAssertTrue(3 == original)
        XCTAssertFalse(3.2 == original)
        
        let factory = SerializationFactory.defaultFactory
        let decoder = factory.createJSONDecoder()
        do {
            let object = try decoder.decode(SampleIntEnum.self, from: original)
            XCTAssertEqual(.three, object)
            
            let encoded = try object.jsonElement()
            XCTAssertEqual(original, encoded)
            
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    func testUInt() {
        let original = JsonElement(UInt(3))
        XCTAssertEqual(JsonElement.integer(3), original)
    }
    
    func testIntFormatted() {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 0
        formatter.generatesDecimalNumbers = false
        
        guard let original = formatter.jsonElement(from: "3") else {
            XCTFail("Failed to convert '3' to a number")
            return
        }

        XCTAssertEqual(JsonElement.integer(3), original)
        
        guard let string = formatter.string(from: JsonElement.integer(3)) else {
            XCTFail("Failed to convert .integer(3) to a string")
            return
        }
        
        XCTAssertEqual("3", string)
    }
    
    func testDoubleFormatted() {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 2
        
        guard let original = formatter.jsonElement(from: "3.0") else {
            XCTFail("Failed to convert '3' to a number")
            return
        }

        XCTAssertEqual(JsonElement.number(3.0), original)
        
        guard let string = formatter.string(from: JsonElement.number(3.0)) else {
            XCTFail("Failed to convert .number(3.0) to a string")
            return
        }
        
        XCTAssertEqual("3", string)
    }
    
    func testDouble() {
        let original = JsonElement(3.2)
        XCTAssertEqual(JsonElement.number(3.2), original)
        XCTAssertNotEqual(JsonElement.number(3), original)
        XCTAssertTrue(3.2 == original)
        XCTAssertFalse(3 == original)
        
        let factory = SerializationFactory.defaultFactory
        let decoder = factory.createJSONDecoder()
        do {
            let object = try decoder.decode(SampleDouble.self, from: original)
            XCTAssertEqual(SampleDouble(rawValue: 3.2), object)
            
            let encoded = try object.jsonElement()
            XCTAssertEqual(original, encoded)
            
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    func testBoolean() {
        let original = JsonElement(true)
        XCTAssertEqual(JsonElement.boolean(true), original)
        XCTAssertNotEqual(JsonElement.boolean(false), original)
        
        let factory = SerializationFactory.defaultFactory
        let decoder = factory.createJSONDecoder()
        do {
            let object = try decoder.decode(SampleBoolean.self, from: original)
            XCTAssertEqual(SampleBoolean(rawValue: true), object)
            
            let encoded = try object.jsonElement()
            XCTAssertEqual(original, encoded)
            
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    func testNull() {
        let original = JsonElement(nil)
        XCTAssertEqual(JsonElement.null, original)
        XCTAssertNotEqual(JsonElement.string("null"), original)
    }
    
    func testArray() {
        let original = JsonElement(["foo","goo"])
        XCTAssertEqual(JsonElement.array(["foo","goo"]), original)
        XCTAssertNotEqual(JsonElement.array([]), original)
        
        let factory = SerializationFactory.defaultFactory
        let decoder = factory.createJSONDecoder()
        do {
            let object = try decoder.decode([String].self, from: original)
            XCTAssertEqual(["foo","goo"], object)
            
            let encoded = try object.jsonElement()
            XCTAssertEqual(original, encoded)
            
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    func testDictionary() {
        let original = JsonElement(["foo":1,"goo":"two"])
        XCTAssertEqual(JsonElement.object(["foo":1,"goo":"two"]), original)
        XCTAssertNotEqual(JsonElement.object([:]), original)
        
        let factory = SerializationFactory.defaultFactory
        let decoder = factory.createJSONDecoder()
        do {
            let object = try decoder.decode(SampleObject.self, from: original)
            let expected = SampleObject(foo: 1, goo: "two")
            XCTAssertEqual(expected, object)
            
            let encoded = try object.jsonElement()
            XCTAssertEqual(original, encoded)
            
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    func testNumberToInt_Equality() {
        let left = JsonElement.integer(3)
        let right = JsonElement.number(3)
        XCTAssertTrue(left == right)
        XCTAssertTrue(right == left)
    }
    
    func testComparable() {
        let values: [JsonElement] = [
            .number(3), .integer(4), .number(2.3)
        ]
        let expected: [JsonElement] = [
            .number(2.3), .number(3), .integer(4)
        ]
        XCTAssertNotEqual(expected, values)
        XCTAssertEqual(expected, values.sorted())
    }
}

enum SampleIntEnum : Int, Codable {
    case one = 1, two, three, four, five
}

struct SampleDouble : RawRepresentable, Codable, Hashable {
    let rawValue: Double
    init(rawValue: Double) {
        self.rawValue = rawValue
    }
}

struct SampleBoolean : RawRepresentable, Codable, Hashable {
    let rawValue: Bool
    init(rawValue: Bool) {
        self.rawValue = rawValue
    }
}

struct SampleObject : Codable, Hashable {
    let foo: Int
    let goo: String
}
