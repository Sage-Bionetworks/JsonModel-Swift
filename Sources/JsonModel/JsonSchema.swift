//
//  JsonSchema.swift
//

import Foundation

/// `JsonSchema` includes a subset of the json schema defined by
/// http://json-schema.org/draft-07/schema# with some additional rules to simplify creating
/// serializable definitions in Swift and Kotlin.
///
/// - note: The composable elements in this code file are defined as public to allow for extending
/// the documentation, but should only be used at your own risk.
public struct JsonSchema : Codable, Hashable {
    private enum CodingKeys : String, OrderedEnumCodingKey {
        case id = "$id",
             schema = "$schema",
             jsonType = "type",
             title,
             description,
             definitions,
             items,
             properties,
             required,
             allOf,
             additionalProperties,
             examples
    }

    public let id: JsonSchemaReferenceId
    public let schema: String
    public let jsonType: JsonType
    public let definitions: [String : JsonSchemaDefinition]?
    public let root: JsonSchemaObject
    
    public init(id: URL,
                description: String,
                isArray: Bool,
                additionalProperties: Bool? = nil,
                codingKeys: [CodingKey],
                interfaces: [JsonSchemaObjectRef]?,
                definitions: [JsonSchemaDefinition],
                properties: [String : JsonSchemaProperty]?,
                required: [String]?,
                examples: [[String : JsonSerializable]]?) {
        
        let refId = JsonSchemaReferenceId(url: id)
        self.id = refId
        self.schema = "http://json-schema.org/draft-07/schema#"
        self.jsonType = isArray ? .array : .object

        // Build the definitions
        var allDefinitions: [JsonSchemaDefinition] = interfaces?.compactMap {
            guard let refId = $0.refId, !refId.isExternal else { return nil }
            return .object(JsonSchemaObject(id: refId))
        } ?? []
        allDefinitions.append(contentsOf: definitions)
        let defs = allDefinitions.reduce(into: [String : JsonSchemaDefinition]()) {
            guard let className = $1.className else { return }
            $0[className] = $1
        }
        self.definitions = defs.count == 0 ? nil : defs
        
        // Nil out the root of the object used to store typed info about this schema
        var root = JsonSchemaObject(id: refId,
                                    additionalProperties: additionalProperties,
                                    description: description,
                                    codingKeys: codingKeys,
                                    properties: properties,
                                    required: required,
                                    interfaces: interfaces,
                                    examples: examples)
        root.id = nil
        self.root = root
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.schema = try container.decode(String.self, forKey: .schema)
        self.id = try container.decode(JsonSchemaReferenceId.self, forKey: .id)
        self.definitions = try container.decodeIfPresent([String : JsonSchemaDefinition].self, forKey: .definitions)
        let jsonType = try container.decode(JsonType.self, forKey: .jsonType)
        self.jsonType = jsonType
        var root: JsonSchemaObject = try {
            switch jsonType {
            case .object:
                return try JsonSchemaObject(from: decoder)
            case .array:
                return try container.decode(JsonSchemaObject.self, forKey: .items)
            default:
                throw DecodingError.typeMismatch(JsonType.self,
                                                    .init(codingPath: decoder.codingPath,
                                                          debugDescription: "Unsupported root json type \(jsonType)",
                                                          underlyingError: nil))
            }
        }()
        root.id = nil
        if !root.isValidDecoding {
            throw DecodingError.typeMismatch(JsonType.self,
                                                .init(codingPath: decoder.codingPath,
                                                      debugDescription: "Unsupported root object json type \(root.jsonType)",
                                                      underlyingError: nil))
        }
        self.root = root
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.id, forKey: .id)
        try container.encode(self.schema, forKey: .schema)
        try container.encode(self.jsonType, forKey: .jsonType)
        try container.encodeIfPresent(self.definitions, forKey: .definitions)
        switch jsonType {
        case .object:
            try container.encodeIfPresent(root.title, forKey: .title)
            try container.encodeIfPresent(root.description, forKey: .description)
            try container.encodeIfPresent(root.orderedProperties, forKey: .properties)
            try container.encodeIfPresent(root.required, forKey: .required)
            try container.encodeIfPresent(root.allOf, forKey: .allOf)
            try container.encodeIfPresent(root.additionalProperties, forKey: .additionalProperties)
            try container.encodeIfPresent(root.examples, forKey: .examples)

        case .array:
            let description = "An array of `\(root.className ?? "Unknown")` objects."
            try container.encode(description, forKey: .description)
            try container.encode(self.root, forKey: .items)
            
        default:
            throw EncodingError.invalidValue(jsonType, .init(codingPath: encoder.codingPath, debugDescription: "Can only have a root that is an object or array", underlyingError: nil))
        }
    }
}

