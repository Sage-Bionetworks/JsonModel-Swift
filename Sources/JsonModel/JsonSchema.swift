//
//  JsonSchema.swift
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

import Foundation

public protocol PolymorphicSchemaElement {
    var id: JsonSchemaReferenceId { get }
    var description: String? { get }
    var properties: [String : JsonSchemaProperty]? { get }
    var required: [String]? { get }
    var allOf: [JsonSchemaObjectRef]? { get }
    var isOpen: Bool { get }
    var examples: [AnyCodableDictionary]? { get }
}

/// `JsonSchema` includes a subset of the json schema defined by
/// http://json-schema.org/draft-07/schema# with some additional rules to simplify creating
/// serializable definitions in Swift and Kotlin.
///
/// - note: The composable elements in this code file are defined as public to allow for extending
/// the documentation, but should only be used at your own risk.
public struct JsonSchema : PolymorphicSchemaElement, Codable, Equatable, Hashable {
    private enum CodingKeys : String, CodingKey {
        case schema = "$schema",
        id = "$id",
        jsonType = "type",
        title,
        description,
        definitions,
        properties,
        required,
        allOf,
        examples,
        additionalProperties
    }

    public private(set) var schema: String = "http://json-schema.org/draft-07/schema#"
    public let id: JsonSchemaReferenceId
    public private(set) var jsonType: JsonType = .object
    public let title: String?
    public let description: String?
    public let definitions: [String : JsonSchemaDefinition]?
    public let allOf: [JsonSchemaObjectRef]?
    public let properties: [String : JsonSchemaProperty]?
    public let required: [String]?
    public let examples: [AnyCodableDictionary]?
    private let additionalProperties: JsonElement?
    
    public var isOpen: Bool {
        return additionalProperties == nil
    }
    
    public init(id: URL,
                description: String = "",
                isOpen: Bool = true,
                interfaces: [JsonSchemaReferenceId]? = nil,
                definitions: [JsonSchemaDefinition] = [],
                properties: [String : JsonSchemaProperty]? = nil,
                required: [String]? = nil,
                examples: [[String : JsonSerializable]]? = nil) {
        let refId = JsonSchemaReferenceId(url: id)
        self.id = refId
        self.title = refId.className
        self.description = description
        self.additionalProperties = isOpen ? nil : .boolean(false)
        self.allOf = interfaces?.map { JsonSchemaObjectRef(ref: $0) }
        var allDefinitions: [JsonSchemaDefinition] = interfaces?.compactMap {
            $0.isExternal ? nil : .object(JsonSchemaObject(id: $0, isOpen: true))
        } ?? []
        allDefinitions.append(contentsOf: definitions)
        self.definitions = allDefinitions.reduce(into: [String : JsonSchemaDefinition]()) {
            guard let className = $1.className else { return }
            $0[className] = $1
        }
        self.properties = properties
        self.required = required
        self.examples = (examples == nil) ? nil : examples!.map { AnyCodableDictionary($0)}
    }
}

public enum JsonSchemaDefinition : Codable, Equatable, Hashable {
    case object(JsonSchemaObject)
    case stringLiteral(JsonSchemaStringLiteral)
    case stringEnum(JsonSchemaStringEnum)
    
    public var className: String? {
        switch self {
        case .object(let value):
            return value.id.className
        case .stringEnum(let value):
            return value.id.className
        case .stringLiteral(let value):
            return value.id.className
        }
    }
    
    public init(from decoder: Decoder) throws {
        if let obj = try? JsonSchemaStringEnum(from: decoder) {
            self = .stringEnum(obj)
        }
        else if let obj = try? JsonSchemaStringLiteral(from: decoder), obj.isValidDecoding {
            self = .stringLiteral(obj)
        }
        else if let obj = try? JsonSchemaObject(from: decoder), obj.isValidDecoding {
            self = .object(obj)
        }
        else {
            let context = DecodingError.Context(codingPath: decoder.codingPath,
                                                debugDescription: "Cannot find match for this decoding")
            throw DecodingError.typeMismatch(JsonSchemaDefinition.self, context)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        switch self {
        case .object(let value):
            try value.encode(to: encoder)
        case .stringEnum(let value):
            try value.encode(to: encoder)
        case .stringLiteral(let value):
            try value.encode(to: encoder)
        }
    }
    
    public static func == (lhs: JsonSchemaDefinition, rhs: JsonSchemaDefinition) -> Bool {
        switch lhs {
        case .object(let lv):
            if case .object(let rv) = rhs { return rv == lv } else { return false }
        case .stringEnum(let lv):
            if case .stringEnum(let rv) = rhs { return rv == lv } else { return false }
        case .stringLiteral(let lv):
            if case .stringLiteral(let rv) = rhs { return rv == lv } else { return false }
        }
    }
}

public enum JsonSchemaProperty : Codable, Equatable, Hashable {
    case array(JsonSchemaArray)
    case const(JsonSchemaConst)
    case primitive(JsonSchemaPrimitive)
    case reference(JsonSchemaObjectRef)
    
