//
//  OrderedJSONEncoder.swift
//  
//  Copyright © 2022 Sage Bionetworks. All rights reserved.
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

public protocol OrderedCodingKey : CodingKey {
    var orderIndex: Int { get }
}

public protocol OrderedEnumCodingKey : OrderedCodingKey, StringEnumSet {
}

extension OrderedEnumCodingKey {
    public var orderIndex: Int {
        type(of: self).allValues().firstIndex(of: self.stringValue)!
    }
}

/// This is a subclass of `JSONEncoder` that encodes json using the indexed order provided by
/// `Encodable` objects that are encoded using `CodingKey` keys that implement the
/// `OrderedCodingKey` protocol.
open class OrderedJSONEncoder : JSONEncoder {
    
    public override init() {
        self._keyEncodingStrategy = .custom({ codingPath in
            return IndexedCodingKey(key: codingPath.last!) ?? codingPath.last!
        })
        super.init()
    }
    
    /// Should the encoded data be sorted to order the keys for coding keys that implement the `OrderedCodingKey` protocol?
    public var shouldOrderKeys: Bool = true
    
    override open var keyEncodingStrategy: JSONEncoder.KeyEncodingStrategy {
        get { shouldOrderKeys ? _keyEncodingStrategy : super.keyEncodingStrategy }
        set {
            super.keyEncodingStrategy = newValue
            shouldOrderKeys = false
        }
    }
    private var _keyEncodingStrategy: JSONEncoder.KeyEncodingStrategy
    
    override open var outputFormatting: JSONEncoder.OutputFormatting {
        get { _outputFormatting }
        set { _outputFormatting.formUnion(newValue) }
    }
    private var _outputFormatting: JSONEncoder.OutputFormatting = [.prettyPrinted, .sortedKeys]
    
    open override func encode<T>(_ value: T) throws -> Data where T : Encodable {
        let orderedData = try super.encode(value)
        guard let json = String(data: orderedData, encoding: .utf8)
        else {
            return orderedData
        }
        // Look for keys where the order was added to the key value and remove them.
        let replaceStr = "\\\"\\d*\(IndexedCodingKey.separator)"
        let searchStr = "^\\s*\(replaceStr).*\\\"\\s\\:"
        let searchRegex = try! NSRegularExpression(pattern: searchStr, options: [.anchorsMatchLines])
        let matches = searchRegex.matches(in: json, options: [], range: NSRange(location: 0, length: json.count))
        var replacementJson = json
        let replaceRegex = try! NSRegularExpression(pattern: replaceStr, options:[])
        matches.reversed().forEach { match in
            replacementJson = replaceRegex.stringByReplacingMatches(in: replacementJson,
                                                                    options: [],
                                                                    range: match.range,
                                                                    withTemplate: "\"")
        }
        return replacementJson.data(using: .utf8) ?? orderedData
    }
    
    fileprivate struct IndexedCodingKey : CodingKey {
        static let separator: Character = "ह"
        
        var stringValue: String
        var intValue: Int?
        var keyValue: String
        
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
            guard let orderedKey = key as? OrderedCodingKey
            else {
                return nil
            }
            self.intValue = orderedKey.orderIndex
            self.keyValue = key.stringValue
            self.stringValue = "\(orderedKey.orderIndex)\(IndexedCodingKey.separator)\(key.stringValue)"
        }
    }
}
