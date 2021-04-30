//
//  PolymorphicSerializer.swift
//  
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
public protocol GenericSerializer : AnyObject, DocumentableInterface {
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
public protocol PolymorphicSerializer : GenericSerializer {
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
    public enum TypeKeys: String, CodingKey, CaseIterable, Codable {
        case type
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
        TypeKeys.allCases
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

enum PolymorphicSerializerError : Error {
    case typeKeyNotFound
    case exampleNotFound(String)
}