    public init(from decoder: Decoder) throws {
        if let obj = try? JsonSchemaConst(from: decoder) {
            self = .const(obj)
        }
        else if let obj = try? JsonSchemaObjectRef(from: decoder) {
            self = .reference(obj)
        }
        else if let obj = try? JsonSchemaArray(from: decoder) {
            self = .array(obj)
        }
        else if let obj = try? JsonSchemaPrimitive(from: decoder), obj.isValidDecoding {
            self = .primitive(obj)
        }
        else {
            let context = DecodingError.Context(codingPath: decoder.codingPath,
                                                debugDescription: "Cannot find match for this decoding")
            throw DecodingError.typeMismatch(JsonSchemaProperty.self, context)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        switch self {
        case .array(let value):
            try value.encode(to: encoder)
        case .const(let value):
            try value.encode(to: encoder)
        case .primitive(let value):
            try value.encode(to: encoder)
        case .reference(let value):
            try value.encode(to: encoder)
        }
    }
    
    public static func == (lhs: JsonSchemaProperty, rhs: JsonSchemaProperty) -> Bool {
        switch lhs {
        case .array(let lv):
            if case .array(let rv) = rhs { return rv == lv } else { return false }
        case .const(let lv):
            if case .const(let rv) = rhs { return rv == lv } else { return false }
        case .primitive(let lv):
            if case .primitive(let rv) = rhs { return rv == lv } else { return false }
        case .reference(let lv):
            if case .reference(let rv) = rhs { return rv == lv } else { return false }
        }
    }
}

public enum JsonSchemaArrayElement : Codable, Equatable, Hashable {
    case primitive(JsonSchemaPrimitive)
    case reference(JsonSchemaObjectRef)
    
    public init(from decoder: Decoder) throws {
        if let obj = try? JsonSchemaObjectRef(from: decoder) {
            self = .reference(obj)
        }
        else if let obj = try? JsonSchemaPrimitive(from: decoder), obj.isValidDecoding {
            self = .primitive(obj)
        }
        else {
            let context = DecodingError.Context(codingPath: decoder.codingPath,
                                                debugDescription: "Cannot find match for this decoding")
            throw DecodingError.typeMismatch(JsonSchemaArrayElement.self, context)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        switch self {
        case .primitive(let value):
            try value.encode(to: encoder)
        case .reference(let value):
            try value.encode(to: encoder)
        }
    }
    
    public static func == (lhs: JsonSchemaArrayElement, rhs: JsonSchemaArrayElement) -> Bool {
        switch lhs {
        case .primitive(let lv):
            if case .primitive(let rv) = rhs { return rv == lv } else { return false }
        case .reference(let lv):
            if case .reference(let rv) = rhs { return rv == lv } else { return false }
        }
    }
}

public struct JsonSchemaObjectRef : Codable, Equatable, Hashable {
    private enum CodingKeys : String, CodingKey {
        case ref = "$ref", description
    }
    public let ref: JsonSchemaReferenceId
    public let description: String?
    
    public init(ref: JsonSchemaReferenceId, description: String? = nil) {
        self.ref = ref
        self.description = description
    }
}

public struct JsonSchemaObject : PolymorphicSchemaElement, Codable, Equatable, Hashable {
    private enum CodingKeys : String, CodingKey {
        case id = "$id", jsonType = "type", title, description, properties, required, allOf, additionalProperties, examples
    }
    
    public let id: JsonSchemaReferenceId
    public private(set) var jsonType: JsonType = .object
    public let title: String?
    public let description: String?
    public let allOf: [JsonSchemaObjectRef]?
    public let properties: [String : JsonSchemaProperty]?
    public let required: [String]?
    private let additionalProperties: JsonElement?
    public let examples: [AnyCodableDictionary]?
    
    public var isOpen: Bool {
        return additionalProperties == nil
    }
    
    public init(id: JsonSchemaReferenceId,
                properties: [String : JsonSchemaProperty]? = nil,
                required: [String]? = nil,
                isOpen: Bool = false,
                description: String? = "",
                interfaces: [JsonSchemaReferenceId]? = nil,
                examples: [[String : JsonSerializable]]? = nil) {
        self.id = id
        self.title = id.className
        self.description = description
        self.additionalProperties = isOpen ? nil : .boolean(false)
        self.allOf = interfaces?.map { JsonSchemaObjectRef(ref: $0) }
        self.properties = properties
        self.required = required
        self.examples = (examples == nil) ? nil : examples!.map { AnyCodableDictionary($0)}
    }
    
