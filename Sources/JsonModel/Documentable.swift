//
//  Documentable.swift
//  
//

import Foundation

/// Hardcoded URL to the repo that hosts the json schemas for the mobile client shared libraries.
public let kBDHJsonSchemaBaseURL = URL(string: "https://bridgedigitalhealth.github.io/mobile-client-json/schemas/v2/")!
public let kSageJsonSchemaBaseURL = kBDHJsonSchemaBaseURL

public protocol TypeRepresentable : Hashable, RawRepresentable, ExpressibleByStringLiteral {
    var stringValue: String { get }
}

extension RawRepresentable where Self.RawValue == String {
    public var stringValue: String { return rawValue }
}

/// A `Documentable` is used to create the `JsonSchema` for a collection of serializable objects.
/// It is generally assumed that the objects conform to `Decodable` and/or `Encodable` but neither
/// protocol is required
public protocol Documentable {
}

extension Documentable {
    public static func documentableType() -> Documentable.Type {
        return self
    }
}

public protocol DocumentableString : Documentable, Codable {
    /// Not all of the string literals have a `rawValue` of a `String` but they should all be
    /// codable using a string value.
    var stringValue: String { get }
}

public protocol DocumentableStringEnum : DocumentableString {
    /// An array of encodable objects to use as the set of examples for decoding this object.
    static func allValues() -> [String]
}

public protocol StringEnumSet : Hashable, RawRepresentable, CaseIterable where RawValue == String {
}

extension StringEnumSet {
    public static func allValues() -> [String] {
        return self.allCases.map { $0.rawValue }
    }
    
    public var indexPosition: Int {
        type(of: self).allValues().firstIndex(of: self.stringValue)!
    }
    
    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.indexPosition < rhs.indexPosition
    }
}

public protocol DocumentableCodingKey : CodingKey, DocumentableStringEnum, StringEnumSet {
    static var requiredKeys: [Self] { get }
}

public protocol DocumentableStringLiteral : DocumentableString {
    /// An array of encodable objects to use as the set of examples for decoding this object.
    static func examples() -> [String]
}

public protocol DocumentableStringOptionSet : Documentable, Codable {
    
    /// An array of encodable objects to use as the set of examples for decoding this object.
    static func examples() -> [String]
}

public protocol DocumentableAny : Documentable {
    /// Any dictionary that can be used to define the json schema definition for this object.
    static func jsonSchemaDefinition() -> [String : JsonSerializable]
}

public protocol DocumentableRoot {
    
    /// The class name for the root object.
    var className: String { get }
    
    /// The schema for json serialization strategy that this document describes.
    var jsonSchema: URL { get }
    
    /// The description to use in documentation.
    var documentDescription: String? { get }

    /// Does the root document define an array of `rootType` objects or is this the root object itself?
    var isDocumentTypeArray: Bool { get }
    
    /// The root object that includes the properties and definitions for object this document is describing.
    var rootDocumentType: DocumentableBase.Type { get }
}

public protocol DocumentableBase : Documentable {
    
    /// A list of `CodingKey` values for all the `Codable` properties on this object.
    static func codingKeys() -> [CodingKey]
    
    /// Is the coding key required?
    static func isRequired(_ codingKey: CodingKey) -> Bool
    
    /// Returns the property mapping for the
    static func documentProperty(for codingKey: CodingKey) throws -> DocumentProperty
}

/// Used to build Json Schema definitions and property references.
public protocol DocumentableObject : DocumentableBase {
    
    /// Can this class be subclassed?
    static func isOpen() -> Bool
    
    /// The example JSON for this object.
    static func jsonExamples() throws -> [[String : JsonSerializable]]
}

/// A protocol that allows a JsonSchema to define "additionalProperties" explicitly.
/// Any serializable object that may be serialized using other languages that have
/// a different set of required properties (for example, Kotlin serialization) should
/// not set `additionalProperties == false`.
public protocol FinalDocumentableObject : DocumentableStruct {
    static var additionalProperties: Bool { get }
}

/// Structs that implement the Codable protocol.
public protocol DocumentableStruct : DocumentableObject, Codable {
    static func examples() -> [Self]
}

extension DocumentableStruct {
    // A struct is always final.
    public static func isOpen() -> Bool {
        return false
    }
    
    // The examples can be created by encoding self as a dictionary.
    public static func jsonExamples() throws -> [[String : JsonSerializable]] {
        return try examples().map { try $0.jsonEncodedDictionary() }
    }
    
