// Created 11/7/23
// swift-tools-version:5.0

import Foundation

public protocol TypeRepresentable : Hashable, RawRepresentable, ExpressibleByStringLiteral {
    var stringValue: String { get }
}

extension RawRepresentable where Self.RawValue == String {
    public var stringValue: String { return rawValue }
}

public protocol StringEnumSet : Hashable, RawRepresentable, CaseIterable where RawValue == String {
}

extension StringEnumSet {
    public static func allValues() -> [String] {
        return self.allCases.map { $0.rawValue }
    }
    
    public var indexPosition: Int {
        type(of: self).allValues().firstIndex(of: self.stringValue)!
    }
    
    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.indexPosition < rhs.indexPosition
    }
}

/// Coding keys that conform to this protocol include a sort order index.
public protocol OrderedCodingKey : CodingKey {
    /// The sort index of this key when encoding.
    var sortOrderIndex: Int? { get }
}

/// An ordered enum relies upon using an enum that is `CaseIterable` to define the index position
/// within the set.
public protocol OrderedEnumCodingKey : OrderedCodingKey, StringEnumSet {
}

extension OrderedEnumCodingKey {
    public var sortOrderIndex: Int? { indexPosition }
}

/// Open ordered coding keys are used for classes that are open to define indexes within the
/// encoding that are relative to the coding keys of the parent or child. This allows coding keys
/// to be sorted where the keys are *not* all defined within the same class.
public protocol OpenOrderedCodingKey : OrderedCodingKey {
    var relativeIndex: Int { get }
}