    fileprivate var isValidDecoding: Bool {
        return jsonType == .object
    }
}

public struct JsonSchemaArray : Codable, Equatable, Hashable {
    private enum CodingKeys : String, CodingKey {
        case jsonType = "type", items, description
    }
    
    public private(set) var jsonType: JsonType = .array
    public let items: JsonSchemaArrayElement
    public let description: String?
    
    public init(items: JsonSchemaArrayElement, description: String? = nil) {
        self.items = items
        self.description = description
    }
}

public struct JsonSchemaPrimitive : Codable, Equatable, Hashable {
    private enum CodingKeys : String, CodingKey {
        case jsonType = "type", defaultValue = "default", description
    }
    
    public let jsonType: JsonType
    public let defaultValue: JsonElement?
    public let description: String?
    
    static public let string = JsonSchemaPrimitive(jsonType: .string)
    static public let integer = JsonSchemaPrimitive(jsonType: .integer)
    static public let number = JsonSchemaPrimitive(jsonType: .number)
    static public let boolean = JsonSchemaPrimitive(jsonType: .boolean)
    
    public init(jsonType: JsonType, description: String? = nil) {
        self.defaultValue = nil
        self.jsonType = jsonType
        self.description = description
    }
    
    public init(defaultValue: JsonElement, description: String? = nil) {
        self.defaultValue = defaultValue
        self.jsonType = defaultValue.jsonType
        self.description = description
    }
    
    fileprivate var isValidDecoding: Bool {
        return jsonType.isPrimitive
    }
}

public struct JsonSchemaStringLiteral : Codable, Equatable, Hashable {
    private enum CodingKeys : String, CodingKey {
        case id = "$id", jsonType = "type", title, description, pattern, examples
    }
    public let id: JsonSchemaReferenceId
    public private(set) var jsonType: JsonType = .string
    public let title: String?
    public let description: String?
    public let pattern: String?
    public let examples: [String]?

    public init(id: JsonSchemaReferenceId,
                description: String = "",
                examples: [String]? = nil,
                pattern: NSRegularExpression? = nil) {
        self.id = id
        self.title = id.className
        self.description = description
        self.pattern = pattern?.pattern
        self.examples = examples
    }
    
    fileprivate var isValidDecoding: Bool {
        return jsonType == .string
    }
}

public struct JsonSchemaStringEnum : Codable, Equatable, Hashable {
    private enum CodingKeys : String, CodingKey {
        case id = "$id", jsonType = "type", title, values = "enum", description
    }
    public let id: JsonSchemaReferenceId
    public private(set) var jsonType: JsonType = .string
    public let values: [String]
    public let title: String?
    public let description: String?
    
    public init(id: JsonSchemaReferenceId,
                values: [String],
                description: String = "") {
        self.id = id
        self.title = id.className
        self.description = description
        self.values = values
    }
}

public struct JsonSchemaConst : Codable, Equatable, Hashable {
    private enum CodingKeys : String, CodingKey {
        case const, ref = "$ref", description
    }
    public let const: String
    public let ref: JsonSchemaReferenceId?
    public let description: String?
    
    public init(const: String,
                ref: JsonSchemaReferenceId? = nil,
                description: String? = nil) {
        self.const = const
        self.ref = ref
        self.description = description
    }
}

public struct JsonSchemaReferenceId : Codable, Equatable, Hashable {
    public let className: String
    public let classPath: String
    
    public var isExternal: Bool {
        return classPath.lowercased().hasSuffix(".json")
    }
    
    public var baseURL: URL? {
        return classPath.hasPrefix("http") ? URL(string: classPath)?.deletingLastPathComponent() : nil
    }
    
    init(_ className: String, isExternal: Bool = false, baseURL: URL? = nil) {
        self.className = className
        if isExternal {
            let filename = "\(className).json"
            if let base = baseURL {
                self.classPath = base.appendingPathComponent(filename).absoluteString
            }
            else {
                self.classPath = filename
            }
        }
        else {
            self.classPath = "#\(className)"
        }
    }
    
    init(url: URL) {
        self.classPath = url.absoluteString
        self.className = url.deletingPathExtension().lastPathComponent
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let stringValue = try container.decode(String.self)

        if stringValue.hasPrefix("#"), stringValue.count > 1 {
            self.className = String(stringValue[stringValue.index(after: stringValue.startIndex)...])
        }
        else if stringValue.lowercased().hasSuffix(".json"), stringValue.count > 5, let url = URL(string: stringValue) {
            self.className = url.deletingPathExtension().lastPathComponent
        }
        else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "'\(stringValue)' is not a valid string. JsonSchemaReferenceId must either begin with '#' or end with '.json'")
        }
        self.classPath = stringValue
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(classPath)
    }
}
