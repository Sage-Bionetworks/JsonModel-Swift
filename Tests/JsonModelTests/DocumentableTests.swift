//
//  DocumentableTests.swift
//
//

import XCTest
@testable import JsonModel

final class DocumentableTests: XCTestCase {
    
    func testFactoryDocumentBuilder() {
        
        let factory = TestFactory.defaultFactory
        
        let doc = JsonDocumentBuilder(factory: factory)
        
        XCTAssertEqual(doc.interfaces.count, 1, "\(doc.interfaces.map { $0.className })")
        XCTAssertEqual(doc.objects.count, 7, "\(doc.objects.map { $0.className })")
        
        let sampleType = doc.objects.first(where: { $0.className == "SampleType" })
        XCTAssertNotNil(sampleType)
        
        do {
            let schemas = try doc.buildSchemas()
            XCTAssertEqual(schemas.count, 1)
            guard let jsonSchema = schemas.first else {
                XCTFail("Failed to return a jsonSchema")
                return
            }
            checkSampleSchema(jsonSchema, false)
        }
        catch let err {
            XCTFail("Failed to build the JsonSchema: \(err)")
        }
    }
    
    func testFactoryDocumentBuilder_Recursive() {
        
        let factory = AnotherTestFactory.defaultFactory
        
        let doc = JsonDocumentBuilder(factory: factory)
        
        XCTAssertEqual(doc.interfaces.count, 2, "\(doc.interfaces.map { $0.className })")
        XCTAssertEqual(doc.objects.count, 11, "\(doc.objects.map { $0.className })")
        
        do {
            let schemas = try doc.buildSchemas()
            
            XCTAssertEqual(schemas.count, 2)
            
            if let sampleSchema = schemas.first(where: { $0.id.className == "Sample"}) {
                checkSampleSchema(sampleSchema, false)
            }
            else {
                XCTFail("Did not create schema for `Sample`")
            }
            
            if let _ = schemas.first(where: { $0.id.className == "Another"}) {
            }
            else {
                XCTFail("Did not create schema for `Sample`")
            }
        }
        catch let err {
            XCTFail("Failed to build the JsonSchema: \(err)")
        }
    }
    
