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
/// - See Also: `PolymorphicSerializerTests`
///
public protocol PolymorphicRepresentable : PolymorphicTyped, Decodable {
}

/// An explicitly defined protocol for a polymorphically-typed serializable value.
///
/// - Discussion:
/// Older implementations of the `JsonModel-Swift` package followed the Obj-C compatible
/// serialization protocols defined in Swift 2.0 where an object could conform to either the
/// `Encodable` protocol or the `Decodable` protocol without conforming to the `Codable`
/// protocol. Additionally, these older objects often had serialization strategies that
/// conflicted with either encoding or decoding. To work-around this, we introduced the
/// `PolymorphicRepresentable` protocol which **only** required adherence to the `Decodable`
/// protocol and not to the `Encodable` protocol. This allowed developers who only needed
/// to decode their objects, to use the ``SerializationFactory`` to handle polymorphic
/// object decoding without requiring them to also implement an unused `Encodable` protocol
/// adherence.
public protocol PolymorphicCodable : PolymorphicRepresentable, Encodable {
}

/// This is the original protocol used by ``PolymorphicSerializer`` to decode an object from
/// a list of example instances. It is retained so that older implementations of polymorphic
/// objects do not need to be migrated.
public protocol PolymorphicTyped {
    /// A "name" for the class of object that can be used in Dictionary representable objects.
    var typeName: String { get }
}

/// A **static** implementation that allows decoding from an object Type rather than requiring
/// an example instance.
public protocol PolymorphicStaticTyped : PolymorphicTyped {
    /// A "name" for the class of object that can be used in Dictionary representable objects.
    static var typeName: String { get }
}

extension PolymorphicStaticTyped {
    public var typeName: String { Self.typeName }
}

/// The generic method for a decodable. This is a work-around for the limitations of Swift generics
/// where an instance of a class that has an associated type cannot be stored in a dictionary or
/// array.
///
/// - Note:
/// When this library was originally written, Swift Generics were very limited in functionality.
/// This protocol was originally designed as a work-around to those limitations. While generics
/// are much more useful with Swift 5.7, the original implementation is retained.
///
public protocol GenericSerializer : AnyObject {
    var interfaceName : String { get }
    func decode(from decoder: Decoder) throws -> Any
    func documentableExamples() -> [DocumentableObject]
    func canDecode(_ typeName: String) -> Bool
    func validate() throws
}

extension Decodable {
    static func decodingType() -> Decodable.Type {
        self
    }
}

/// A serializer for decoding serializable objects.
///
/// This serializer is designed to allow for decoding objects that use
/// [kotlinx.serialization](https://github.com/Kotlin/kotlinx.serialization) so it requires that
/// the "type" key is set as a special property in the JSON. While you *can* change the default
/// key in the JSON dictionary, this is not recommended because it would require all of your
/// Swift Codable implementations to also use the new coding key.
///
open class GenericPolymorphicSerializer<ProtocolValue> : GenericSerializer {
    public private(set) var typeMap: [String : Decodable.Type] = [:]
    
    public var examples: [ProtocolValue] {
        _examples.map { $0.value }
    }
    private var _examples: [String : ProtocolValue] = [:]
    
    public init() {
    }
    
    public init(_ examples: [ProtocolValue]) {
        examples.forEach { example in
            try? self.add(example)
        }
    }
    
    public init(_ types: [Decodable.Type]) {
        types.forEach { decodable in
            self.add(typeOf: decodable)
        }
    }
    
    /// Insert the given example into the example array, replacing any existing example with the
    /// same `typeName` as one of the new example.
    public final func add(_ example: ProtocolValue) throws {
        guard let decodable = example as? Decodable else {
            throw PolymorphicSerializerError.exampleNotDecodable(example)
        }
        let typeValue = type(of: decodable).decodingType()
        let typeName = (example as? PolymorphicTyped)?.typeName ?? "\(typeValue)"
        typeMap[typeName] = typeValue
        _examples[typeName] = example
    }

    /// Insert the given examples into the example array, replacing any existing examples with the
    /// same `typeName` as one of the new examples.
    public final func add(contentsOf newExamples: [ProtocolValue]) throws {
        try newExamples.forEach { example in
            try self.add(example)
        }
    }
    
    /// Insert the given `ProtocolValue.Type` into the type map, replacing any existing class with
    /// the same "type" decoding.
    public final func add(typeOf typeValue: Decodable.Type) {
        let typeName = (typeValue as? PolymorphicStaticTyped.Type)?.typeName ?? "\(typeValue)"
        typeMap[typeName] = typeValue
        _examples[typeName] = nil
    }
    
    open func typeName(from decoder: Decoder) throws -> String {
        let container = try decoder.container(keyedBy: PolymorphicCodableTypeKeys.self)
        guard let type = try container.decodeIfPresent(String.self, forKey: .type) else {
            throw PolymorphicSerializerError.typeKeyNotFound
        }
        return type
    }
    
    // MARK: GenericSerializer
    
