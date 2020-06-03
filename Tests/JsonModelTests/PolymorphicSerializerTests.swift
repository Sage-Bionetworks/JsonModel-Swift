//
//  PolymorphicSerializerTests.swift
//
//  Copyright © 2020 Sage Bionetworks. All rights reserved.
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

final class PolymorphicSerializerTests: XCTestCase {
    
    func testSampleSerializer() {
        let serializer = SampleSerializer()
        
        XCTAssertEqual("Sample", serializer.interfaceName)
        
        let json = """
        {
            "value": 5,
            "type": "a"
        }
        """.data(using: .utf8)! // our data in native (JSON) format
        
        let factory = TestFactory.defaultFactory
        let decoder = factory.createJSONDecoder()
        let encoder = factory.createJSONEncoder()
        
        do {
            let sampleWrapper = try decoder.decode(SampleWrapper.self, from: json)
            
            guard let sample = sampleWrapper.value as? SampleA else {
                XCTFail("\(sampleWrapper.value) not of expected type.")
                return
            }
            
            XCTAssertEqual(5, sample.value)
            
            let encoding = try encoder.encode(sampleWrapper)
            let encodedJson = try JSONSerialization.jsonObject(with: encoding, options: [])
            guard let dictionary = encodedJson as? [String : Any] else {
                XCTFail("\(encodedJson) not a dictionary.")
                return
            }
            
            if let value = dictionary["value"] as? Int {
                XCTAssertEqual(5, value)
            }
            else {
                XCTFail("Encoding does not include 'value' keyword. \(dictionary)")
            }
            
            if let typeName = dictionary["type"] as? String {
                XCTAssertEqual("a", typeName)
            }
            else {
                XCTFail("Encoding does not include 'valtypeue' keyword. \(dictionary)")
            }

        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
        }
    }
    
    func testSampleSerializer_NotRegistered() {
        let json = """
        {
            "name": "moo",
            "type": "notRegistered"
        }
        """.data(using: .utf8)! // our data in native (JSON) format
        
        let factory = TestFactory.defaultFactory
        let decoder = factory.createJSONDecoder()
        
        do {
            let sampleWrapper = try decoder.decode(SampleWrapper.self, from: json)
            
            guard let sample = sampleWrapper.value as? SampleNotRegistered else {
                XCTFail("\(sampleWrapper.value) not of expected type.")
                return
            }
            
            XCTAssertEqual("moo", sample.name)
            
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
        }
    }
}

struct SampleWrapper : Codable {
    let value: Sample
    init(from decoder: Decoder) throws {
        self.value = try decoder.serializationFactory.decodePolymorphicObject(Sample.self, from: decoder)
    }
    func encode(to encoder: Encoder) throws {
        guard let encodable = self.value as? Encodable else {
            let context = EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "value does not convorm to encodable protocol.")
            throw EncodingError.invalidValue(self.value, context)
        }
        try encodable.encode(to: encoder)
    }
}

class SampleSerializer : AbstractPolymorphicSerializer, PolymorphicSerializer {

    var documentDescription: String? {
        "Sample is an example interface used for unit testing."
    }
    
    let examples: [Sample] = [
        SampleA(value: 3),
        SampleB(value: "foo"),
    ]
    
    override class func typeDocumentProperty() -> DocumentProperty {
        DocumentProperty(propertyType: .reference(SampleType.self))
    }
}

protocol Sample {
}

protocol SerializableSample : Sample, PolymorphicRepresentable, Encodable {
    var exampleType: SampleType { get }
    static var defaultType: SampleType { get }
}

extension SerializableSample {
    var typeName: String { return exampleType.rawValue }
}

struct SampleType : TypeRepresentable, Codable {
    
    let rawValue: String
    
    init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    static let a: SampleType = "a"
    static let b: SampleType = "b"
    static let notRegistered: SampleType = "notRegistered"
    
    static func allStandardValues() -> [SampleType] {
        return [.a, .b]
    }
}

extension SampleType : ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }
}

extension SampleType : DocumentableStringLiteral {
    static func examples() -> [String] {
        return allStandardValues().map { $0.rawValue }
    }
}

struct SampleItem : Codable, Hashable {
    private enum CodingKeys : String, CodingKey, CaseIterable {
        case name, color
    }
    let name: String
    let color: SampleColor
}

extension SampleItem : DocumentableStruct {
    
    static func examples() -> [SampleItem] {
        [SampleItem(name: "foo", color: .blue)]
    }
    
    static func codingKeys() -> [CodingKey] {
        CodingKeys.allCases
    }
    
    static func isRequired(_ codingKey: CodingKey) -> Bool {
        true
    }
    
    static func documentProperty(for codingKey: CodingKey) throws -> DocumentProperty {
        guard let key = codingKey as? CodingKeys else {
            throw DocumentableError.invalidCodingKey(codingKey, "Not a mappable coding key for \(self)")
        }
        switch key {
        case .name:
            return .init(propertyType: .primitive(.string))
        case .color:
            return .init(propertyType: .reference(SampleColor.documentableType()))
        }
    }
}

struct SampleAnimals : Codable, Hashable {
    let options: Set<String>
    
    init(_ options: Set<String>) {
        self.options = options
    }
    
