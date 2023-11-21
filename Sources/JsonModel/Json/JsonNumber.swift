//
//  JsonNumber.swift
//

import Foundation

/// `JsonNumber` implements converting a Swift number to an Objective-C `NSNumber`.
public protocol JsonNumber : Codable {
    
    /// Return an NSNumber for use in json encoding
    func jsonNumber() -> NSNumber?
}

extension Bool : JsonNumber {
    public func jsonNumber() -> NSNumber? {
        return self as NSNumber
    }
}

extension Int : JsonNumber {
    public func jsonNumber() -> NSNumber? {
        return NSNumber(value: self)
    }
}

extension Int8 : JsonNumber {
    public func jsonNumber() -> NSNumber? {
        return NSNumber(value: self)
    }
}

extension Int16 : JsonNumber {
    public func jsonNumber() -> NSNumber? {
        return NSNumber(value: self)
    }
}

extension Int32 : JsonNumber {
    public func jsonNumber() -> NSNumber? {
        return NSNumber(value: self)
    }
}

extension Int64 : JsonNumber {
    public func jsonNumber() -> NSNumber? {
        return NSNumber(value: self)
    }
}

extension UInt : JsonNumber {
    public func jsonNumber() -> NSNumber? {
        return NSNumber(value: self)
    }
}

extension UInt8 : JsonNumber {
    public func jsonNumber() -> NSNumber? {
        return NSNumber(value: self)
    }
}

extension UInt16 : JsonNumber {
    public func jsonNumber() -> NSNumber? {
        return NSNumber(value: self)
    }
}

extension UInt32 : JsonNumber {
    public func jsonNumber() -> NSNumber? {
        return NSNumber(value: self)
    }
}

extension UInt64 : JsonNumber {
    public func jsonNumber() -> NSNumber? {
        return NSNumber(value: self)
    }
}

extension Double : JsonNumber {
    public func jsonNumber() -> NSNumber? {
        return NSNumber(value: self)
    }
}

extension Float : JsonNumber {
    public func jsonNumber() -> NSNumber? {
        return NSNumber(value: self)
    }
}
