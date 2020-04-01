//
//  AnyCodingKey.swift
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


/// `CodingKey` for converting a decoding container to a dictionary where any key in the
/// dictionary is accessible.
public struct AnyCodingKey: CodingKey {
    public let stringValue: String
    public let intValue: Int?
    
    public init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }
    
    public init?(intValue: Int) {
        self.intValue = intValue
        self.stringValue = "\(intValue)"
    }
}

/// Wrapper for any codable array.
public struct AnyCodableArray : Codable, Equatable, Hashable {
    let array : [JsonSerializable]
    
    public init(_ array : [JsonSerializable]) {
        self.array = array
    }
    
    public init(from decoder: Decoder) throws {
        var genericContainer = try decoder.unkeyedContainer()
        self.array = try genericContainer._decode(Array<JsonSerializable>.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        try (self.array as NSArray).encode(to: encoder)
    }
    
    public static func == (lhs: AnyCodableArray, rhs: AnyCodableArray) -> Bool {
        return (lhs.array as NSArray).isEqual(to: rhs.array)
    }
    
    public func hash(into hasher: inout Hasher) {
        (array as NSArray).hash(into: &hasher)
    }
}

/// Wrapper for any codable dictionary.
public struct AnyCodableDictionary : Codable, Equatable, Hashable {
    public let dictionary : [String : JsonSerializable]
    
    public init(_ dictionary : [String : JsonSerializable]) {
        self.dictionary = dictionary
    }
    
    public init(from decoder: Decoder) throws {
        let genericContainer = try decoder.container(keyedBy: AnyCodingKey.self)
        self.dictionary = try genericContainer._decode(Dictionary<String, JsonSerializable>.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        try (self.dictionary as NSDictionary).encode(to: encoder)
    }
    
    public static func == (lhs: AnyCodableDictionary, rhs: AnyCodableDictionary) -> Bool {
        return (lhs.dictionary as NSDictionary).isEqual(to: rhs.dictionary)
    }
    
    public func hash(into hasher: inout Hasher) {
        (dictionary as NSDictionary).hash(into: &hasher)
    }
}

/// Extension of the keyed decoding container for decoding to any dictionary. These methods are defined internally
/// to avoid possible namespace clashes.
extension KeyedDecodingContainer {
    
    /// Decode this container as a `Dictionary<String, Any>`.
    fileprivate func _decode(_ type: Dictionary<String, JsonSerializable>.Type) throws -> Dictionary<String, JsonSerializable> {
        var dictionary = Dictionary<String, JsonSerializable>()
        
        for key in allKeys {
            if let boolValue = try? decode(Bool.self, forKey: key) {
                dictionary[key.stringValue] = boolValue
            }
            else if let intValue = try? decode(Int.self, forKey: key) {
                dictionary[key.stringValue] = intValue
            }
            else if let stringValue = try? decode(String.self, forKey: key) {
                dictionary[key.stringValue] = stringValue
            }
            else if let doubleValue = try? decode(Double.self, forKey: key) {
                dictionary[key.stringValue] = doubleValue
            }
            else if let nestedDictionary = try? decode(AnyCodableDictionary.self, forKey: key) {
                dictionary[key.stringValue] = nestedDictionary.dictionary
            }
            else if let nestedArray = try? decode(AnyCodableArray.self, forKey: key) {
                dictionary[key.stringValue] = nestedArray.array
            }
        }
        return dictionary
    }
}

/// Extension of the unkeyed decoding container for decoding to any array. These methods are defined internally
/// to avoid possible namespace clashes.
extension UnkeyedDecodingContainer {
    
    /// For the elements in the unkeyed contain, decode all the elements.
    mutating fileprivate func _decode(_ type: Array<JsonSerializable>.Type) throws -> Array<JsonSerializable> {
        var array: [JsonSerializable] = []
        while isAtEnd == false {
            if let value = try? decode(Bool.self) {
                array.append(value)
            } else if let value = try? decode(Int.self) {
                array.append(value)
            } else if let value = try? decode(Double.self) {
                array.append(value)
            } else if let value = try? decode(String.self) {
                array.append(value)
            } else if let nestedArray = try? decode(AnyCodableArray.self) {
                array.append(nestedArray.array)
            } else {
                let nestedDictionary = try decode(AnyCodableDictionary.self)
                array.append(nestedDictionary.dictionary)
            }
        }
        return array
    }
}

extension FactoryEncoder {
    
    /// Serialize a dictionary. This is a work around for not being able to
    /// directly encode a generic dictionary.
    public func rsd_encode(_ value: Dictionary<String, Any>) throws -> Data {
        let dictionary = value._mapKeys { "\($0)" }
        let anyDictionary = AnyCodableDictionary(dictionary.jsonDictionary())
        let data = try self.encode(anyDictionary)
        return data
    }
    
    /// Serialize an array. This is a work around for not being able to
    /// directly encode a generic dictionary.
    public func rsd_encode(_ value: Array<Any>) throws -> Data {
        let anyArray = AnyCodableArray(value.jsonArray())
        let data = try self.encode(anyArray)
        return data
    }
}

extension Dictionary {
    
    /// Use this dictionary to decode the given object type.
    public func rsd_decode<T>(_ type: T.Type, resourceInfo: ResourceInfo? = nil) throws -> T where T : Decodable {
        let decoder = SerializationFactory.shared.createJSONDecoder(resourceInfo: resourceInfo)
        let jsonData = try JSONSerialization.data(withJSONObject: self, options: [])
        let decodable = try decoder.decode(type, from: jsonData)
        return decodable
    }
    
    /// Returns a `Dictionary` containing the results of transforming the keys
    /// over `self` where the returned values are the mapped keys.
    /// - parameter transform: The function used to transform the input keys into the output key
    /// - returns: A dictionary of key/value pairs.
    internal func _mapKeys<T: Hashable>(_ transform: (Key) -> T) -> [T: Value] {
        var result: [T: Value] = [:]
        for (key, value) in self {
            let transformedKey = transform(key)
            result[transformedKey] = value
        }
        return result
    }
}

extension Array {
    
    /// Use this array to decode an array of objects of the given type.
    public func rsd_decode<T>(_ type: Array<T>.Type, resourceInfo: ResourceInfo? = nil) throws -> Array<T> where T : Decodable {
        let decoder = SerializationFactory.shared.createJSONDecoder(resourceInfo: resourceInfo)
        let jsonData = try JSONSerialization.data(withJSONObject: self, options: [])
        let decodable = try decoder.decode(type, from: jsonData)
        return decodable
    }
}

extension Encodable {
    
    /// Return the dictionary representation for this object.
    func jsonEncodedDictionary() throws -> [String : JsonSerializable] {
        let data = try SerializationFactory.shared.createJSONEncoder().encode(self)
        let json = try JSONSerialization.jsonObject(with: data, options: [])
        guard let dictionary = json as? NSDictionary else {
            let context = EncodingError.Context(codingPath: [], debugDescription: "Failed to encode the object into a dictionary.")
            throw EncodingError.invalidValue(json, context)
        }
        return dictionary.jsonDictionary()
    }
}