    static let birds = SampleAnimals(["robin", "sparrow"])
    static let mammals = SampleAnimals(["bear", "cow", "fox"])
    
    init(from decoder: Decoder) throws {
        self.options = try Set<String>(from: decoder)
    }
    
    func encode(to encoder: Encoder) throws {
        try self.options.sorted().encode(to: encoder)
    }
}

extension SampleAnimals : DocumentableStringOptionSet {
    static func examples() -> [String] {
        return Array(SampleAnimals.mammals.options)
    }
}

enum SampleColor : String, Codable, DocumentableStringEnum, StringEnumSet {
    case red, yellow, blue
}

struct SampleA : SerializableSample, Codable, Equatable {
    static let defaultType: SampleType = .a
    private enum CodingKeys : String, CodingKey, CaseIterable {
        case exampleType = "type", value, color, animalMap
    }
    
    private (set) var exampleType: SampleType = Self.defaultType
    
    let value: Int
    let color: SampleColor?
    let animalMap: [String : SampleAnimals]?
    
    init(value: Int, color: SampleColor? = nil, animalMap: [String : SampleAnimals]? = nil) {
        self.value = value
        self.color = color
        self.animalMap = animalMap
    }
}

extension SampleA : DocumentableStruct {
    static func codingKeys() -> [CodingKey] {
        return self.CodingKeys.allCases
    }

    static func isRequired(_ codingKey: CodingKey) -> Bool {
        guard let key = codingKey as? CodingKeys else { return false }
        return key == .exampleType || key == .value
    }
    
    static func documentProperty(for codingKey: CodingKey) throws -> DocumentProperty {
        guard let key = codingKey as? CodingKeys else {
            throw DocumentableError.invalidCodingKey(codingKey, "Not a mappable coding key for \(self)")
        }
        switch key {
        case .exampleType:
            return DocumentProperty(constValue: defaultType)
        case .value:
            return DocumentProperty(propertyType: .primitive(.integer))
        case .color:
            return DocumentProperty(propertyType: .reference(SampleColor.documentableType()))
        case .animalMap:
            return DocumentProperty(propertyType: .referenceDictionary(SampleAnimals.documentableType()))
        }
    }
    
    static func examples() -> [SampleA] {
        return [SampleA(value: 3), SampleA(value: 2, color: .yellow, animalMap: ["blue":.birds])]
    }
}

struct SampleB : SerializableSample, Codable, Equatable {
    static let defaultType: SampleType = .b
    private enum CodingKeys : String, CodingKey, CaseIterable {
        case value, exampleType = "type", animals, jsonBlob, timestamp, numberMap, sampleItem
    }
    
    private (set) var exampleType: SampleType = Self.defaultType
    
    let value: String
    let animals: SampleAnimals?
    let jsonBlob: JsonElement?
    let timestamp: Date?
    let numberMap: [String : Int]?
    let sampleItem: SampleItem?
    
    init(value: String,
         animals: SampleAnimals? = nil,
         jsonBlob: JsonElement? = nil,
         timestamp: Date? = nil,
         numberMap: [String : Int]? = nil,
         sampleItem: SampleItem? = nil) {
        self.value = value
        self.animals = animals
        self.jsonBlob = jsonBlob
        self.timestamp = timestamp
        self.numberMap = numberMap
        self.sampleItem = sampleItem
    }
}

extension SampleB : DocumentableStruct {
    static func codingKeys() -> [CodingKey] {
        return self.CodingKeys.allCases
    }

    static func isRequired(_ codingKey: CodingKey) -> Bool {
        guard let key = codingKey as? CodingKeys else { return false }
        return key == .exampleType || key == .value
    }
    
    static func documentProperty(for codingKey: CodingKey) throws -> DocumentProperty {
        guard let key = codingKey as? CodingKeys else {
            throw DocumentableError.invalidCodingKey(codingKey, "Not a mappable coding key for \(self)")
        }
        switch key {
        case .exampleType:
            return DocumentProperty(constValue: defaultType)
        case .value:
            return DocumentProperty(propertyType: .primitive(.string))
        case .animals:
            return DocumentProperty(propertyType: .reference(SampleAnimals.documentableType()))
        case .jsonBlob:
            return DocumentProperty(propertyType: .any)
        case .timestamp:
            return DocumentProperty(propertyType: .format(.dateTime))
        case .numberMap:
            return DocumentProperty(propertyType: .primitiveDictionary(.integer))
        case .sampleItem:
            return DocumentProperty(propertyType: .reference(SampleItem.documentableType()))
        }
    }
    
    static func examples() -> [SampleB] {
        return [SampleB(value: "foo"),
                SampleB(value: "foo", animals: SampleAnimals.birds, jsonBlob: .array([1,2]), timestamp: Date(), numberMap: ["one" : 1])]
    }
}

struct SampleNotRegistered : Sample, Codable {
    let name: String
}

class TestFactory : SerializationFactory {
    let sampleSerializer = SampleSerializer()
    required init() {
        super.init()
        self.registerSerializer(sampleSerializer)
    }
    
    override func decodeDefaultObject<T>(_ type: T.Type, from decoder: Decoder) throws -> T {
        guard type == Sample.self else {
            return try super.decodeDefaultObject(type, from: decoder)
        }
        return try SampleNotRegistered(from: decoder) as! T
    }
}
