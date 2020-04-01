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
        
        let factory = SerializationFactory.shared
        factory.registerSerializer(serializer)
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
}

struct SampleWrapper : Codable {
    let value: Sample
    init(from decoder: Decoder) throws {
        self.value = try decoder.factory.decodeObject(Sample.self, from: decoder)
    }
    func encode(to encoder: Encoder) throws {
        try self.value.encode(to: encoder)
    }
}

class SampleSerializer : AbstractPolymorphicSerializer, PolymorphicSerializer {
    let examples: [Sample] = [
        SampleA(value: 3),
        SampleB(value: "foo"),
    ]
}

protocol Sample : PolymorphicRepresentable, Encodable {
    var exampleType: SampleType { get }
    static var defaultType: SampleType { get }
}

extension Sample {
    var typeName: String { return exampleType.rawValue }
}

struct SampleType : TypeRepresentable, Codable {
    
    let rawValue: String
    
    init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    static let a: SampleType = "a"
    static let b: SampleType = "b"
    
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

enum SampleColor : String, Codable, DocumentableStringEnum, StringEnumSet {
    case red, yellow, blue
}

struct SampleA : Sample, Codable, Equatable {
    static let defaultType: SampleType = .a
    private enum CodingKeys : String, CodingKey, CaseIterable {
        case exampleType = "type", value, color
    }
    
    private (set) var exampleType: SampleType = Self.defaultType
    
    let value: Int
    let color: SampleColor?
    
    init(value: Int, color: SampleColor? = nil) {
        self.value = value
        self.color = color
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
            return DocumentProperty(propertyType: .reference(type(of: SampleColor.red)))
        }
    }
    
    static func examples() -> [SampleA] {
        return [SampleA(value: 3), SampleA(value: 2, color: .yellow)]
    }
}

struct SampleB : Sample, Codable, Equatable {
    static let defaultType: SampleType = .b
    private enum CodingKeys : String, CodingKey, CaseIterable {
        case value, exampleType = "type"
    }
    
    private (set) var exampleType: SampleType = Self.defaultType
    
    let value: String
    
    init(value: String) {
        self.value = value
    }
}

extension SampleB : DocumentableStruct {
    static func codingKeys() -> [CodingKey] {
        return self.CodingKeys.allCases
    }

    static func isRequired(_ codingKey: CodingKey) -> Bool {
        return true
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
        }
    }
    
    static func examples() -> [SampleB] {
        return [SampleB(value: "foo")]
    }
}
