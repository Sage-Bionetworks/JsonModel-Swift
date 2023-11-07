// Created 11/7/23
// swift-tools-version:5.0

import XCTest
import JsonModel

final class SerializableMacrosTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testSimpleStruct() throws {
        let test = SimpleStruct(foo: "two", baloo: 2)
        let encoding = try test.jsonEncodedDictionary()
        XCTAssertEqual("two", encoding["foo"] as? String)
        XCTAssertEqual(2, encoding["baloo"] as? Int)
        XCTAssertNil(encoding["goo"])
    }
    
    @Serializable
    public struct SimpleStruct {
        public let foo: String
        public let baloo: Int
        @Transient public var goo: Double = 0
    }

}