public enum JsonSchemaDefinition : Codable, Hashable {
    case object(JsonSchemaObject)
    case stringLiteral(JsonSchemaStringLiteral)
    case stringEnum(JsonSchemaStringEnum)
    case stringOptionSet(JsonSchemaStringOptionSet)
    case any(JsonSchemaAnyDefinition)
    
    public var className: String? {
        switch self {
        case .object(let value):
            return value.className
        case .stringEnum(let value):
            return value.id.className
        case .stringLiteral(let value):
            return value.id.className
        case .stringOptionSet(let value):
            return value.id.className
        case .any(let value):
            return value.id.className
        }
    }
    
    public init(from decoder: Decoder) throws {
        if let obj = try? JsonSchemaStringOptionSet(from: decoder) {
            self = .stringOptionSet(obj)
        }
        else if let obj = try? JsonSchemaStringEnum(from: decoder) {
            self = .stringEnum(obj)
        }
        else if let obj = try? JsonSchemaStringLiteral(from: decoder), obj.isValidDecoding {
            self = .stringLiteral(obj)
        }
        else if let obj = try? JsonSchemaObject(from: decoder), obj.isValidDecoding {
            self = .object(obj)
        }
        else if let obj = try? JsonSchemaAnyDefinition(from: decoder) {
            self = .any(obj)
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
        case .stringOptionSet(let value):
            try value.encode(to: encoder)
        case .any(let value):
            try value.encode(to: encoder)
        }
    }
}

public enum JsonSchemaProperty : Codable, Hashable {
    case array(JsonSchemaArray)
    case const(JsonSchemaConst)
    case dictionary(JsonSchemaTypedDictionary)
    case primitive(JsonSchemaPrimitive)
    case reference(JsonSchemaObjectRef)
    
    public init(from decoder: Decoder) throws {
        if let obj = try? JsonSchemaConst(from: decoder) {
            self = .const(obj)
        }
        else if let obj = try? JsonSchemaObjectRef(from: decoder) {
            self = .reference(obj)
        }
        else if let obj = try? JsonSchemaArray(from: decoder), obj.isValidDecoding {
            self = .array(obj)
        }
        else if let obj = try? JsonSchemaTypedDictionary(from: decoder), obj.isValidDecoding {
            self = .dictionary(obj)
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
        case .dictionary(let value):
            try value.encode(to: encoder)
        case .primitive(let value):
            try value.encode(to: encoder)
        case .reference(let value):
            try value.encode(to: encoder)
        }
    }
}

public enum JsonSchemaElement : Codable, Hashable {
    case primitive(JsonSchemaPrimitive)
    case reference(JsonSchemaObjectRef)
    case object(JsonSchemaObject)
    
    public init(from decoder: Decoder) throws {
        if let obj = try? JsonSchemaObjectRef(from: decoder) {
            self = .reference(obj)
        }
        else if let obj = try? JsonSchemaPrimitive(from: decoder), obj.isValidDecoding {
            self = .primitive(obj)
        }
        else if let obj = try? JsonSchemaObject(from: decoder), obj.isValidDecoding {
            self = .object(obj)
        }
        else {
            let context = DecodingError.Context(codingPath: decoder.codingPath,
                                                debugDescription: "Cannot find match for this decoding")
            throw DecodingError.typeMismatch(JsonSchemaElement.self, context)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        switch self {
        case .primitive(let value):
            try value.encode(to: encoder)
        case .reference(let value):
            try value.encode(to: encoder)
        case .object(let value):
            try value.encode(to: encoder)
        }
    }
}

public struct JsonSchemaObjectRef : Codable, Hashable {
    private enum CodingKeys : String, OrderedEnumCodingKey {
        case _ref = "$ref", description
    }
    public let description: String?
    public var refId: JsonSchemaReferenceId? { _ref.value }
    private let _ref: JsonSchemaRef
    
