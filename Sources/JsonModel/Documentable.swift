//
//  Documentable.swift
//  
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

public protocol TypeRepresentable : Hashable, RawRepresentable, ExpressibleByStringLiteral {
    var stringValue: String { get }
}

extension TypeRepresentable {
    static var regularExpression: NSRegularExpression? {
        return try? NSRegularExpression(pattern: "^[A-Za-z][A-Za-z0-9]*$", options: [])
    }
}

extension RawRepresentable where Self.RawValue == String {
    public var stringValue: String { return rawValue }
}

/// A `Documentable` is used to create the `JsonSchema` for a collection of serializable objects.
/// It is generally assumed that the objects conform to `Decodable` and/or `Encodable` but neither
/// protocol is required
public protocol Documentable {
}

protocol DocumentableStringEnum : Documentable, Codable {
    /// The string value of the enum.
    var stringValue: String { get }
    
    /// An array of encodable objects to use as the set of examples for decoding this object.
    static func allValues() -> [String]
}

public protocol StringEnumSet : Hashable, RawRepresentable, CaseIterable where RawValue == String {
}

extension StringEnumSet {
    static func allValues() -> [String] {
        return self.allCases.map { $0.rawValue }
    }
}

public protocol DocumentableStringLiteral : Documentable, Codable {
    /// Not all of the string literals have a `rawValue` of a `String` but they should all be
    /// codable using a string value.
    var stringValue: String { get }
    
    /// A regular expression that can be used to limit the allowed string pattern for values.
    static var regularExpression: NSRegularExpression? { get }
    
    /// An array of encodable objects to use as the set of examples for decoding this object.
    static func examples() -> [String]
}

/// Used to build Json Schema definitions and property references.
public protocol DocumentableObject : Documentable {
    
    /// A list of `CodingKey` values for all the `Codable` properties on this object.
    static func codingKeys() -> [CodingKey]
    
    /// Can this class be subclassed?
    static func isOpen() -> Bool
    
    /// Is the coding key required?
    static func isRequired(_ codingKey: CodingKey) -> Bool
    
    /// Returns the property mapping for the
    static func documentProperty(for codingKey: CodingKey) throws -> DocumentProperty
    
    /// The example JSON for this object.
    static func jsonExamples() throws -> [[String : JsonSerializable]]
}

/// A light-weight wrapper
public struct DocumentProperty {

    let propertyType: PropertyType
    let constValue: String?
    let defaultValue: JsonElement?
    
    public enum PropertyType {
        case primitive(JsonType)
        case primitiveArray(JsonType)
        case reference(Documentable.Type)
        case referenceArray(Documentable.Type)
        case interface(String)
        case interfaceArray(String)
    }
    
    public init(propertyType: PropertyType) {
        self.propertyType = propertyType
        self.constValue = nil
        self.defaultValue = nil
    }
    
    public init(defaultValue: JsonElement) {
        self.propertyType = .primitive(defaultValue.jsonType)
        self.constValue = nil
        self.defaultValue = defaultValue
    }
    
    public init(constValue: DocumentableStringLiteral) {
        self.propertyType = .reference(type(of: constValue))
        self.constValue = constValue.stringValue
        self.defaultValue = nil
    }
}

/// Structs that implement the Codable protocol.
public protocol DocumentableStruct : DocumentableObject, Codable {
    static func examples() -> [Self]
}

extension DocumentableStruct {
    static func isOpen() -> Bool {
        return false
    }
    
    static func jsonExamples() throws -> [[String : JsonSerializable]] {
        return try examples().map { try $0.jsonEncodedDictionary() }
    }
}

/// Errors that can be thrown while building documentation.
public enum DocumentableError : Error {
    
    /// Not a valid coding key path for this object.
    case invalidCodingKey(CodingKey, String)
    
    /// The json schema could not be built b/c the mappings weren't set up correctly.
    case invalidMapping(String)
    
    /// The domain of the error.
    public static var errorDomain: String {
        return "DocumentableErrorDomain"
    }
    
