//
//  DocumentableTests.swift
//
//
//  Copyright © 2020-2022 Sage Bionetworks. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
// 1.  Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
//
// 2.  Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation and/or
// other materials provided with the distribution.
//
// 3.  Neither the name of the copyright holder(s) nor the names of any contributors
// may be used to endorse or promote products derived from this software without
// specific prior written permission. No license is granted to the trademarks of
// the copyright holders even if such marks are included in this software.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
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
        
        XCTAssertEqual("\(kSageJsonSchemaBaseURL)Sample.json", jsonSchema.id.classPath)
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

class AnotherSerializer : AbstractPolymorphicSerializer, PolymorphicSerializer {
    var jsonSchema: URL {
        URL(string: "Another.json", relativeTo: kSageJsonSchemaBaseURL)!
    }

    var documentDescription: String? {
        "Another example interface used for unit testing."
    }
    
    let examples: [Another] = [
        AnotherA(),
        AnotherB(),
    ]
    
    override class func typeDocumentProperty() -> DocumentProperty {
        DocumentProperty(propertyType: .reference(AnotherType.self))
    }
    
    override func isSealed() -> Bool {
        true
    }
}

protocol Another : PolymorphicRepresentable, Encodable {
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
            try samples.forEach {
                let encodable = $0 as! Encodable
                let nestedEncoder = nestedContainer.superEncoder()
                try encodable.encode(to: nestedEncoder)
            }
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

