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
    
    func testPolymorphicPropertyWrapper_DefaultTyped() throws {
        let sampleTest = SampleTest(single: SampleX(name: "foo", value: 5), array: [])
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(sampleTest)
        let dictionary = try JSONSerialization.jsonObject(with: jsonData) as! NSDictionary
        let expectedDictionary : NSDictionary = [
            "single" : [
                "type" : "SampleX",
                "name" : "foo",
                "value" : 5
            ] as [String : Any],
            "array" : [] as [Any]
        ]
        XCTAssertEqual(expectedDictionary, dictionary)
    }
    
    func testPolymorphicPropertyWrapper_NotDictionary() throws {
        let sampleTest = SampleTest(single: "foo", array: [])
        let encoder = JSONEncoder()
        do {
            let _ = try encoder.encode(sampleTest)
        }
        catch EncodingError.invalidValue(_, let context) {
            XCTAssertEqual("Cannot encode a polymorphic object to a single value container.", context.debugDescription)
            return
        }
        
        XCTFail("This test should throw an invalid value error and exit before here.")
    }
}

extension String : Sample {
}

fileprivate struct SampleX : Sample, Encodable {
    let name: String
    let value: UInt
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