    /// A fall-back method for defining the document properties.
    ///
    /// - Note: This function can only handle cases where
    /// (a) the examples include all the coding keys with non-nil values, and
    /// (b) sets and arrays only support `[String]`, `[Int]`, or `[Double]`, and
    /// (c) the mirrored values do not include interfaces, constants, dictionaries, or default values.
    public static func mirroredPropertyType(for codingKey: CodingKey) throws -> DocumentProperty {
        for example in examples() {
            let mirror = Mirror(reflecting: example)
            for child in mirror.children {
                if child.label == codingKey.stringValue {
                    if child.value is Date {
                        return .init(propertyType: .format(.dateTime))
                    }
                    else if child.value is URL {
                        return .init(propertyType: .format(.uri))
                    }
                    else if child.value is UUID {
                        return .init(propertyType: .format(.uuid))
                    }
                    else if let obj = child.value as? Documentable {
                        return .init(propertyType: .reference(type(of: obj).documentableType()))
                    }
                    else if let obj = child.value as? DocumentableSequence, let docType = obj.castDocumentableType() {
                        return .init(propertyType: .referenceArray(docType))
                    }
                    else if child.value is String {
                        return .init(propertyType: .primitive(.string))
                    }
                    else if child.value is Bool {
                        return .init(propertyType: .primitive(.boolean))
                    }
                    else if child.value is IntegerNumber {
                        return .init(propertyType: .primitive(.integer))
                    }
                    else if child.value is JsonNumber {
                        return .init(propertyType: .primitive(.number))
                    }
                    else if child.value is [String] || child.value is Set<String> {
                        return .init(propertyType: .primitiveArray(.string))
                    }
                    else if child.value is [Int] || child.value is Set<Int> {
                        return .init(propertyType: .primitiveArray(.integer))
                    }
                    else if child.value is [JsonNumber] || child.value is Set<Double> {
                        return .init(propertyType: .primitiveArray(.number))
                    }
                }
            }
        }
        throw DocumentableError.cannotMirror(codingKey)
    }
}

protocol DocumentableSequence {
    func castDocumentableType() -> Documentable.Type?
}

extension Set : DocumentableSequence where Element : Documentable {
    func castDocumentableType() -> Documentable.Type? {
        Array(self).castDocumentableType()
    }
}

extension Array : DocumentableSequence where Element : Documentable {
    func castDocumentableType() -> Documentable.Type? {
        first.flatMap { firstObj in
            let docType = type(of: firstObj).documentableType()
            for element in self {
                if type(of: element) != docType {
                    return nil
                }
            }
            return docType
        }
    }
}

public protocol GenericDocumentableStruct : DocumentableStruct {
    associatedtype CodingKeys : DocumentableCodingKey
}

extension GenericDocumentableStruct {
    /// A generic documentable struct is a true struct and the coding keys can be a single level.
    public static func codingKeys() -> [CodingKey] {
        CodingKeys.allCases.map { $0 as CodingKey }
    }
    
    /// The required keys are defined on the enum.
    public static func isRequired(_ codingKey: CodingKey) -> Bool {
        (codingKey as? CodingKeys).map { CodingKeys.requiredKeys.contains($0) } ?? false
    }
}

/// A documentable root object is an object that has a *required* initializer with no parameters
/// that can be used for examples.
public protocol DocumentableRootObject : DocumentableObject, DocumentableRoot {
    init()
}

extension DocumentableRootObject {
    // A documentable root describes an object, not an array.
    public var isDocumentTypeArray: Bool { false }
    
    // A documentable root has a root type that is always itself.
    public var rootDocumentType: DocumentableBase.Type { type(of: self) }
    
    // The class name is the class name of *this* object.
    public var className: String { "\(rootDocumentType)" }
}

public protocol DocumentableInterface : DocumentableBase, DocumentableRoot {
    
    /// The name of the interface that is described by this documentable.
    var interfaceName: String { get }
    
    /// A list of `DocumentableObject.Type` classes that implement this interface.
    func documentableAnyOf() -> [DocumentableObject.Type]
    
    /// Is the interface sealed or can it be extended?
    func isSealed() -> Bool
    
    // The "type" key for this interface.
    static func typeDocumentProperty() -> DocumentProperty
}

extension DocumentableInterface {
    
    // The class name is the interface name.
    public var className: String { interfaceName }
    
    // An interface describes an object, not an array.
    public var isDocumentTypeArray: Bool { false }