    public var interfaceName: String {
        "\(ProtocolValue.self)"
    }
    
    public func decode(from decoder: Decoder) throws -> Any {
        let name = try typeName(from: decoder)
        guard let typeValue = typeMap[name] else {
            throw PolymorphicSerializerError.exampleNotFound(name)
        }
        return try typeValue.init(from: decoder)
    }
    
    public func documentableExamples() -> [DocumentableObject] {
        examples.compactMap { $0 as? DocumentableObject }
    }
    
    public func canDecode(_ typeName: String) -> Bool {
        typeMap[typeName] != nil
    }
    
    public func validate() throws {
        // do nothing
    }
    
    // MARK: DocumentableInterface
    
    /// Protocols are not sealed.
    open func isSealed() -> Bool {
        false
    }
    
    /// Default is to return the "type" key.
    open class func codingKeys() -> [CodingKey] {
        [PolymorphicCodableTypeKeys.type]
    }
    
    /// Default is to return `true`.
    open class func isRequired(_ codingKey: CodingKey) -> Bool {
        true
    }
    
    /// Default is to return the "type" property.
    open class func documentProperty(for codingKey: CodingKey) throws -> DocumentProperty {
        guard let _ = codingKey as? PolymorphicCodableTypeKeys else {
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
    case exampleNotDecodable(Any)
    case typeNotDecodable(Any.Type)
}

enum PolymorphicCodableTypeKeys: String, Codable, OpenOrderedCodingKey {
    case type
    public var sortOrderIndex: Int? { 0 }
    public var relativeIndex: Int { 0 }
}

extension Encoder {
    
    /// Add the "type" key to an encoded object.
    public func encodePolymorphic(_ obj: Any) throws {
        if let encodable = obj as? Encodable {
            // Use the `Encodable` protocol if supported. This can pass on the `userInfo` from the encoder.
            let polymorphicEncoder = PolymorphicEncoder(self, encodable: encodable)
            try encodable.encode(to: polymorphicEncoder)
            if let error = polymorphicEncoder.error {
                throw error
            }
        }
        else if let dictionaryRep = obj as? DictionaryRepresentable {
            // Otherwise, look to see if this is an older object that pre-dates Swift 2.0 `Codable`
            var dictionary = try dictionaryRep.jsonDictionary()
            if dictionary[PolymorphicCodableTypeKeys.type.rawValue] == nil {
                dictionary[PolymorphicCodableTypeKeys.type.rawValue] = typeName(for: obj)
            }
            let jsonElement = JsonElement.object(dictionary)
            try jsonElement.encode(to: self)
        }
        else {
            // If the object isn't serializable as a dictionary, then can't encode it.
            throw EncodingError.invalidValue(obj,
                .init(codingPath: self.codingPath, debugDescription: "Object `\(type(of: obj))` does not conform to the `Encodable` protocol"))
        }
    }
}

extension UnkeyedEncodingContainer {
    
    /// Add the "type" key to an array of encoded object.
    mutating public func encodePolymorphic(_ array: [Any]) throws {
        try array.forEach { obj in
            let nestedEncoder = self.superEncoder()
            try nestedEncoder.encodePolymorphic(obj)
        }
    }
}

fileprivate func typeName(for obj: Any) -> String {
    (obj as? PolymorphicTyped)?.typeName ?? "\(type(of: obj))"
}

/// Work-around for polymorphic encoding that includes a "type" in a dictionary where the "type"
/// field is not encoded by the object.
class PolymorphicEncoder : Encoder {
    let wrappedEncoder : Encoder
    let encodable: Encodable
    var error: Error?
    var typeAdded: Bool = false
    
    init(_ wrappedEncoder : Encoder, encodable: Encodable) {
        self.wrappedEncoder = wrappedEncoder
        self.encodable = encodable
    }
    
    var codingPath: [CodingKey] {
        wrappedEncoder.codingPath
    }
    
    var userInfo: [CodingUserInfoKey : Any] {
        wrappedEncoder.userInfo
    }
    
    func insertType() {
        guard !typeAdded else { return }
        typeAdded = true
        do {
            let typeName = typeName(for: encodable)
            var container = wrappedEncoder.container(keyedBy: PolymorphicCodableTypeKeys.self)
            try container.encode(typeName, forKey: .type)
        } catch {
            self.error = error
        }
    }
    
    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        insertType()
        return wrappedEncoder.container(keyedBy: type)
    }
    
    func unkeyedContainer() -> UnkeyedEncodingContainer {
        self.error = EncodingError.invalidValue(encodable,
            .init(codingPath: codingPath, debugDescription: "Cannot encode a polymorphic object to an array."))
        return wrappedEncoder.unkeyedContainer()
    }
    
    func singleValueContainer() -> SingleValueEncodingContainer {
        self.error = EncodingError.invalidValue(encodable,
            .init(codingPath: codingPath, debugDescription: "Cannot encode a polymorphic object to a single value container."))
        return wrappedEncoder.singleValueContainer()
    }
}

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