    /// The error code within the given domain.
    public var errorCode: Int {
        switch(self) {
        case .invalidCodingKey(_, _):
            return -1
        case .invalidMapping(_):
            return -2
        }
    }
    
    /// The user-info dictionary.
    public var errorUserInfo: [String : Any] {
        let description: String
        switch(self) {
        case .invalidCodingKey(_, let str): description = str
        case .invalidMapping(let str): description = str
        }
        return ["NSDebugDescription": description]
    }
}

public class JsonDocumentBuilder {
    public let baseUrl: URL
    public let rootName: String
    
    private(set) var interfaces: [JsonSchemaReferenceId] = []
    private(set) var objects: [KlassPointer] = []
    
    public init(baseUrl: URL, rootName: String, factory: SerializationFactory) {
        self.baseUrl = baseUrl
        self.rootName = rootName
        factory.serializerMap.forEach { (interfaceName, serializer) in
            serializer.documentableExamples().forEach {
                addExample(example: $0, interfaceName: interfaceName)
            }
        }
    }
    
    public func buildSchema() throws -> JsonSchema {

        var allDefinitions: [JsonSchemaDefinition] = interfaces.compactMap {
            $0.isExternal ? nil : .object(JsonSchemaObject(id: $0, isOpen: true))
        }
        let objectDefs: [JsonSchemaDefinition] = try self.objects.map {
            try $0.buildDefinition(using: self)
        }
        allDefinitions.append(contentsOf: objectDefs)
        
        return JsonSchema(id: self.baseUrl.appendingPathComponent("\(self.rootName).json"),
                          description: "",
                          isOpen: true,
                          interfaces: nil,
                          definitions: allDefinitions,
                          properties: nil,
                          required: nil,
                          examples: nil)
    }
    
    private func addExample(example: Documentable, interfaceName: String? = nil) {
        recursiveAddObject(documentableType: type(of: example), interfaceName: interfaceName)
    }
    
    private func recursiveAddObject(documentableType: Documentable.Type, interfaceName: String? = nil, parent: KlassPointer? = nil) {
        let className = "\(documentableType)"
        if let pointer = self.objects.first(where: { $0.className == className }) {
            // If the pointer is already found, then just update the interface mapping.
            addInterfaceMapping(pointer: pointer, interfaceName: interfaceName)
        }
        else {
            // First add the object in case there is recursive serialization.
            let pointer = KlassPointer(klass: documentableType)
            if let parentPointer = parent, let parentIndex = self.objects.firstIndex(of: parentPointer) {
                // If this is an object that was discovered by inspection (below) of the properties
                // on this object, then we want to include the definitions for those objects *before*
                // this object.
                self.objects.insert(pointer, at: parentIndex)
            }
            else {
                self.objects.append(pointer)
            }
            
            // Then look at the property mappings.
            if let docType = documentableType as? DocumentableObject.Type {
                docType.codingKeys().forEach {
                    do {
                        let prop = try docType.documentProperty(for: $0)
                        switch prop.propertyType {
                        case .reference(let dType):
                            recursiveAddObject(documentableType: dType, interfaceName: nil, parent: pointer)
                        case .referenceArray(let dType):
                            recursiveAddObject(documentableType: dType, interfaceName: nil, parent: pointer)
                        case .interface(let interface):
                            addInterfaceMapping(pointer: nil, interfaceName: interface)
                        case .interfaceArray(let interface):
                            addInterfaceMapping(pointer: nil, interfaceName: interface)
                        default:
                            break
                        }
                    }
                    catch let err {
                        print("Failed to get the property for \($0): \(err)")
                    }
                }
            }
            
            // Finally add the interface mapping.
            addInterfaceMapping(pointer: pointer, interfaceName: interfaceName)
        }
    }
    
    private func addInterfaceMapping(pointer: KlassPointer?, interfaceName: String?) {
        guard let interface = interfaceName else { return }
        let ref = JsonSchemaReferenceId(interface)
        if let pointer = pointer, !pointer.interfaces.contains(ref) {
            pointer.interfaces.append(ref)
        }
        if !self.interfaces.contains(ref) {
            self.interfaces.append(ref)
        }
    }
    