    var ref: String { _ref.encodingPath }
    
    public init(ref: JsonSchemaReferenceId?, description: String? = nil) {
        self._ref = .init(ref)
        self.description = description
    }
}

public struct JsonSchemaTypedDictionary : Codable, Hashable {
    private enum CodingKeys : String, OrderedEnumCodingKey {
        case jsonType = "type", description, additionalProperties
    }
    public private(set) var jsonType: JsonType = .object
    private let additionalProperties: JsonSchemaElement
    public let description: String?
    
    public var items: JsonSchemaElement {
        return additionalProperties
    }
    
    public init(items: JsonSchemaElement, description: String? = nil) {
        self.additionalProperties = items
        self.description = description
    }
    
    fileprivate var isValidDecoding: Bool {
        return jsonType == .object
    }
}

public struct JsonSchemaAnyDefinition : Codable, Hashable {
    public fileprivate(set) var id: JsonSchemaReferenceId
    
    public var definition: [String : JsonSerializable] {
        switch json {
        case .object(let dictionary):
            return dictionary
        default:
            return [:]
        }
    }
    private let json: JsonElement
    
    public init(id: JsonSchemaReferenceId,
                definition: [String : JsonSerializable]) {
        self.id = id
        self.json = .object(definition)
    }
    
    private enum CodingKeys : String, CodingKey {
        case id = "$id"
    }
    
    public init(from decoder: Decoder) throws {
        var dictionary = try AnyCodableDictionary(from: decoder).dictionary
        guard let idString = dictionary[CodingKeys.id.rawValue] as? String,
              let id = JsonSchemaReferenceId(stringValue: idString)
        else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription:
                                                        "$id is a required key for decoding definitions using this library."))
        }
        dictionary[CodingKeys.id.rawValue] = nil
        self.id = id
        self.json = .object(dictionary)
    }
    
    public func encode(to encoder: Encoder) throws {
        try self.json.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
    }
}

public struct JsonSchemaObject : Codable, Hashable {
    private enum CodingKeys : String, OrderedEnumCodingKey {
        case id = "$id", jsonType = "type", title, description, orderedProperties="properties", required, allOf, additionalProperties, examples
    }
    
    public fileprivate(set) var id: JsonSchemaReferenceId?
    public fileprivate(set) var title: String?
    public var className: String? { id?.className ?? title }
    
    public private(set) var jsonType: JsonType = .object
    public let description: String?
    public let allOf: [JsonSchemaObjectRef]?
    public let required: [String]?
    public let additionalProperties: Bool?
    public let examples: [AnyCodableDictionary]?
    
    public var properties: [String : JsonSchemaProperty]? {
        orderedProperties?.orderedDictionary._mapKeys { $0.stringValue }
    }
    let orderedProperties: OrderedJsonDictionary<JsonSchemaProperty>?

    public init(id: JsonSchemaReferenceId,
                additionalProperties: Bool? = nil,
                description: String? = "",
                codingKeys: [CodingKey] = [],
                properties: [String : JsonSchemaProperty]? = nil,
                required: [String]? = nil,
                interfaces: [JsonSchemaObjectRef]? = nil,
                examples: [[String : JsonSerializable]]? = nil) {
        self.id = id
        self.title = id.className
        self.description = description
        self.additionalProperties = additionalProperties
        self.allOf = (interfaces?.count ?? 0) == 0 ? nil : interfaces
        self.orderedProperties = (properties?.count ?? 0) == 0 ? nil : .init(properties!, orderedKeys: codingKeys)
        self.required = (required?.count ?? 0) == 0 ? nil : required
        self.examples = (examples?.count ?? 0) == 0 ? nil : examples!.map {
            AnyCodableDictionary($0, orderedKeys: codingKeys)
        }
    }
    
    fileprivate var isValidDecoding: Bool {
        return jsonType == .object
    }
}

public struct JsonSchemaArray : Codable, Hashable {
    private enum CodingKeys : String, OrderedEnumCodingKey {
        case jsonType = "type", description, items
    }
    
    public private(set) var jsonType: JsonType = .array
    public let items: JsonSchemaElement
    public let description: String?
    
