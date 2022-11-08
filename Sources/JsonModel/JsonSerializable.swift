//
//  JsonSerializable.swift
//

import Foundation

/// Casting for any a JSON type object. Elements may be any one of the JSON types
/// (NSNull, NSNumber, String, Array<JsonSerializable>, Dictionary<String : JsonSerializable>).
/// This is a subset of ``JsonValue`` so all these objects conform to the `Encodable` protocol.
///
/// - note: `NSArray` and `NSDictionary` do not implement this protocol b/c they cannot be extended
/// using a generic `where` clause. 
public protocol JsonSerializable {
    func encode(to encoder: Encoder) throws
}

extension NSNull : JsonSerializable {
}

extension String : JsonSerializable {
}

extension NSString : JsonSerializable {
}

extension Array : JsonSerializable where Element == JsonSerializable {
}

extension Dictionary : JsonSerializable where Key == String, Value == JsonSerializable {
}

extension NSNumber : JsonSerializable {
}

extension Int : JsonSerializable {
}

extension Int8 : JsonSerializable {
}

extension Int16 : JsonSerializable {
}

extension Int32 : JsonSerializable {
}

extension Int64 : JsonSerializable {
}

extension UInt : JsonSerializable {
}

extension UInt8 : JsonSerializable {
}

extension UInt16 : JsonSerializable {
}

extension UInt32 : JsonSerializable {
}

extension UInt64 : JsonSerializable {
}

extension Bool : JsonSerializable {
}

extension Double : JsonSerializable {
}

extension Float : JsonSerializable {
}
