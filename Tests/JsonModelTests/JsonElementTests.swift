//
//  JsonElementTests.swift
//  
//
//  Created by Shannon Young on 3/26/20.
//

import XCTest
@testable import JsonModel

final class JsonElementTests: XCTestCase {

    func testString() {
        let original = JsonElement("foo")
        XCTAssertEqual(JsonElement.string("foo"), original)
        XCTAssertNotEqual(JsonElement.string("boo"), original)
    }
    
    func testInt() {
        let original = JsonElement(3)
        XCTAssertEqual(JsonElement.integer(3), original)
        XCTAssertNotEqual(JsonElement.number(3.2), original)
    }
    
    func testDouble() {
        let original = JsonElement(3.2)
        XCTAssertEqual(JsonElement.number(3.2), original)
        XCTAssertNotEqual(JsonElement.number(3), original)
    }
    
    func testBoolean() {
        let original = JsonElement(true)
        XCTAssertEqual(JsonElement.boolean(true), original)
        XCTAssertNotEqual(JsonElement.boolean(false), original)
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
    }
    
    func testDictionary() {
        let original = JsonElement(["foo":1,"goo":"two"])
        XCTAssertEqual(JsonElement.object(["foo":1,"goo":"two"]), original)
        XCTAssertNotEqual(JsonElement.object([:]), original)
    }

    static var allTests = [
        ("testString", testString),
        ("testInt", testInt),
        ("testDouble", testDouble),
        ("testBoolean", testBoolean),
        ("testNull", testNull),
        ("testArray", testArray),
        ("testDictionary", testDictionary),
    ]
}