    func checkSampleSchema(_ jsonSchema: JsonSchema, _ externalSampleItem: Bool) {
        
        XCTAssertEqual("\(kBDHJsonSchemaBaseURL)Sample.json", jsonSchema.id.classPath)
        XCTAssertEqual("Sample", jsonSchema.root.title)
        XCTAssertEqual("Sample is an example interface used for unit testing.", jsonSchema.root.description)
        
        XCTAssertNil(jsonSchema.root.additionalProperties)
        XCTAssertNil(jsonSchema.root.allOf)
        XCTAssertNil(jsonSchema.root.examples)
        XCTAssertNotNil(jsonSchema.definitions)
        
        let expectedProperties: [String : JsonSchemaProperty] = [
            "type" : .reference(JsonSchemaObjectRef(ref: JsonSchemaReferenceId("SampleType")))
        ]
        XCTAssertEqual(expectedProperties, jsonSchema.root.properties)
        XCTAssertEqual(["type"], jsonSchema.root.required)
        
        guard let definitions = jsonSchema.definitions else {
            XCTFail("Failed to build the jsonSchema definitions")
            return
        }

        let expectedCount = externalSampleItem ? 5 : 6
        XCTAssertEqual(expectedCount, definitions.count)
        
        var key: String = "SampleColor"
        if let def = definitions[key], case .stringEnum(let obj) = def {
            XCTAssertEqual(key, obj.id.className)
            XCTAssertEqual(key, obj.title)
            XCTAssertEqual(["red", "yellow", "blue"], obj.values)
        }
        else {
            XCTFail("Missing definition mapping for \(key)")
        }
        
        key = "SampleType"
        if let def = definitions[key], case .stringLiteral(let obj) = def {
            XCTAssertEqual(key, obj.id.className)
            XCTAssertEqual(key, obj.title)
            XCTAssertEqual(["a","b"], obj.examples)
        }
        else {
            XCTFail("Missing definition mapping for \(key)")
        }
        
        key = "SampleAnimals"
        if let def = definitions[key], case .stringOptionSet(let obj) = def {
            XCTAssertEqual(key, obj.id.className)
            XCTAssertEqual(key, obj.title)
            XCTAssertEqual(["bear", "cow", "fox"], Set(obj.examples ?? []))
        }
        else {
            XCTFail("Missing definition mapping for \(key)")
        }
        
        key = "SampleA"
        if let def = definitions[key], case .object(let obj) = def {
            XCTAssertEqual(key, obj.className)
            XCTAssertEqual(key, obj.title)
            XCTAssertEqual(obj.allOf?.map { $0.ref }, ["#"])
            XCTAssertEqual(Set(obj.required ?? []), ["type","value"])
            XCTAssertNil(obj.additionalProperties)
            let expectedExamples = [
                AnyCodableDictionary(["type":"a","value":3]),
                AnyCodableDictionary(["type":"a","value":2,"color":"yellow","animalMap": ["blue":["robin","sparrow"]]])
            ]
            XCTAssertEqual(expectedExamples, obj.examples)
            let expectedProperties: [String : JsonSchemaProperty] = [
                "type" : .const(JsonSchemaConst(const: "a", ref: JsonSchemaReferenceId("SampleType"))),
                "value" : .primitive(.integer),
                "color" : .reference(JsonSchemaObjectRef(ref: JsonSchemaReferenceId("SampleColor"))),
                "animalMap" : .dictionary(JsonSchemaTypedDictionary(items: .reference(JsonSchemaObjectRef(ref: JsonSchemaReferenceId("SampleAnimals")))))
            ]
            XCTAssertEqual(expectedProperties, obj.properties)
        }
        else {
            XCTFail("Missing definition mapping for \(key)")
        }
        
        key = "SampleB"
        if let def = definitions[key], case .object(let obj) = def {
            XCTAssertEqual(key, obj.className)
            XCTAssertEqual(key, obj.title)
            XCTAssertEqual(obj.allOf?.map { $0.ref }, ["#"])
            XCTAssertEqual(Set(obj.required ?? []), ["type","value"])
            XCTAssertNil(obj.additionalProperties)
            
            let sampleItemRef = JsonSchemaReferenceId("SampleItem", isExternal: externalSampleItem)
            
            let expectedProperties: [String : JsonSchemaProperty] = [
                "type" : .const(JsonSchemaConst(const: "b", ref: JsonSchemaReferenceId("SampleType"))),
                "value" : .primitive(.string),
                "animals" : .reference(JsonSchemaObjectRef(ref: JsonSchemaReferenceId("SampleAnimals"))),
                "jsonBlob" : .primitive(.any),
                "timestamp" : .primitive(JsonSchemaPrimitive(format: .dateTime)),
                "numberMap" : .dictionary(JsonSchemaTypedDictionary(items: .primitive(.integer))),
                "sampleItem" : .reference(JsonSchemaObjectRef(ref: sampleItemRef))
            ]
            
            XCTAssertEqual(expectedProperties.count, obj.properties?.count)
            XCTAssertEqual(expectedProperties, obj.properties)
            XCTAssertEqual(expectedProperties["type"], obj.properties?["type"])
            XCTAssertEqual(expectedProperties["value"], obj.properties?["value"])
            XCTAssertEqual(expectedProperties["animals"], obj.properties?["animals"])
            XCTAssertEqual(expectedProperties["jsonBlob"], obj.properties?["jsonBlob"])
            XCTAssertEqual(expectedProperties["timestamp"], obj.properties?["timestamp"])
            XCTAssertEqual(expectedProperties["numberMap"], obj.properties?["numberMap"])
        }
        else {
            XCTFail("Missing definition mapping for \(key)")
        }
    }
    