    private func pointer(for documentableType: Documentable.Type) -> KlassPointer? {
        let className = "\(documentableType)"
        return self.objects.first(where: { $0.className == className })
    }
    
    fileprivate func buildSchemaProperty(for prop: DocumentProperty) throws -> JsonSchemaProperty {
        switch prop.propertyType {
        case .reference(let dType):
            guard let pointer = self.pointer(for: dType) else {
                throw DocumentableError.invalidMapping("Could not find the pointer for the property mapping.")
            }
            if let const = prop.constValue {
                return .const(JsonSchemaConst(const: const, ref: pointer.schemaRef))
            }
            else {
                return .reference(JsonSchemaObjectRef(ref: pointer.schemaRef))
            }
            
        case .referenceArray(let dType):
            guard let pointer = self.pointer(for: dType) else {
                throw DocumentableError.invalidMapping("Could not find the pointer for the property mapping.")
            }
            return .array(JsonSchemaArray(items: .reference(JsonSchemaObjectRef(ref: pointer.schemaRef))))
            
        case .interface(let className):
            guard let schemaRef = self.interfaces.first(where: { $0.className == className }) else {
                throw DocumentableError.invalidMapping("Could not find the pointer for the property mapping.")
            }
            return .reference(JsonSchemaObjectRef(ref: schemaRef))
        
        case .interfaceArray(let className):
            guard let schemaRef = self.interfaces.first(where: { $0.className == className }) else {
                throw DocumentableError.invalidMapping("Could not find the pointer for the property mapping.")
            }
            return .array(JsonSchemaArray(items: .reference(JsonSchemaObjectRef(ref: schemaRef))))
            
        case .primitive(let jsonType):
            if let defaultValue = prop.defaultValue {
                return .primitive(JsonSchemaPrimitive(defaultValue: defaultValue))
            }
            else {
                return .primitive(JsonSchemaPrimitive(jsonType: jsonType))
            }
        
        case .primitiveArray(let jsonType):
            return .array(JsonSchemaArray(items: .primitive(JsonSchemaPrimitive(jsonType: jsonType))))
        
        }
    }
    
    class KlassPointer : Hashable {
        let klass: Documentable.Type
        
        var interfaces: [JsonSchemaReferenceId] = []
        var examples: [JsonElement] = []
        
        init(klass: Documentable.Type) {
            self.klass = klass
        }

        var className: String {
            "\(klass)"
        }
        
        var schemaRef: JsonSchemaReferenceId {
            JsonSchemaReferenceId(className)
        }
        
        func buildDefinition(using builder: JsonDocumentBuilder) throws -> JsonSchemaDefinition {
            let ref = JsonSchemaReferenceId(className)
            if let docType = klass as? DocumentableStringLiteral.Type {
                return .stringLiteral(JsonSchemaStringLiteral(id: ref,
                                                              description: "",
                                                              examples: docType.examples(),
                                                              pattern: docType.regularExpression))
            }
            else if let docType = klass as? DocumentableStringEnum.Type {
                return .stringEnum(JsonSchemaStringEnum(id: ref,
                                                        values: docType.allValues()))
            }
            else if let docType = klass as? DocumentableObject.Type {
                let codingKeys = docType.codingKeys()
                let required = codingKeys.compactMap { docType.isRequired($0) ? $0.stringValue : nil }
                let examples = try docType.jsonExamples()
                let properties = try codingKeys.reduce(into: [String : JsonSchemaProperty]()) { (hashtable, key) in
                    let prop = try docType.documentProperty(for: key)
                    hashtable[key.stringValue] = try builder.buildSchemaProperty(for: prop)
                }
                return .object(JsonSchemaObject(id: ref,
                                                properties: properties,
                                                required: required,
                                                isOpen: docType.isOpen(),
                                                description: "",
                                                interfaces: self.interfaces,
                                                examples: examples))
            }
            else {
                fatalError("Not implemented")
            }
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(className)
        }
        
        static func == (lhs: JsonDocumentBuilder.KlassPointer, rhs: JsonDocumentBuilder.KlassPointer) -> Bool {
            return lhs.className == rhs.className
        }
    }
}
