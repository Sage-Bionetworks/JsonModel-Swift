// Created 3/13/23
// swift-tools-version:5.0

import Foundation

/// An explicitly defined protocol for a polymorphically-typed serializable value.
public protocol PolymorphicCodable : PolymorphicRepresentable, Encodable {
}

/// Wrap a ``PolymorphicCodable`` interface to allow automatic synthesis of a polymorphically-typed value.
///
/// This implementation was modified from an investigation of property wrappers originally created
/// by Aaron Rabara in January, 2023. - syoung 03/14/2023
///
/// There are several limitations to this implementation which are described below. Because of these
/// limitations, it is **highly recommended** that you thoroughly unit test your implementations
/// for the expected encoding and decoding of polymorphic objects.
///
/// The simpliest example is a non-null, read/write, required value without a default such as:
///
/// ```
/// struct SampleTest : Codable {
///     @PolymorphicValue var single: Sample
/// }
/// ```
///
/// - Limitation 1:
/// If the property is read-only, it must still be defined with a setter, though the setter can be
/// private.
///
/// ```
/// struct SampleTest : Codable {
///     @PolymorphicValue private(set) var single: Sample
/// }
/// ```
///
/// - Limitation 2:
/// This property wrapper will only auto-synthesize the `Codable` methods for a non-null value
/// without a default. Therefore, if you wish to define a default or nullable property, then
/// you must unwrap in your implementation.
///
/// ```
/// public struct SampleTest : Codable {
///     private enum CodingKeys : String, CodingKey {
///         case _nullable = "nullable", _defaultValue = "defaultValue"
///     }
///
///     public var nullable: Sample? {
///         get {
///             _nullable?.wrappedValue
///         }
///         set {
///             _nullable = newValue.map { .init(wrappedValue: $0) }
///         }
///     }
///     private let _nullable: PolymorphicValue<Sample>?
///
///     public var defaultValue: Sample! {
///         get {
///             _defaultValue?.wrappedValue ?? SampleA(value: 0)
///         }
///         set {
///             _defaultValue = newValue.map { .init(wrappedValue: $0) }
///         }
///     }
///     private let _defaultValue: PolymorphicValue<Sample>?
///
///     public init(nullable: Sample? = nil) {
///         self._nullable = nullable.map { .init(wrappedValue: $0) }
///     }
/// }
/// ```
///
/// - Limitation 3:
/// This property wrapper does not explicitly require conformance to the `Codable` or
/// `PolymorphicTyped` protocols (limitation of Swift Generics as of 03/14/2022), but will fail to
/// encode at runtime if the objects do *not* conform to these protocols. Finally, if you attempt
/// to decode with a ``SerializationFactory`` that does not have a registered serializer for the
/// given ``ProtocolValue``, then decoding will fail at runtime.
///
/// ```
///
/// // This struct will encode and decode properly.
/// struct SampleA : Sample, PolymorphicCodable {
///     public private(set) var type: SampleType = .a
///     public let value: Int
/// }
///
/// // This struct will fail to encode and decode because it does not match the required
/// // `Codable` protocols.
/// struct SampleThatFails : Sample {
///     public private(set) var type: SampleType = .fails
///     public let value: String
/// }
///
/// // The decoded object must use a factory to create the JSONDecoder that registers
/// // the serializer for the matching `ProtocolValue`.
/// class TestFactory : SerializationFactory {
///     let sampleSerializer = SampleSerializer()
///     required init() {
///         super.init()
///         self.registerSerializer(sampleSerializer)
///     }
/// }
/// ```
///
@propertyWrapper
public struct PolymorphicValue<ProtocolValue> : Codable {
    public var wrappedValue: ProtocolValue
    
    public init(wrappedValue: ProtocolValue, description: String? = nil) {
        self.wrappedValue = wrappedValue
    }
    
    public init(from decoder: Decoder) throws {
        self.wrappedValue = try decoder.serializationFactory.decodePolymorphicObject(ProtocolValue.self, from: decoder)
    }
    
    public func encode(to encoder: Encoder) throws {
        try encoder.encodePolymorphic(wrappedValue)
    }
}

/// Wrap a ``PolymorphicCodable`` interface to allow automatic synthesis of a polymorphically-typed array.
///
/// - Example:
/// ```
/// struct SampleTest : Codable {
///     @PolymorphicValue var array: [Sample]
/// }
/// ```
///
/// - See Also:
/// ``PolymorphicValue``. The same limitations on that implementation apply to this one.
///
@propertyWrapper
public struct PolymorphicArray<ProtocolValue> : Codable {
    public var wrappedValue: [ProtocolValue]
    
    public init(wrappedValue: [ProtocolValue], description: String? = nil) {
        self.wrappedValue = wrappedValue
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.unkeyedContainer()
        self.wrappedValue = try decoder.serializationFactory.decodePolymorphicArray(ProtocolValue.self, from: container)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try wrappedValue.forEach { obj in
            let nestedEncoder = container.superEncoder()
            try nestedEncoder.encodePolymorphic(obj)
        }
    }
}

fileprivate enum PolymorphicCodableTypeKeys: String, CodingKey {
    case type
}

extension Encoder {
    fileprivate func encodePolymorphic(_ obj: Any) throws {
        guard let encodable = obj as? Encodable else {
            throw EncodingError.invalidValue(obj,
                .init(codingPath: self.codingPath, debugDescription: "Object `\(type(of: obj))` does not conform to the `Encodable` protocol"))
        }
        let typeName = (obj as? PolymorphicTyped)?.typeName ?? "\(type(of: obj))"
        var container = self.container(keyedBy: PolymorphicCodableTypeKeys.self)
        try container.encode(typeName, forKey: .type)
        try encodable.encode(to: self)
    }
}
