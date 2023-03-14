// Created 3/13/23
// swift-tools-version:5.0

import XCTest
@testable import JsonModel

final class PolymorphicWrapperTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testPolymorphicPropertyWrappers() throws {
        let json = """
        {
            "single" : { "type" : "a", "value" : 1 },
            "array" : [
                { "type" : "a", "value" : 10 },
                { "type" : "a", "value" : 11 },
                { "type" : "b", "value" : "foo" }
            ]
        }
        """.data(using: .utf8)!
        
        let factory = TestFactory.defaultFactory
        let decoder = factory.createJSONDecoder()
        let encoder = factory.createJSONEncoder()
        
        let decodedObject = try decoder.decode(SampleTest.self, from: json)
        
        XCTAssertEqual(SampleA(value: 1), decodedObject.single as? SampleA)
        XCTAssertEqual(3, decodedObject.array.count)
        XCTAssertEqual(SampleA(value: 10), decodedObject.array.first as? SampleA)
        XCTAssertEqual(SampleB(value: "foo"), decodedObject.array.last as? SampleB)
        XCTAssertNil(decodedObject.nullable)
        
        let encodedData = try encoder.encode(decodedObject)
        let encodedJson = try JSONDecoder().decode(JsonElement.self, from: encodedData)
        let expectedJson = try JSONDecoder().decode(JsonElement.self, from: json)
        
        XCTAssertEqual(expectedJson, encodedJson)
    }
}

fileprivate struct SampleTest : Codable {
    private enum CodingKeys : String, CodingKey {
        case single, array, _nullable = "nullable"
    }
    
    @PolymorphicValue private(set) var single: Sample
    @PolymorphicArray var array: [Sample]
    
    public var nullable: Sample? {
        _nullable?.wrappedValue
    }
    private let _nullable: PolymorphicValue<Sample>?
    
    init(single: Sample, array: [Sample], nullable: Sample? = nil) {
        self.single = single
        self.array = array
        self._nullable = nullable.map { PolymorphicValue(wrappedValue: $0) }
    }
}
