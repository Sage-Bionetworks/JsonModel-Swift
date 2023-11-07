// Created 11/7/23
// swift-tools-version:5.0

import Foundation

@available(*, deprecated, message: "Use `GenericPolymorphicSerializer` instead.")
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

@available(*, deprecated, message: "Use `GenericPolymorphicSerializer` instead.")
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
    
    public func documentableAnyOf() -> [DocumentableObject.Type] {
        documentableExamples().map { type(of: $0) }
    }
}

@available(*, deprecated, message: "Use `GenericPolymorphicSerializer` instead.")
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
