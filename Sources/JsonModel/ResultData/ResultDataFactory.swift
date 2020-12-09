//
//  ResultDataFactory.swift
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

/// `ResultDataFactory` is a subclass of the `SerializationFactory` that registers a serializer
/// for `JsonResultData` objects that can be used to deserialize the results.
open class ResultDataFactory : SerializationFactory {
    
    public let resultSerializer = ResultDataSerializer()
    
    public required init() {
        super.init()
        self.registerSerializer(resultSerializer)
    }
}

/// `SerializableResultData` is the base implementation for `ResultData` that is serialized using
/// the `Codable` protocol and the polymorphic serialization defined by this framework.
///
public protocol SerializableResultData : ResultData, PolymorphicRepresentable, Encodable {
    var serializableResultType: SerializableResultType { get }
}

extension SerializableResultData {
    public var typeName: String { serializableResultType.stringValue }
    
    public func jsonDictionary() throws -> [String : JsonSerializable] {
        try jsonEncodedDictionary()
    }
}

/// `SerializableResultType` is an extendable string enum used by the `SerializationFactory` to
/// create the appropriate result type.
public struct SerializableResultType : TypeRepresentable, Codable, Hashable {
    
    public let rawValue: String
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    /// Defaults to creating a `JsonElementResultObject`.
    public static let jsonValue: SerializableResultType = "jsonValue"

    /// Defaults to creating a `CollectionResultObject`.
    public static let collection: SerializableResultType = "collection"

    /// Defaults to creating a `FileResultObject`.
    public static let file: SerializableResultType = "file"

    /// Defaults to creating a `ErrorResultObject`.
    public static let error: SerializableResultType = "error"
    
    /// List of all the standard types.
    public static func allStandardTypes() -> [SerializableResultType] {
        [.jsonValue, .collection, .file, .error]
    }
}

extension SerializableResultType : ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }
}

extension SerializableResultType : DocumentableStringLiteral {
    public static func examples() -> [String] {
        return allStandardTypes().map{ $0.rawValue }
    }
}

public final class ResultDataSerializer : IdentifiableInterfaceSerializer, PolymorphicSerializer {
    public var documentDescription: String? {
        """
        `JsonResultData` is the base implementation for `ResultData` that is serialized using
        the `Codable` protocol and the polymorphic serialization defined by this framework.
        """.replacingOccurrences(of: "\n", with: " ").replacingOccurrences(of: "  ", with: "\n")
    }
    
    override init() {
        self.examples = [
            JsonElementResultObject.examples().first!,
            CollectionResultObject.examples().first!,
            ErrorResultObject.examples().first!,
            FileResultObject.examples().first!,
        ]
    }
    
    public private(set) var examples: [ResultData]
    
    public override class func typeDocumentProperty() -> DocumentProperty {
        .init(propertyType: .reference(SerializableResultType.documentableType()))
    }
    
    public func add(_ example: SerializableResultData) {
        examples.removeAll(where: { $0.typeName == example.typeName })
        examples.append(example)
    }
    
    /// Insert the given examples into the example array, replacing any existing examples with the
    /// same `typeName` as one of the new examples.
    public func add(contentsOf newExamples: [SerializableResultData]) {
        let newNames = newExamples.map { $0.typeName }
        self.examples.removeAll(where: { newNames.contains($0.typeName) })
        self.examples.append(contentsOf: newExamples)
    }
}
