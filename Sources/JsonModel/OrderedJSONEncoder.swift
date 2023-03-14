//
//  OrderedJSONEncoder.swift
//  

import Foundation

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

/// This is a subclass of `JSONEncoder` that encodes json using the indexed order provided by
/// `Encodable` objects that are encoded using `CodingKey` keys that implement the
/// `OrderedCodingKey` protocol.
open class OrderedJSONEncoder : JSONEncoder {
    
    /// Should the encoded data be sorted to order the keys for coding keys that implement the
    /// `OrderedCodingKey` protocol? By default, keys are *not* ordered so that encoding will
    /// run faster, but they can be if the protocol supports doing so.
    public var shouldOrderKeys: Bool = false {
        didSet {
            if shouldOrderKeys {
                self.keyEncodingStrategy = .custom({ codingPath in
                    return IndexedCodingKey(key: codingPath.last!) ?? codingPath.last!
                })
            }
            else {
                self.keyEncodingStrategy = .useDefaultKeys
            }
        }
    }
    
    override open var outputFormatting: JSONEncoder.OutputFormatting {
        get {
            shouldOrderKeys ? super.outputFormatting.union([.prettyPrinted, .sortedKeys]) : super.outputFormatting
        }
        set {
            super.outputFormatting = newValue
        }
    }
    
    open override func encode<T>(_ value: T) throws -> Data where T : Encodable {
        let orderedData = try super.encode(value)
        guard let json = String(data: orderedData, encoding: .utf8)
        else {
            return orderedData
        }
        // Look for keys where the order was added to the key value and remove them.
        let replaceStr = "\\d*\(IndexedCodingKey.separator)"
        let searchStr = "^\\s*\\\"\(replaceStr).*\\\"\\s\\:"
        let searchRegex = try! NSRegularExpression(pattern: searchStr, options: [.anchorsMatchLines])
        let matches = searchRegex.matches(in: json, options: [], range: NSRange(location: 0, length: json.count))
        let replaceRegex = try! NSRegularExpression(pattern: replaceStr, options:[])
        let replaceRanges = matches.compactMap {
            Range(replaceRegex.rangeOfFirstMatch(in: json, range: $0.range), in: json)
        }
        var replacementJson = json
        replaceRanges.reversed().forEach {
            replacementJson.removeSubrange($0)
        }
        return replacementJson.data(using: .utf8) ?? orderedData
    }
    
    struct IndexedCodingKey : CodingKey {
        static let separator: Character = "ह"
        static let multiplier: Int = 1000
        
        let stringValue: String
        let intValue: Int?
        let keyValue: String
        
        init?(stringValue: String) {
            let strings = stringValue.split(separator: IndexedCodingKey.separator)
            guard strings.count == 2, let index = Int(strings.first!) else {
                return nil
            }
            self.intValue = index
            self.keyValue = String(strings.last!)
            self.stringValue = stringValue
        }

        init?(intValue: Int) {
            return nil
        }
        
        init?(key: CodingKey) {
            guard let orderedKey = key as? OrderedCodingKey,
                  let sortOrderIndex = orderedKey.sortOrderIndex
            else {
                return nil
            }
            let relativeIndex = (key as? OpenOrderedCodingKey)?.relativeIndex ?? 0
            let index = sortOrderIndex + relativeIndex * IndexedCodingKey.multiplier
            self.intValue = index
            self.stringValue = "\(index)\(IndexedCodingKey.separator)\(key.stringValue)"
            self.keyValue = key.stringValue
        }
    }
}

