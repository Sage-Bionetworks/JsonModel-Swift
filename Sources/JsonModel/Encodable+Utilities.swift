//
//  Encodable+Utilies.swift
//  
//

import Foundation

extension Encodable {
    
    /// Return the `JsonElement` for this object using the serialization strategy for numbers and
    /// dates defined by `SerializationFactory.defaultFactory`.
    public func jsonElement(using factory: SerializationFactory = SerializationFactory.defaultFactory) throws -> JsonElement {
        let arr = [self]
        let data = try factory.createJSONEncoder().encode(arr)
        let json = try factory.createJSONDecoder().decode([JsonElement].self, from: data)
        return json.first!
    }
    
    /// Return the dictionary representation for this object.
    public func jsonEncodedDictionary(using factory: SerializationFactory = SerializationFactory.defaultFactory) throws -> [String : JsonSerializable] {
        let json = try self.jsonElement(using: factory)
        guard case .object(let dictionary) = json else {
            let context = EncodingError.Context(codingPath: [], debugDescription: "Failed to encode the object into a dictionary.")
            throw EncodingError.invalidValue(json, context)
        }
        return dictionary
    }
    
    /// Returns JSON-encoded data created by encoding this object.
    public func jsonEncodedData(using factory: SerializationFactory = SerializationFactory.defaultFactory) throws -> Data {
        let jsonEncoder = factory.createJSONEncoder()
        return try self.encodeObject(to: jsonEncoder)
    }
    
    /// Encode the object using the factory encoder.
    fileprivate func encodeObject(to encoder: FactoryEncoder) throws -> Data {
        let wrapper = _EncodableWrapper(encodable: self)
        return try encoder.encode(wrapper)
    }
}

/// The wrapper is required b/c `JSONEncoder` does not implement the `Encoder` protocol.
/// Instead, it uses a private wrapper to box the encoded object.
fileprivate struct _EncodableWrapper: Encodable {
    let encodable: Encodable
    func encode(to encoder: Encoder) throws {
        try encodable.encode(to: encoder)
    }
}
