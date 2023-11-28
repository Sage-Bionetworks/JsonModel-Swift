//
//  IdentifiableInterfaceSerializer.swift
//
//

import Foundation

/// Convenience implementation for a serializer that includes a required `identifier` key.
@available(*, deprecated, message: "Use `GenericPolymorphicSerializer` instead.")
open class IdentifiableInterfaceSerializer : AbstractPolymorphicSerializer {
    private enum InterfaceKeys : String, OpenOrderedCodingKey {
        case identifier
        var sortOrderIndex: Int? { 0 }
        var relativeIndex: Int { 1 }
    }
    
    open override class func codingKeys() -> [CodingKey] {
        var keys = super.codingKeys()
        keys.append(InterfaceKeys.identifier)
        return keys
    }
    
    open override class func documentProperty(for codingKey: CodingKey) throws -> DocumentProperty {
        guard let key = codingKey as? InterfaceKeys else {
            return try super.documentProperty(for: codingKey)
        }
        switch key {
        case .identifier:
            return .init(propertyType: .primitive(.string), propertyDescription:
                            "The identifier associated with the task, step, or asynchronous action.")
        }
    }
}