    func testAutoGeneratedDocs() throws {
        let jsonDocBuilder = JsonDocumentBuilder(baseUrl: testBURL, rootDocument: AutoGeneratedObject())
        let docs = try jsonDocBuilder.buildSchemas()
        
        XCTAssertEqual(docs.count, 1)
        guard let doc = docs.first else { return }
        
        if let def = doc.definitions?["Child"], case .object(let child) = def {
            
            XCTAssertEqual(doc.root.properties?["children"], .array(.init(items: .reference(.init(ref: child.id)))))
            XCTAssertEqual(doc.root.properties?["favorite"], .reference(.init(ref: child.id)))
            
            XCTAssertEqual(child.properties?["name"], .primitive(.string))
            XCTAssertEqual(child.properties?["age"], .primitive(.integer))
            XCTAssertEqual(child.properties?["hasPet"], .primitive(.boolean))
            XCTAssertEqual(child.properties?["rating"], .primitive(.number))
            
            if let ageRangeDef = doc.definitions?["AgeRange"], case .stringEnum(let jsonSchemaStringEnum) = ageRangeDef {
                XCTAssertEqual(child.properties?["ageRange"], .reference(.init(ref: jsonSchemaStringEnum.id)))
            }
            else {
                XCTFail("Failed to create definition for AgeRange")
            }
        }
        else {
            XCTFail("expecting a definition for child")
        }
        
        XCTAssertEqual(doc.root.properties?["jsonSchema"], .primitive(.init(format: .uri)))
        XCTAssertEqual(doc.root.properties?["uuid"], .primitive(.init(format: .uuid)))
        XCTAssertEqual(doc.root.properties?["createdOn"], .primitive(.init(format: .dateTime)))
        XCTAssertEqual(doc.root.properties?["ages"], .array(.init(items: .primitive(.integer))))
        XCTAssertEqual(doc.root.properties?["ratings"], .array(.init(items: .primitive(.number))))
        XCTAssertEqual(doc.root.properties?["names"], .array(.init(items: .primitive(.string))))
    }
}

// MARK: Test objects

class AnotherTestFactory : SerializationFactory {
    let sampleSerializer = SampleSerializer()
    let anotherSerializer = AnotherSerializer()
    required init() {
        super.init()
        self.registerSerializer(sampleSerializer)
        self.registerSerializer(anotherSerializer)
    }
    
    override func documentableInterfaces() -> [DocumentableInterface] {
        [sampleSerializer, anotherSerializer]
    }
}

class AnotherSerializer : GenericPolymorphicSerializer<Another>, DocumentableInterface {
    var jsonSchema: URL {
        URL(string: "Another.json", relativeTo: kBDHJsonSchemaBaseURL)!
    }

    var documentDescription: String? {
        "Another example interface used for unit testing."
    }
    
    override init() {
        super.init([
            AnotherA(),
            AnotherB(),
        ])
    }
    
    override class func typeDocumentProperty() -> DocumentProperty {
        DocumentProperty(propertyType: .reference(AnotherType.self))
    }
    
    override func isSealed() -> Bool {
        true
    }
}

protocol Another : PolymorphicTyped, Codable {
    var exampleType: AnotherType { get }
}

extension Another {
    var typeName: String { return exampleType.rawValue }
}

enum AnotherType : String, Codable, CaseIterable, StringEnumSet, DocumentableStringEnum {
    case a, b
}

struct AnotherA : Another, Codable {
    static let defaultType: AnotherType = .a
    private enum CodingKeys : String, CodingKey, CaseIterable {
        case exampleType = "type", animals, samples, sampleItem
    }
    
    private (set) var exampleType: AnotherType = Self.defaultType
    
    let animals: [SampleAnimals]?
    let samples: [Sample]?
    let sampleItem: SampleItem?
    
    init(animals: [SampleAnimals]? = nil, samples: [Sample]? = nil, sampleItem: SampleItem? = nil) {
        self.animals = animals
        self.samples = samples
        self.sampleItem = sampleItem
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.animals = try container.decodeIfPresent([SampleAnimals].self, forKey: .animals)
        self.sampleItem = try container.decodeIfPresent(SampleItem.self, forKey: .sampleItem)
        if container.contains(.samples) {
            let nestedContainer = try container.nestedUnkeyedContainer(forKey: .samples)
            self.samples = try decoder.serializationFactory.decodePolymorphicArray(Sample.self, from: nestedContainer)
        } else {
            self.samples = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(self.animals, forKey: .animals)
        try container.encodeIfPresent(self.sampleItem, forKey: .sampleItem)
        if let samples = self.samples {
            var nestedContainer = container.nestedUnkeyedContainer(forKey: .samples)
            try nestedContainer.encodePolymorphic(samples)
        }
    }
}

extension AnotherA : DocumentableStruct {
    static func codingKeys() -> [CodingKey] {
        return self.CodingKeys.allCases
    }

    static func isRequired(_ codingKey: CodingKey) -> Bool {
        guard let key = codingKey as? CodingKeys else { return false }
        return key == .exampleType
    }
    