    public init(items: JsonSchemaElement, description: String? = nil) {
        self.items = items
        self.description = description
    }
    
    fileprivate var isValidDecoding: Bool {
        return jsonType == .array
    }
}

public enum JsonSchemaFormat : String, Codable, Hashable {
    case dateTime = "date-time", date, time, uuid, uri, uriRelative = "uri-reference", email
}

public struct JsonSchemaPrimitive : Codable, Hashable {
    private enum CodingKeys : String, OrderedEnumCodingKey {
        case jsonType = "type", description, defaultValue = "default", format
    }
    
    public let jsonType: JsonType?
    public let description: String?
    public let defaultValue: JsonElement?
    public let format: JsonSchemaFormat?
    
    static public let string = JsonSchemaPrimitive(jsonType: .string)
    static public let integer = JsonSchemaPrimitive(jsonType: .integer)
    static public let number = JsonSchemaPrimitive(jsonType: .number)
    static public let boolean = JsonSchemaPrimitive(jsonType: .boolean)
    static public let any = JsonSchemaPrimitive()
    
    public init(description: String? = nil) {
        self.defaultValue = nil
        self.format = nil
        self.jsonType = nil
        self.description = description
    }
    
    public init(jsonType: JsonType, description: String? = nil) {
        self.defaultValue = nil
        self.format = nil
        self.jsonType = jsonType
        self.description = description
    }
    
    public init(defaultValue: JsonElement, description: String? = nil) {
        self.defaultValue = defaultValue
        self.format = nil
        self.jsonType = defaultValue.jsonType
        self.description = description
    }
    
    public init(format: JsonSchemaFormat, description: String? = nil) {
        self.defaultValue = nil
        self.format = format
        self.jsonType = .string
        self.description = description
    }
    
    fileprivate var isValidDecoding: Bool {
        return jsonType?.isPrimitive ?? true
    }
}

public struct JsonSchemaStringLiteral : Codable, Hashable {
    private enum CodingKeys : String, OrderedEnumCodingKey {
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

public struct JsonSchemaStringOptionSet : Codable, Hashable {
    private enum CodingKeys : String, OrderedEnumCodingKey {
        case id = "$id", jsonType = "type", title, description, items
    }
    public let id: JsonSchemaReferenceId
    public private(set) var jsonType: JsonType = .array
    public let title: String?
    public let description: String?
    
    private let items: StringOptions
    
    public var examples: [String]? {
        return items.examples
    }
    
    public var pattern: String? {
        return items.pattern
    }

    public init(id: JsonSchemaReferenceId,
                description: String = "",
                examples: [String]? = nil,
                pattern: NSRegularExpression? = nil) {
        self.id = id
        self.title = id.className
        self.description = description
        self.items = StringOptions(examples: examples, pattern: pattern?.pattern)
    }
    
    fileprivate var isValidDecoding: Bool {
        return jsonType == .string
    }
    
    struct StringOptions : Codable, Hashable {
        private(set) var jsonType: JsonType = .string
        let examples: [String]?
        let pattern: String?
    }
}

public struct JsonSchemaStringEnum : Codable, Hashable {
    private enum CodingKeys : String, OrderedEnumCodingKey {
        case id = "$id", jsonType = "type", title, description, values = "enum"
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

public struct JsonSchemaConst : Codable, Hashable {
    private enum CodingKeys : String, OrderedEnumCodingKey {
        case const, _ref = "$ref", description
    }
    public let const: String
    public var ref: JsonSchemaReferenceId? { _ref?.value}
    private let _ref: JsonSchemaRef?
    public let description: String?

    public init(const: String,
                ref: JsonSchemaReferenceId? = nil,
                description: String? = nil) {
        self.const = const
        self._ref = ref.map { .init($0) }
        self.description = description
    }
}

fileprivate let kDefinitionsPrefix = "#/definitions/"

struct JsonSchemaRef : Codable, Hashable {
    let value: JsonSchemaReferenceId?
    
    var encodingPath: String {
        value.map { ref in
            ref.classPath == "#\(ref.className)" ? "\(kDefinitionsPrefix)\(ref.className)" : ref.classPath
        } ?? "#"
    }
    
