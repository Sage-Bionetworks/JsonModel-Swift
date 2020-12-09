//
//  JsonValue.swift
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

/// Protocol for converting an object to a dictionary representation. This is included for
/// reverse-compatiblility to older implementations that are not Swift `Codable` and instead
/// use a dictionary representation. Additionally, this can be used to implement Kotlin-Native
/// serializable objects that do not conform to the Codable protocol.
public protocol DictionaryRepresentable {
    
    /// Return the dictionary representation for this object.
    func jsonDictionary() throws -> [String : JsonSerializable]
}

/// Protocol for converting objects to JSON serializable objects.
public protocol JsonValue {
    
    /// Return a JSON-type object. Elements may be any one of the JSON types.
    func jsonObject() -> JsonSerializable
    
    /// Encode the object.
    func encode(to encoder: Encoder) throws
}

extension NSString : JsonValue {
    public func jsonObject() -> JsonSerializable {
        return String(self)
    }
    
    public func encode(to encoder: Encoder) throws {
        try (self as String).encode(to: encoder)
    }
}

extension String : JsonValue {
    public func jsonObject() -> JsonSerializable {
        return String(self)
    }
}

extension NSNumber : JsonValue {
    public func jsonObject() -> JsonSerializable {
        return self.copy() as! NSNumber
    }
}

extension Int : JsonValue {
    public func jsonObject() -> JsonSerializable {
        return self
    }
}

extension Int8 : JsonValue {
    public func jsonObject() -> JsonSerializable {
        return self
    }
}

extension Int16 : JsonValue {
    public func jsonObject() -> JsonSerializable {
        return self
    }
}

extension Int32 : JsonValue {
    public func jsonObject() -> JsonSerializable {
        return self
    }
}

extension Int64 : JsonValue {
    public func jsonObject() -> JsonSerializable {
        return self
    }
}

extension UInt : JsonValue {
    public func jsonObject() -> JsonSerializable {
        return self
    }
}

extension UInt8 : JsonValue {
    public func jsonObject() -> JsonSerializable {
        return self
    }
}

extension UInt16 : JsonValue {
    public func jsonObject() -> JsonSerializable {
        return self
    }
}

extension UInt32 : JsonValue {
    public func jsonObject() -> JsonSerializable {
        return self
    }
}

extension UInt64 : JsonValue {
    public func jsonObject() -> JsonSerializable {
        return self
    }
}

extension Bool : JsonValue {
    public func jsonObject() -> JsonSerializable {
        return self
    }
}

extension Double : JsonValue {
    public func jsonObject() -> JsonSerializable {
        return self
    }
}

extension Float : JsonValue {
    public func jsonObject() -> JsonSerializable {
        return self
    }
}

extension NSNull : JsonValue {
    public func jsonObject() -> JsonSerializable {
        return self
    }
}

extension NSDate : JsonValue {
    public func jsonObject() -> JsonSerializable {
        return (self as Date).jsonObject()
    }
    
    public func encode(to encoder: Encoder) throws {
        try (self as Date).encode(to: encoder)
    }
}

extension Date : JsonValue {
    public func jsonObject() -> JsonSerializable {
        return SerializationFactory.defaultFactory.timestampFormatter.string(from: self)
    }
}

extension DateComponents : JsonValue {
    
    public func jsonObject() -> JsonSerializable {
        guard let date = self.date ?? Calendar(identifier: .iso8601).date(from: self) else { return NSNull() }
        return defaultFormatter().string(from: date)
    }
    
    public func defaultFormatter() -> DateFormatter {
        if ((year == nil) || (year == 0)) && ((month == nil) || (month == 0)) && ((day == nil) || (day == 0)) {
            return SerializationFactory.defaultFactory.timeOnlyFormatter
        }
        else if ((hour == nil) || (hour == 0)) && ((minute == nil) || (minute == 0)) {
            if let year = year, year > 0, let month = month, month > 0, let day = day, day > 0 {
                return SerializationFactory.defaultFactory.dateOnlyFormatter
            }
            
            // Build the format string if not all components are included
            var formatString = ""
            if let year = year, year > 0 {
                formatString = "yyyy"
            }
            if let month = month, month > 0 {
                if formatString.count > 0 {
                    formatString.append("-")
                }
                formatString.append("MM")
                if let day = day, day > 0 {
                    formatString.append("-")
                    formatString.append("dd")
                }
            }

            let formatter = DateFormatter()
            formatter.dateFormat = formatString
            return formatter
        }
        return SerializationFactory.defaultFactory.timestampFormatter
    }
}

extension NSDateComponents : JsonValue {
    public func jsonObject() -> JsonSerializable {
        return (self as DateComponents).jsonObject()
    }
    
    public func encode(to encoder: Encoder) throws {
        try (self as DateComponents).encode(to: encoder)
    }
}

extension Data : JsonValue {
    public func jsonObject() -> JsonSerializable {
        return self.base64EncodedString()
    }
}

extension NSData : JsonValue {
    public func jsonObject() -> JsonSerializable {
        return (self as Data).jsonObject()
    }
    
    public func encode(to encoder: Encoder) throws {
        try (self as Data).encode(to: encoder)
    }
}

