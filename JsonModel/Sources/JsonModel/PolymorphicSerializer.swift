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
public protocol PolymorphicRepresentable : Decodable {
    var typeName: String { get }
}

/// The generic method for a decodable. This is a work-around for the limitations of Swift generics
/// where an instance of a class that has an associated type cannot be stored in a dictionary or
/// array.
public protocol GenericSerializer : class {
    var interfaceName : String { get }
    func decode(from decoder: Decoder) throws -> Any
    func documentableExamples() -> [DocumentableObject]
}

/// A serializer protocol for decoding serializable objects.
///
/// This serializer is designed to allow for decoding objects that use
/// [kotlinx.serialization](https://github.com/Kotlin/kotlinx.serialization) so it requires that
/// the "type" key is set as a special property in the JSON. While you *can* chance the default
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
    
    /// Find an example for the given `typeName` key.
    public func findExample(for typeName: String) -> ProtocolValue? {
        return examples.first { ($0 as? PolymorphicRepresentable)?.typeName == typeName }
    }
    
    public func decode(from decoder: Decoder) throws -> Any {
        let name = try typeName(from: decoder)
        guard let example = findExample(for: name) as? Decodable else {
            let context = DecodingError.Context(codingPath: decoder.codingPath,
                                                debugDescription: "Could not find an example for type \(name)")
            throw DecodingError.valueNotFound(ProtocolValue.self, context)
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
        return try container.decode(String.self, forKey: .type)
    }
}

