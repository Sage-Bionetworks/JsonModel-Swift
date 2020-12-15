//
//  CollectionResultObject.swift
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

/// `CollectionResultObject` is used to include multiple results associated with a single action.
public final class CollectionResultObject : SerializableResultData {
    private enum CodingKeys : String, CodingKey, CaseIterable {
        case serializableResultType="type", identifier, startDate, endDate, children="inputResults"
    }
    public private(set) var serializableResultType: SerializableResultType = .collection
    
    public let identifier: String
    public var startDate: Date
    public var endDate: Date
    
    /// The list of input results associated with this step. These are generally assumed to be answers to
    /// field inputs, but they are not required to implement the `RSDAnswerResult` protocol.
    public var children: [ResultData]
    
    public init(identifier: String) {
        self.identifier = identifier
        self.startDate = Date()
        self.endDate = Date()
        self.children = []
    }
    
    /// Initialize from a `Decoder`. This decoding method will use the `RSDFactory` instance associated
    /// with the decoder to decode the `inputResults`.
    ///
    /// - parameter decoder: The decoder to use to decode this instance.
    /// - throws: `DecodingError`
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.identifier = try container.decode(String.self, forKey: .identifier)
        self.startDate = try container.decodeIfPresent(Date.self, forKey: .startDate) ?? Date()
        self.endDate = try container.decodeIfPresent(Date.self, forKey: .endDate) ?? Date()
        
        let resultsContainer = try container.nestedUnkeyedContainer(forKey: .children)
        self.children = try decoder.serializationFactory.decodePolymorphicArray(ResultData.self, from: resultsContainer)
    }
    
    /// Encode the result to the given encoder.
    /// - parameter encoder: The encoder to use to encode this instance.
    /// - throws: `EncodingError`
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(serializableResultType, forKey: .serializableResultType)
        try container.encode(identifier, forKey: .identifier)
        try container.encode(startDate, forKey: .startDate)
        try container.encode(endDate, forKey: .endDate)
        
        var nestedContainer = container.nestedUnkeyedContainer(forKey: .children)
        try children.forEach { result in
            let nestedEncoder = nestedContainer.superEncoder()
            if let encodable = result as? Encodable {
                try encodable.encode(to: nestedEncoder)
            }
            else {
                let json = try result.jsonDictionary()
                let element: JsonElement = .object(json)
                try element.encode(to: nestedEncoder)
            }
        }
    }
}

extension CollectionResultObject : DocumentableStruct {
    public static func codingKeys() -> [CodingKey] {
        return CodingKeys.allCases
    }
    
    public static func isRequired(_ codingKey: CodingKey) -> Bool {
        true
    }
    
    public static func documentProperty(for codingKey: CodingKey) throws -> DocumentProperty {
        guard let key = codingKey as? CodingKeys else {
            throw DocumentableError.invalidCodingKey(codingKey, "\(codingKey) is not recognized for this class")
        }
        switch key {
        case .serializableResultType:
            return .init(constValue: SerializableResultType.collection)
        case .identifier:
            return .init(propertyType: .primitive(.string))
        case .startDate, .endDate:
            return .init(propertyType: .format(.dateTime))
        case .children:
            return .init(propertyType: .interfaceArray("\(ResultData.self)"))
        }
    }
    
    public static func examples() -> [CollectionResultObject] {
        let result = CollectionResultObject(identifier: "answers")
        result.startDate = ISO8601TimestampFormatter.date(from: "2017-10-16T22:28:09.000-07:00")!
        result.endDate = result.startDate.addingTimeInterval(5 * 60)
        result.children = JsonElementResultObject.examples()
        return [result]
    }
}
