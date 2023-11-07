// Created 11/7/23
// swift-tools-version:5.0

import Foundation

/// An enum listing the json-types for serialization.
public enum JsonType : String, Codable, CaseIterable {
    case string, number, integer, boolean, null, array, object
    
    var isPrimitive: Bool {
        let primitiveTypes: [JsonType] = [.string, .number, .integer, .boolean, .null]
        return primitiveTypes.contains(self)
    }
}

extension JsonType : DocumentableStringEnum, StringEnumSet {
}