    // The root document type is itself.
    public var rootDocumentType: DocumentableBase.Type { type(of: self) }
    
}

public struct DocumentableRootArray : DocumentableRoot {
    public let rootDocumentType: DocumentableBase.Type
    public let jsonSchema: URL
    public let documentDescription: String?
    
    public init(rootDocumentType: DocumentableBase.Type, jsonSchema: URL, documentDescription: String? = nil) {
        self.jsonSchema = jsonSchema
        self.rootDocumentType = rootDocumentType
        self.documentDescription = documentDescription
    }
    
    public var isDocumentTypeArray: Bool { true }
    
    public var className: String { "\(rootDocumentType)" }
}

/// A light-weight wrapper
public struct DocumentProperty {

    let propertyType: PropertyType
    let constValue: String?
    let defaultValue: JsonElement?
    let propertyDescription: String?
    
    public enum PropertyType : Equatable {
        case any
        case format(JsonSchemaFormat)
        case primitive(JsonType)
        case primitiveArray(JsonType)
        case primitiveDictionary(JsonType)
        case reference(Documentable.Type)
        case referenceArray(Documentable.Type)
        case referenceDictionary(Documentable.Type)
        case interface(String)
        case interfaceArray(String)
        case interfaceDictionary(String)
        
        public static func == (lhs: DocumentProperty.PropertyType, rhs: DocumentProperty.PropertyType) -> Bool {
            if case .any = lhs, case .any = rhs {
                return true
            }
            else if case .format(let lhsValue) = lhs, case .format(let rhsValue) = rhs {
                return lhsValue == rhsValue
            }
            else if case .primitive(let lhsValue) = lhs, case .primitive(let rhsValue) = rhs {
                return lhsValue == rhsValue
            }
            else if case .primitiveArray(let lhsValue) = lhs, case .primitiveArray(let rhsValue) = rhs {
                return lhsValue == rhsValue
            }
            else if case .primitiveDictionary(let lhsValue) = lhs, case .primitiveDictionary(let rhsValue) = rhs {
                return lhsValue == rhsValue
            }
            else if case .interface(let lhsValue) = lhs, case .interface(let rhsValue) = rhs {
                return lhsValue == rhsValue
            }
            else if case .interfaceArray(let lhsValue) = lhs, case .interfaceArray(let rhsValue) = rhs {
                return lhsValue == rhsValue
            }
            else if case .interfaceDictionary(let lhsValue) = lhs, case .interfaceDictionary(let rhsValue) = rhs {
                return lhsValue == rhsValue
            }
            else {
                return false
            }
        }
    }
    
    public init(propertyType: PropertyType, propertyDescription: String? = nil) {
        self.propertyType = propertyType
        self.constValue = nil
        self.defaultValue = nil
        self.propertyDescription = propertyDescription
    }
    
    public init(defaultValue: JsonElement, propertyDescription: String? = nil) {
        self.propertyType = .primitive(defaultValue.jsonType)
        self.constValue = nil
        self.defaultValue = defaultValue
        self.propertyDescription = propertyDescription
    }
    
    public init(constValue: DocumentableString, propertyDescription: String? = nil) {
        self.propertyType = .reference(type(of: constValue))
        self.constValue = constValue.stringValue
        self.defaultValue = nil
        self.propertyDescription = propertyDescription
    }
}

/// Errors that can be thrown while building documentation.
public enum DocumentableError : Error {
    
    /// Not a valid coding key path for this object.
    case invalidCodingKey(CodingKey, String)
    
    /// The json schema could not be built b/c the mappings weren't set up correctly.
    case invalidMapping(String)
    
    /// The given coding key cannot be mirrored using the Documentable examples
    case cannotMirror(CodingKey)
    
    /// The domain of the error.
    public static var errorDomain: String {
        return "DocumentableErrorDomain"
    }
    
    /// The error code within the given domain.
    public var errorCode: Int {
        switch(self) {
        case .invalidCodingKey(_, _):
            return -1
        case .invalidMapping(_):
            return -2
        case .cannotMirror(_):
            return -3
        }
    }
    
    /// The user-info dictionary.
    public var errorUserInfo: [String : Any] {
        let description: String
        switch(self) {
        case .invalidCodingKey(_, let str): description = str
        case .invalidMapping(let str): description = str
        case .cannotMirror(let key): description = "Cannot mirror `\(key.stringValue)` using the provided examples."
        }
        return ["NSDebugDescription": description]
    }
}
