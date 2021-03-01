//
//  Encodable+Utilies.swift
//  
//
//  Copyright © 2017-2020 Sage Bionetworks. All rights reserved.
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

extension Encodable {
    
    /// Return the `JsonElement` for this object using the serialization strategy for numbers and
    /// dates defined by `SerializationFactory.defaultFactory`.
    public func jsonElement(using factory: SerializationFactory = SerializationFactory.defaultFactory) throws -> JsonElement {
        let arr = [self]
        let data = try factory.createJSONEncoder().encode(arr)
        let json = try factory.createJSONDecoder().decode([JsonElement].self, from: data)
        return json.first!
    }
    
    /// Return the dictionary representation for this object.
    public func jsonEncodedDictionary(using factory: SerializationFactory = SerializationFactory.defaultFactory) throws -> [String : JsonSerializable] {
        let json = try self.jsonElement(using: factory)
        guard case .object(let dictionary) = json else {
            let context = EncodingError.Context(codingPath: [], debugDescription: "Failed to encode the object into a dictionary.")
            throw EncodingError.invalidValue(json, context)
        }
        return dictionary
    }
    
    /// Returns JSON-encoded data created by encoding this object.
    public func jsonEncodedData(using factory: SerializationFactory = SerializationFactory.defaultFactory) throws -> Data {
        let jsonEncoder = factory.createJSONEncoder()
        return try self.encodeObject(to: jsonEncoder)
    }
    
    /// Encode the object using the factory encoder.
    fileprivate func encodeObject(to encoder: FactoryEncoder) throws -> Data {
        let wrapper = _EncodableWrapper(encodable: self)
        return try encoder.encode(wrapper)
    }
}

/// The wrapper is required b/c `JSONEncoder` does not implement the `Encoder` protocol.
/// Instead, it uses a private wrapper to box the encoded object.
fileprivate struct _EncodableWrapper: Encodable {
    let encodable: Encodable
    func encode(to encoder: Encoder) throws {
        try encodable.encode(to: encoder)
    }
}