    init(_ value: JsonSchemaReferenceId?) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let stringValue = try container.decode(String.self)
        if stringValue.hasPrefix(kDefinitionsPrefix) {
            self.value = .init(String(stringValue.dropFirst(kDefinitionsPrefix.count)))
        }
        else if stringValue == "#" {
            self.value = nil
        }
        else {
            self.value = try .init(from: decoder)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(encodingPath)
    }
}

public struct JsonSchemaReferenceId : Codable, Hashable {
    public let className: String
    public let classPath: String
    public let url: URL?
    
    public var isExternal: Bool {
        classPath.lowercased().hasSuffix(".json")
    }
    
    public var baseURL: URL? {
        url?.baseURL
    }
    
    init(_ className: String, root: JsonSchemaReferenceId) {
        self.className = className
        self.classPath = "\(root.classPath)#\(className)"
        self.url = root.url.map {
            .init(string: "\($0.relativePath)#\(className)", relativeTo: $0.baseURL)!
        }
    }
    
    init(_ className: String, isExternal: Bool = false, baseURL: URL? = nil) {
        self.className = className
        if isExternal {
            let filename = "\(className).json"
            if let base = baseURL {
                self.classPath = base.appendingPathComponent(filename).absoluteString
                self.url = URL(string: filename, relativeTo: baseURL)
            }
            else {
                self.classPath = filename
                self.url = nil
            }
        }
        else {
            self.classPath = "#\(className)"
            self.url = nil
        }
    }
    
    init(url: URL) {
        self.classPath = url.absoluteString
        self.className = url.deletingPathExtension().lastPathComponent
        self.url = Self.parseURL(from: url)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let stringValue = try container.decode(String.self)
        guard let (className, url) = Self.parseClassName(stringValue: stringValue)
        else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "'\(stringValue)' is not a valid string. JsonSchemaReferenceId must either begin with '#' or end with '.json'")
        }
        self.className = className
        self.classPath = stringValue
        self.url = url
    }
    
    public init?(stringValue: String) {
        guard let (className, url) = Self.parseClassName(stringValue: stringValue)
        else {
            return nil
        }
        self.className = className
        self.classPath = stringValue
        self.url = url
    }
    
    private static func parseClassName(stringValue: String) -> (String, URL?)? {
        if let idx = stringValue.lastIndex(of: "#") {
            return (String(stringValue[stringValue.index(after: idx)...]), nil)
        }
        else if stringValue.lowercased().hasSuffix(".json"), stringValue.count > 5, let url = URL(string: stringValue) {
            return (url.deletingPathExtension().lastPathComponent, parseURL(from: url))
        }
        else {
            return nil
        }
    }
    
    private static func parseURL(from url: URL) -> URL? {
        let relativePath = url.lastPathComponent
        let baseUrl = url.deletingLastPathComponent()
        return baseUrl.absoluteString.hasPrefix("http") ? URL(string: relativePath, relativeTo: baseUrl) : nil
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(classPath)
    }
}

struct OrderedJsonDictionary<Element : Codable> : Codable, Hashable where Element : Hashable {
    let orderedDictionary : [AnyCodingKey : Element]
    
    init(_ dictionary : [String : Element], orderedKeys: [CodingKey]) {
        self.orderedDictionary = dictionary._mapKeys {
            .init(stringValue: $0, orderedKeys: orderedKeys)
        }
    }
    
    init(_ dictionary : [AnyCodingKey : Element]) {
        self.orderedDictionary = dictionary
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnyCodingKey.self)
        let allKeys = container.allKeys
        var dictionary = Dictionary<AnyCodingKey, Element>()
        for codingKey in allKeys {
            let orderedKey: AnyCodingKey = .init(stringValue: codingKey.stringValue,
                                                 intValue: allKeys.firstIndex(where: { $0.stringValue == codingKey.stringValue }))
            let nestedDecoder = try container.superDecoder(forKey: codingKey)
            dictionary[orderedKey] = try Element.init(from: nestedDecoder)
        }
        self.orderedDictionary = dictionary
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: AnyCodingKey.self)
        try orderedDictionary.forEach { (key, value) in
            let nestedEncoder = container.superEncoder(forKey: key)
            try value.encode(to: nestedEncoder)
        }
    }
}