extension NSUUID : JsonValue {
    public func jsonObject() -> JsonSerializable {
        return self.uuidString
    }
    
    public func encode(to encoder: Encoder) throws {
        try (self as UUID).encode(to: encoder)
    }
}

extension UUID : JsonValue {
    public func jsonObject() -> JsonSerializable {
        return self.uuidString
    }
}

extension NSURL : JsonValue {
    public func jsonObject() -> JsonSerializable {
        return self.absoluteString ?? NSNull()
    }
    
    public func encode(to encoder: Encoder) throws {
        try (self as URL).encode(to: encoder)
    }
}

extension URL : JsonValue {
    public func jsonObject() -> JsonSerializable {
        return self.absoluteString
    }
}

fileprivate func _convertToJSONValue(from object: Any) -> JsonSerializable {
    if let obj = object as? JsonValue {
        return obj.jsonObject()
    }
    else if let obj = object as? DictionaryRepresentable, let json = try? obj.jsonDictionary() {
        return json
    }
    else if let obj = object as? NSObjectProtocol {
        return obj.description
    }
    else {
        return NSNull()
    }
}

fileprivate func _encode(value: Any, to nestedEncoder:Encoder) throws {
    // Note: need to special-case encoding a Date, Data type, or NonConformingNumber since these
    // are not encoding correctly unless cast to a nested container that can handle
    // custom encoding strategies.
    if let date = value as? Date {
        var container = nestedEncoder.singleValueContainer()
        try container.encode(date)
    } else if let data = value as? Data {
        var container = nestedEncoder.singleValueContainer()
        try container.encode(data)
    } else if let nestedArray = value as? [JsonSerializable] {
        let encodable = AnyCodableArray(nestedArray)
        try encodable.encode(to: nestedEncoder)
    } else if let nestedDictionary = value as? Dictionary<String, JsonSerializable> {
        let encodable = AnyCodableDictionary(nestedDictionary)
        try encodable.encode(to: nestedEncoder)
    } else if let number = (value as? JsonNumber)?.jsonNumber() {
        var container = nestedEncoder.singleValueContainer()
        try container.encode(number)
    } else if let encodable = value as? JsonValue {
        try encodable.encode(to: nestedEncoder)
    } else if let encodable = value as? Encodable {
        try encodable.encode(to: nestedEncoder)
    } else {
        let context = EncodingError.Context(codingPath: nestedEncoder.codingPath, debugDescription: "Could not encode value \(value).")
        throw EncodingError.invalidValue(value, context)
    }
}

extension NSDictionary : JsonValue, Encodable {
    
    public func jsonDictionary() -> [String : JsonSerializable] {
        var dictionary : [String : JsonSerializable] = [:]
        for (key, value) in self {
            let strKey = "\(key)"
            dictionary[strKey] = _convertToJSONValue(from: value)
        }
        return dictionary
    }
    
    public func jsonObject() -> JsonSerializable {
        return jsonDictionary()
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: AnyCodingKey.self)
        for (key, value) in self {
            let strKey = "\(key)"
            let codingKey = AnyCodingKey(stringValue: strKey)!
            let nestedEncoder = container.superEncoder(forKey: codingKey)
            try _encode(value: value, to: nestedEncoder)
        }
    }
}

extension Dictionary : JsonValue {
    
    public func jsonDictionary() -> [String : JsonSerializable] {
        return (self as NSDictionary).jsonDictionary()
    }
    
    public func jsonObject() -> JsonSerializable {
        return (self as NSDictionary).jsonObject()
    }
}

extension Dictionary where Value : Any {
    
    public func encode(to encoder: Encoder) throws {
        try (self as NSDictionary).encode(to: encoder)
    }
}

extension NSArray : JsonValue {
    
    public func jsonArray() -> [JsonSerializable] {
        return self.map { _convertToJSONValue(from: $0) }
    }
    
    public func jsonObject() -> JsonSerializable {
        return jsonArray()
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        for value in self {
            let nestedEncoder = container.superEncoder()
            try _encode(value: value, to: nestedEncoder)
        }
    }
}

extension Array : JsonValue {
    
    public func jsonArray() -> [JsonSerializable] {
        return (self as NSArray).jsonArray()
    }
    
    public func jsonObject() -> JsonSerializable {
        return (self as NSArray).jsonObject()
    }
}

extension Array where Element : Any {
    
    public func encode(to encoder: Encoder) throws {
        try (self as NSArray).encode(to: encoder)
    }
}

extension Set : JsonValue {
    
    public func jsonObject() -> JsonSerializable {
        return Array(self).jsonObject()
    }
}

extension Set where Element : Any {
    
    public func encode(to encoder: Encoder) throws {
        try Array(self).encode(to: encoder)
    }
}

extension NSNull : Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encodeNil()
    }
}

extension NSNumber : Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if self === kCFBooleanTrue as NSNumber {
            try container.encode(true)
        } else if self === kCFBooleanFalse as NSNumber {
            try container.encode(false)
        } else if NSNumber(value: self.intValue) == self {
            try container.encode(self.intValue)
        } else {
            try container.encode(self.doubleValue)
        }
    }
}
