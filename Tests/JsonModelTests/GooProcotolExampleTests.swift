// Created 3/15/23
// swift-tools-version:5.0

import XCTest
@testable import JsonModel

final class GooProcotolExampleTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExampleMoo() throws {
        let factory = GooFactory()
        let decoder = factory.createJSONDecoder()
        let encoder = factory.createJSONEncoder()
        
        let json = """
        {
            "type" : "moo",
            "goos" : [
                { "type" : "foo", "value" : 2 },
                { "type" : "moo", "goos" : [{ "type" : "foo", "value" : 5 }] }
            ]
        }
        """.data(using: .utf8)!
        
        let decodedObject = try decoder.decode(MooObject.self, from: json)
        let encodedData = try encoder.encode(decodedObject)
        
        let expectedDictionary = try JSONSerialization.jsonObject(with: json) as! NSDictionary
        let actualDictionary = try JSONSerialization.jsonObject(with: encodedData) as! NSDictionary
        XCTAssertEqual(expectedDictionary, actualDictionary)
    }
    
    func testExampleRagu() throws {
        let factory = GooFactory()
        let decoder = factory.createJSONDecoder()
        let encoder = factory.createJSONEncoder()
        
        let json = """
        {
            "type" : "ragu",
            "value" : 7,
            "goo" : { "type" : "foo", "value" : 2 }
        }
        """.data(using: .utf8)!
        
        let decodedObject = try decoder.decode(PolymorphicValue<GooProtocol>.self, from: json)
        let encodedData = try encoder.encode(decodedObject)
        
        let expectedDictionary = try JSONSerialization.jsonObject(with: json) as! NSDictionary
        let actualDictionary = try JSONSerialization.jsonObject(with: encodedData) as! NSDictionary
        XCTAssertEqual(expectedDictionary, actualDictionary)
    }
}

public protocol GooProtocol {
    var value: Int { get }
}

public struct FooObject : Codable, PolymorphicStaticTyped, GooProtocol {
    public static let typeName: String = "foo"

    public let value: Int

    public init(value: Int = 0) {
        self.value = value
    }
}

/// This object can be serialized directly.
public struct MooObject : Codable, PolymorphicTyped, GooProtocol {
    private enum CodingKeys : String, CodingKey {
        case typeName = "type", goos
    }
    public private(set) var typeName: String = "moo"
    
    public var value: Int {
        goos.count
    }

    @PolymorphicArray public var goos: [GooProtocol]

    public init(goos: [GooProtocol] = []) {
        self.goos = goos
    }
}

/// This object must be wrapped to allow serialization at the root.
///
/// - Example:
/// ```
///     let factory = GooFactory()
///     let decoder = factory.createJSONDecoder()
///     let encoder = factory.createJSONEncoder()
///
///     let json = """
///     {
///         "type" : "ragu",
///         "value" : 7,
///         "goo" : { "type" : "foo", "value" : 2 }
///     }
///     """.data(using: .utf8)!
///
///     let decodedObject = try decoder.decode(PolymorphicValue<GooProtocol>.self, from: json)
///     let encodedData = try encoder.encode(decodedObject)
/// ```
public struct RaguObject : Codable, PolymorphicStaticTyped, GooProtocol {
    public static let typeName: String = "ragu"

    public let value: Int
    @PolymorphicValue public private(set) var goo: GooProtocol

    public init(value: Int, goo: GooProtocol) {
        self.value = value
        self.goo = goo
    }
}

open class GooFactory : SerializationFactory {
    
    public let gooSerializer = GenericPolymorphicSerializer<GooProtocol>([
        MooObject(),
        FooObject(),
    ])
    
    public required init() {
        super.init()
        
        self.registerSerializer(gooSerializer)
        gooSerializer.add(typeOf: RaguObject.self)
    }
}