    static func documentProperty(for codingKey: CodingKey) throws -> DocumentProperty {
        guard let key = codingKey as? CodingKeys else {
            throw DocumentableError.invalidCodingKey(codingKey, "Not a mappable coding key for \(self)")
        }
        switch key {
        case .exampleType:
            return DocumentProperty(constValue: defaultType)
        case .animals:
            return DocumentProperty(propertyType: .referenceArray(SampleAnimals.documentableType()))
        case .samples:
            return DocumentProperty(propertyType: .interfaceArray("\(Sample.self)"))
        case .sampleItem:
            return DocumentProperty(propertyType: .reference(SampleItem.documentableType()))
        }
    }
    
    static func examples() -> [AnotherA] {
        return [AnotherA(),
                AnotherA(animals: [.birds], samples: [SampleA(value: 4)], sampleItem: SampleItem(name: "foo", color: .red))]
    }
}

struct AnotherB : Another, Codable, Equatable {
    static let defaultType: AnotherType = .b
    private enum CodingKeys : String, CodingKey, CaseIterable {
        case exampleType = "type"
    }
    
    private (set) var exampleType: AnotherType = Self.defaultType
}

extension AnotherB : DocumentableStruct {
    static func codingKeys() -> [CodingKey] {
        return self.CodingKeys.allCases
    }

    static func isRequired(_ codingKey: CodingKey) -> Bool {
        true
    }
    
    static func documentProperty(for codingKey: CodingKey) throws -> DocumentProperty {
        return DocumentProperty(constValue: defaultType)
    }
    
    static func examples() -> [AnotherB] {
        return [AnotherB()]
    }
}

let testBURL = URL(string: "https://foo.org/schemas/")!

struct AutoGeneratedObject : Codable, Hashable {
    enum CodingKeys : String, DocumentableCodingKey {
        case jsonSchema, uuid, createdOn, favorite, ages, ratings, names, children
        static var requiredKeys: [CodingKeys] { [.jsonSchema, .uuid, .createdOn, .children] }
    }
    
    let jsonSchema: URL
    let uuid: UUID
    let createdOn: Date
    
    let favorite: Child?
    let ages: Set<Int>?
    let ratings: Set<Double>?
    let names: [String]?
    
    let children: Set<Child>
    
    init(children: [Child], createdOn: Date = Date()) {
        self.favorite = children.sorted(by: { $0.rating > $1.rating }).first
        self.children = Set(children)
        self.jsonSchema = URL(string: "AutoGeneratedObject.json", relativeTo: testBURL)!
        self.uuid = UUID()
        self.createdOn = createdOn
        self.ages = Set(children.map { Int($0.age) })
        self.ratings = Set(children.map { Double($0.rating) })
        self.names = children.map { $0.name }
    }

    struct Child : Codable, Hashable {
        enum CodingKeys : String, DocumentableCodingKey {
            case name, age, rating, hasPet, ageRange
            static var requiredKeys: [CodingKeys] { allCases }
        }
        let name: String
        let age : UInt16
        let rating : Float
        let hasPet : Bool
        let ageRange : AgeRange
    }
    
    enum AgeRange : String, DocumentableStringEnum, StringEnumSet {
        case infant, toddler, child, tweenager, teenager, adult
    }
}

extension AutoGeneratedObject : DocumentableRootObject {
    init() {
        self.init(children: AutoGeneratedObject.Child.examples())
    }
    
    var documentDescription: String? {
        "This is an example of a JSON schema that is auto generated."
    }
}

extension AutoGeneratedObject : GenericDocumentableStruct {
    static func examples() -> [AutoGeneratedObject] {
        [.init()]
    }
    
    static func documentProperty(for codingKey: CodingKey) throws -> JsonModel.DocumentProperty {
        try mirroredPropertyType(for: codingKey)
    }
}

extension AutoGeneratedObject.Child : GenericDocumentableStruct {
    static func examples() -> [AutoGeneratedObject.Child] {
        [
            .init(name: "Sue", age: 2, rating: 5.2, hasPet: false, ageRange: .toddler),
            .init(name: "Bob", age: 5, rating: 8.7, hasPet: true, ageRange: .child),
        ]
    }
    
    static func documentProperty(for codingKey: CodingKey) throws -> JsonModel.DocumentProperty {
        try mirroredPropertyType(for: codingKey)
    }
}

