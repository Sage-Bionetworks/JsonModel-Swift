//
//  PolymorphicSerializer.swift
//  
//

import Foundation

/// A `Decodable` implementation that includes a mapping of the value of the "type" keyword that
/// is used to define the polymorphic serialization for this object.
///
/// Swift Codable does not include any mechanism for serialization using the "type" keyword in the
/// JSON that is typical of POJO (Plain Old Java Object) model objects. Therefore, the "type"
/// keyword needs to be explicitly defined in the `CodingKeys` enum in order for the `Codable`
/// protocol methods to be auto-synthesized by the compiler. Additionally, when defining your
/// classes and structs, it is often helpful to be able to describe the class type using the
/// extensible string enum pattern. Finally, "type" is a special syntax word in Swift and so using
/// that word makes for messy, hard-to-read code. Therefore, this protocol returns the `String`
/// value as `typeName` rather than mapping directly to `type`.
///
/// - seealso: `PolymorphicSerializerTests`
///
public protocol PolymorphicRepresentable : PolymorphicTyped, Decodable {
}

public protocol PolymorphicTyped {
    /// A "name" for the class of object that can be used in Dictionary representable objects.
    var typeName: String { get }
}

/// The generic method for a decodable. This is a work-around for the limitations of Swift generics
/// where an instance of a class that has an associated type cannot be stored in a dictionary or
/// array.
public protocol GenericSerializer : AnyObject {
    var interfaceName : String { get }
    func decode(from decoder: Decoder) throws -> Any
    func documentableExamples() -> [DocumentableObject]
    func canDecode(_ typeName: String) -> Bool
    func validate() throws
}

/// A serializer protocol for decoding serializable objects.
///
/// This serializer is designed to allow for decoding objects that use
/// [kotlinx.serialization](https://github.com/Kotlin/kotlinx.serialization) so it requires that
/// the "type" key is set as a special property in the JSON. While you *can* change the default
/// key in the JSON dictionary, this is not recommended because it would require all of your
/// Swift Codable implementations to also use the new coding key.
///
public protocol PolymorphicSerializer : GenericSerializer, DocumentableInterface {
    /// The `ProtocolValue` is the protocol or base class to which all the codable objects for this
    /// serializer should conform.
    associatedtype ProtocolValue

    /// Examples for each decodable.
    var examples: [ProtocolValue] { get }
    
    /// Get a string that will identify the type of object to instantiate for the given decoder.
    ///
    /// By default, this will look in the container for the decoder for a key/value pair where
    /// the key == "type" and the value is a `String`.
    ///
    /// - parameter decoder: The decoder to inspect.
    /// - returns: The string representing this class type (if found).
    /// - throws: `DecodingError` if the type name cannot be decoded.
    func typeName(from decoder: Decoder) throws -> String
}

extension PolymorphicSerializer {
    
    /// The name of the base class or protocol to set as the base implementation that is deserialized
    /// by this serializer.
    public var interfaceName : String {
        return "\(ProtocolValue.self)"
    }
    
    public func validate() throws {
        try examples.forEach {
            guard $0 is PolymorphicRepresentable else {
                let context = DecodingError.Context(codingPath: [], debugDescription: "\($0) does not conform to the PolymorphicRepresentable protocol")
                throw DecodingError.typeMismatch(PolymorphicRepresentable.self, context)
            }
        }
    }
    
    public func canDecode(_ typeName: String) -> Bool {
        findExample(for: typeName) != nil
    }
    
    /// Find an example for the given `typeName` key.
    public func findExample(for typeName: String) -> ProtocolValue? {
        examples.first { ($0 as? PolymorphicRepresentable)?.typeName == typeName }
    }
    
    public func decode(from decoder: Decoder) throws -> Any {
        let name = try typeName(from: decoder)
        guard let example = findExample(for: name) as? Decodable else {
            throw PolymorphicSerializerError.exampleNotFound(name)
        }
        return try type(of: example.self).init(from: decoder)
    }
    
    public func documentableExamples() -> [DocumentableObject] {
        return examples.compactMap { $0 as? DocumentableObject }
    }
}

open class AbstractPolymorphicSerializer {
    public enum TypeKeys: String, Codable, OpenOrderedCodingKey {
        case type
        public var sortOrderIndex: Int? { 0 }
        public var relativeIndex: Int { 0 }
    }
    
    public init() {
    }
    
    open func typeName(from decoder: Decoder) throws -> String {
        let container = try decoder.container(keyedBy: TypeKeys.self)
        guard let type = try container.decodeIfPresent(String.self, forKey: .type) else {
            throw PolymorphicSerializerError.typeKeyNotFound
        }
        return type
    }
    
    open func isSealed() -> Bool {
        false
    }
    
    /// Default is to return the "type" key.
    open class func codingKeys() -> [CodingKey] {
        [TypeKeys.type]
    }
    
    /// Default is to return `true`.
    open class func isRequired(_ codingKey: CodingKey) -> Bool {
        true
    }
    
    open class func documentProperty(for codingKey: CodingKey) throws -> DocumentProperty {
        guard let _ = codingKey as? TypeKeys else {
            throw DocumentableError.invalidCodingKey(codingKey, "\(codingKey) is not handled by \(self).")
        }
        return typeDocumentProperty()
    }
    
    /// Default is a string but this can be overriden to return a `TypeRepresentable` reference.
    open class func typeDocumentProperty() -> DocumentProperty {
        DocumentProperty(propertyType: .primitive(.string))
    }
}

public enum PolymorphicSerializerError : Error {
    case typeKeyNotFound
    case exampleNotFound(String)
}

