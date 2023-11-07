//
//  JsonElement.swift
//  
//

import Foundation

/// A `Codable` element that can be used to serialize any `JsonSerializable`.
public enum JsonElement : Codable {
    case string(String)
    case integer(Int)
    case number(JsonNumber)
    case boolean(Bool)
    case null
    case array([JsonSerializable])
    case object([String : JsonSerializable])
    
    public var jsonType: JsonType {
        switch self {
        case .null:
            return .null
        case .boolean(_):
            return .boolean
        case .string(_):
            return .string
        case .integer(_):
            return .integer
        case .number(_):
            return .number
        case .array(_):
            return .array
        case .object(_):
            return .object
        }
    }
    
    public init(_ jsonValue: JsonValue?) {
        let obj = jsonValue?.jsonObject()
        if obj == nil || obj is NSNull {
            self = .null
        }
        else if let value = obj as? String {
            self = .string(value)
        }
        else if let value = obj as? Bool {
            self = .boolean(value)
        }
        else if obj is IntegerNumber, let value = obj as? NSNumber {
            self = .integer(value.intValue)
        }
        else if let value = obj as? JsonNumber {
            self = .number(value)
        }
        else if let num = obj as? NSNumber {
            self = .number(num.doubleValue)
        }
        else if let value = obj as? [JsonSerializable] {
            self = .array(value)
        }
        else if let value = obj as? [String : JsonSerializable] {
            self = .object(value)
        }
        else {
            fatalError("Unsupported cast of \(String(describing: obj)). Cannot serialize this object.")
        }
    }
    
    public init(from decoder: Decoder) throws {
        if let _ = try? decoder.container(keyedBy: AnyCodingKey.self) {
            let value = try AnyCodableDictionary(from: decoder)
            self = .object(value.dictionary)
        }
        else if let _ = try? decoder.unkeyedContainer() {
            let value = try AnyCodableArray(from: decoder)
            self = .array(value.array)
        }
        else {
            let container = try decoder.singleValueContainer()
            if container.decodeNil() {
                self = .null
            }
            else if let value = try? container.decode(Bool.self) {
                self = .boolean(value)
            }
            else if let value = try? container.decode(Int.self) {
                self = .integer(value)
            }
            else if let value = try? container.decode(Double.self) {
                self = .number(value)
            }
            else {
                let value = try container.decode(String.self)
                self = .string(value)
            }
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        switch self {
        case .null:
            try NSNull().encode(to: encoder)
        case .boolean(let value):
            try value.encode(to: encoder)
        case .string(let value):
            try value.encode(to: encoder)
        case .integer(let value):
            try value.encode(to: encoder)
        case .number(let value):
            try value.encode(to: encoder)
        case .array(let value):
            try AnyCodableArray(value).encode(to: encoder)
        case .object(let value):
            try AnyCodableDictionary(value).encode(to: encoder)
        }
    }
}

extension JsonElement : Hashable {
    
    public static func == (lhs: JsonElement, rhs: JsonElement) -> Bool {
        switch lhs {
        case .null:
            if case .null = rhs { return true } else { return false }
        case .boolean(let lv):
            if case .boolean(let rv) = rhs { return lv == rv } else { return false }
        case .string(let lv):
            if case .string(let rv) = rhs { return lv == rv } else { return false }
        case .array(let lv):
            if case .array(let rv) = rhs { return (lv as NSArray).isEqual(to: rv) } else { return false }
        case .object(let lv):
            if case .object(let rv) = rhs { return (lv as NSDictionary).isEqual(to: rv) } else { return false }
        default:
            return equal(lhs: lhs, rhs: rhs)
        }
    }
    
    public static func == (lhs: JsonElement, rhs: JsonNumber) -> Bool {
        switch lhs {
        case .integer(let lv):
            return lv.jsonNumber() == rhs.jsonNumber()
        case .number(let lv):
            return lv.jsonNumber() == rhs.jsonNumber()
        default:
            return false
        }
    }
    
    public static func == (lhs: JsonNumber, rhs: JsonElement) -> Bool {
        rhs == lhs
    }
    
    public func hash(into hasher: inout Hasher) {
        jsonType.hash(into: &hasher)
        switch self {
        case .null:
            break
        case .boolean(let value):
            value.hash(into: &hasher)
        case .string(let value):
            value.hash(into: &hasher)
        case .integer(let value):
            value.hash(into: &hasher)
        case .number(let value):
            value.jsonNumber()?.hash(into: &hasher)
        case .array(let value):
            (value as NSArray).hash(into: &hasher)
        case .object(let value):
            (value as NSDictionary).hash(into: &hasher)
        }
    }
}

extension JsonElement : Comparable {
    public static func < (lhs: JsonElement, rhs: JsonElement) -> Bool {
        switch lhs {
        case .string(let lv):
            if case .string(let rv) = rhs {
                return lv < rv
            } else {
                return false
            }
        default:
            return lessThan(lhs: lhs, rhs: rhs)
        }
    }
}

extension JsonElement : JsonNumber {
    public func jsonNumber() -> NSNumber? {
        switch self {
        case .integer(let value):
            return value.jsonNumber()
        case .number(let value):
            return value.jsonNumber()
        case .string(let value):
            return NumberFormatter().number(from: value)
        default:
            return nil
        }
    }
}

fileprivate func lessThan(lhs: JsonNumber, rhs: JsonNumber) -> Bool {
    guard let lv = lhs.jsonNumber()?.doubleValue,
          let rv = rhs.jsonNumber()?.doubleValue
    else {
        return false
    }
    return lv < rv
}

fileprivate func equal(lhs: JsonNumber, rhs: JsonNumber) -> Bool {
    guard let lv = lhs.jsonNumber(),
          let rv = rhs.jsonNumber()
    else {
        return false
    }
    return lv == rv
}

extension JsonElement : JsonValue {
    public func jsonObject() -> JsonSerializable {
        switch self {
        case .null:
            return NSNull()
        case .boolean(let value):
            return value
        case .string(let value):
            return value
        case .integer(let value):
            return value
        case .number(let value):
            return value.jsonNumber() ?? NSNull()
        case .array(let value):
            return value
        case .object(let value):
            return value
        }
    }
}

protocol JsonElementFormatter {
    func jsonElement(from string: String) -> JsonElement?
    func string(from jsonElement: JsonElement) -> String?
}

extension NumberFormatter : JsonElementFormatter {
    
    public var isIntegerStyle: Bool {
        get { self.maximumFractionDigits == 0 }
    }
    
    public func jsonElement(from string: String) -> JsonElement? {
        self.number(from: string).map { self.isIntegerStyle ? .integer($0.intValue) : .number($0.doubleValue) }
    }
    
    public func string(from jsonElement: JsonElement) -> String? {
        switch jsonElement {
        case .integer(let value):
            return self.string(from: value as NSNumber)
        case .number(let value):
            return value.jsonNumber().map { self.string(from: $0) } ?? nil
        case .string(let value):
            return value
        default:
            return nil
        }
    }
}

protocol IntegerNumber {
}

extension Int : IntegerNumber {
}

extension Int16 : IntegerNumber {
}

extension Int32 : IntegerNumber {
}

extension Int64 : IntegerNumber {
}

extension UInt : IntegerNumber {
}

extension UInt16 : IntegerNumber {
}

extension UInt32 : IntegerNumber {
}

extension UInt64 : IntegerNumber {
}

