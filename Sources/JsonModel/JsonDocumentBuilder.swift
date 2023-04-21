// Created 4/21/23
// swift-tools-version:5.0

import Foundation

public class JsonDocumentBuilder {
    public let baseUrl: URL
    public let factory: SerializationFactory?
    
    private(set) var interfaces: [KlassPointer] = []
    private(set) var objects: [KlassPointer] = []
    
    public init(factory: SerializationFactory) {
        self.baseUrl = factory.jsonSchemaBaseURL
        self.factory = factory
        commonInit(factory.documentableInterfaces(), factory.documentableRootObjects)
    }
    
    public init(baseUrl: URL, rootDocument: DocumentableRoot) {
        self.baseUrl = baseUrl
        self.factory = nil
        let roots = [
            RootObjectHolder(jsonSchema: rootDocument.jsonSchema, rootDocumentType: rootDocument.rootDocumentType)
        ]
        commonInit([], roots)
    }
    
    @available(*, deprecated, message: "Base URL and root documents are defined on the factory.")
    public init(baseUrl: URL, factory: SerializationFactory, rootDocuments: [DocumentableObject.Type] = []) {
        self.baseUrl = baseUrl
        self.factory = factory
        var roots = factory.documentableRootObjects
        roots.append(contentsOf: rootDocuments.map {
            RootObjectHolder(jsonSchema: .init(string: "\(factory.modelName(for: "\($0)")).json", relativeTo: baseUrl)!,
                             rootDocumentType: $0)
        })
        commonInit(factory.documentableInterfaces(), roots)
    }
    
    @available(*, deprecated, message: "Base URL and root documents are defined on the factory.")
    init(baseUrl: URL, interfaces: [DocumentableInterface], rootDocuments: [DocumentableObject.Type] = []) {
        self.baseUrl = baseUrl
        self.factory = nil
        let roots = rootDocuments.map {
            RootObjectHolder(jsonSchema: .init(string: "\($0).json", relativeTo: baseUrl)!,
                             rootDocumentType: $0)
        }
        commonInit(interfaces, roots)
    }
    
    @available(*, unavailable, message: "Root replaced with a root document that is optional.")
    public init(baseUrl: URL, rootName: String, factory: SerializationFactory) {
        fatalError("Not available")
    }
    
    @available(*, unavailable, message: "Use `buildSchemas()` instead.")
    public func buildSchema() throws -> JsonSchema {
        fatalError("Not available")
    }
    
    private func commonInit(_ interfaces: [DocumentableInterface], _ rootDocuments: [DocumentableRoot]) {
        
        // First create all the top-level pointers
        let rootDocPointers: [(DocumentableBase.Type, KlassPointer)] = rootDocuments.map { root in
            let baseUrl = factory?.baseUrl(for: root.rootDocumentType) ?? self.baseUrl
            let pointer = KlassPointer(root: root, baseUrl: baseUrl)
            pointer.modelName = factory?.modelName(for: pointer.className) ?? pointer.className
            self.objects.append(pointer)
            return (root.rootDocumentType, pointer)
        }
        let interfacePointers = interfaces.map { (serializer) -> (DocumentableInterface, KlassPointer) in
            let docType = type(of: serializer)
            let baseUrl = factory?.baseUrl(for: docType) ?? self.baseUrl
            let pointer = KlassPointer(root: serializer, baseUrl: baseUrl)
            pointer.modelName = factory?.modelName(for: pointer.className) ?? pointer.className
            pointer.isSealed = serializer.isSealed()
            self.objects.append(pointer)
            self.interfaces.append(pointer)
            // Root objects should include the definitions for objects that they reference *except*
            // for the "type" key which should be defined on the interface.
            self.addTypeKey(for: serializer, pointer)
            return (serializer, pointer)
        }

        // Then add the properties and documentables from each pointer. Add definitions from the root
        // documents *first* and then for the interfaces. This is b/c properties that do not reference
        // an interface and and are only used by the root object, should be defined on the root object
        // rather than the interface.
        rootDocPointers.forEach { root in
            recursiveAddProps(docType: root.0, pointer: root.1)
        }
        interfacePointers.forEach { (serializer, pointer) in
            let docType = type(of: serializer)
            recursiveAddProps(docType: docType, pointer: pointer)
            serializer.documentableExamples().forEach {
                recursiveAddObject(documentableType: type(of: $0), parent: pointer, isSubclass: true)
            }
        }
    }
    
    private func recursiveAddObject(documentableType: Documentable.Type, parent: KlassPointer, isSubclass: Bool) {
        let className = "\(documentableType)"
        let baseUrl = factory?.baseUrl(for: documentableType) ?? parent.baseUrl
        if let pointer = self.objects.first(where: { $0.className == className }) {
            // If the pointer is already found, then update the mapping and pointers.
            addMappings(to: pointer, parent: parent, isSubclass: isSubclass)
        }
        else {
            // Create a new pointer.
            let pointer = createPointer(documentableType: documentableType, parent: parent, baseUrl: baseUrl)
            addMappings(to: pointer, parent: parent, isSubclass: isSubclass)
            
            // Then look at the property mappings.
            if let docType = documentableType as? DocumentableBase.Type {
                recursiveAddProps(docType: docType, pointer: pointer)
            }
        }
    }
    
    private func addTypeKey(for serializer: DocumentableInterface, _ pointer: KlassPointer) {
        let typeProperty = type(of: serializer).typeDocumentProperty()
        guard case .reference(let docType) = typeProperty.propertyType
        else {
            return
        }
        createPointer(documentableType: docType, parent: pointer, baseUrl: pointer.baseUrl)
    }
    
    @discardableResult
    private func createPointer(documentableType: Documentable.Type, parent: KlassPointer, baseUrl: URL) -> KlassPointer {
        // Create a new pointer.
        let pointer = KlassPointer(klass: documentableType, baseUrl: baseUrl, parent: parent)
        pointer.modelName = factory?.modelName(for: pointer.className) ?? pointer.className
        
        // Then add the object in case there is recursive mapping.
        self.objects.append(pointer)
        return pointer
    }
    
    private func addMappings(to pointer: KlassPointer, parent: KlassPointer, isSubclass: Bool) {
        if isSubclass {
            // Is the parent an interface (superclass) that has properties that this object class
            // will inherit? Or is it just a reference? If it is an inheritance pattern, then add
            // to the interfaces associated with this pointer.
            pointer.interfaces.insert(parent)
        }
        // Set up the pointers going both to the parent (the class that has this class as a property
        // or subclass) and to the parent's definitions.
        pointer.parentPointers.insert(parent)
        parent.definitions.insert(pointer)
    }
    
    private func recursiveUpdateRoots() {
        var didChange = false
        self.objects.forEach {
            didChange = didChange || $0.updateIsRootIfNeeded()
        }
        if didChange {
            recursiveUpdateRoots()
        }
    }
    
    private func recursiveAddProps(docType: DocumentableBase.Type, pointer: KlassPointer) {
        docType.codingKeys().forEach {
            do {
                let prop = try docType.documentProperty(for: $0)
                switch prop.propertyType {
                case .reference(let dType), .referenceArray(let dType), .referenceDictionary(let dType):
                    recursiveAddObject(documentableType: dType, parent: pointer, isSubclass: false)
                case .interface(let interface), .interfaceArray(let interface), .interfaceDictionary(let interface):
                    guard self.interfaces.contains(where: { $0.className == interface }) else {
                        throw DocumentableError.invalidMapping("The provided factory does not include a polymophic serializer for `\(interface)` which is defined on `\(docType)` as an interface property for key '\($0)'.")
                    }
                default:
                    break
                }
            }
            catch let err {
                print("Failed to get the property for \($0): \(err)")
            }
        }
    }
    
    private func pointer(for documentableType: Documentable.Type) -> KlassPointer? {
        let className = "\(documentableType)"
        return self.objects.first(where: { $0.className == className })
    }
    
    public func buildSchemas() throws -> [JsonSchema] {
        // Only include roots that have a shared base url
        let roots = self.objects.filter {
            $0.isRoot && $0.refId.baseURL == self.baseUrl
        }
        return try roots.map { (rootPointer) -> JsonSchema in
            guard let docType = rootPointer.klass as? DocumentableBase.Type else {
                throw DocumentableError.invalidMapping("\(rootPointer.klass) does not conform to `DocumentableBase`.")
            }
            let definitions = try rootPointer.allDefinitions(using: self)
            let (properties, required) = try self.buildProperties(for: docType, in: rootPointer)
            let interfaces: [JsonSchemaObjectRef] = try rootPointer.interfaces.map {
                let refId = try self.interfaceSchemaRef(for: $0.className, in: rootPointer)
                return JsonSchemaObjectRef(ref: refId)
            }
            let examples = try (docType as? DocumentableObject.Type).map {
                try $0.jsonExamples()
            }
            return JsonSchema(id: URL(string: rootPointer.refId.classPath)!,
                              description: rootPointer.documentDescription ?? "",
                              isArray: rootPointer.isArray,
                              additionalProperties: (docType as? FinalDocumentableObject.Type)?.additionalProperties,
                              codingKeys: docType.codingKeys(),
                              interfaces: interfaces.count > 0 ? interfaces : nil,
                              definitions: definitions,
                              properties: properties,
                              required: required,
                              examples: examples)
        }
    }
    
    fileprivate func interfaceSchemaRef(for className: String, in objPointer: KlassPointer) throws -> JsonSchemaReferenceId? {
        guard let interface = interface(for: className) else {
            throw DocumentableError.invalidMapping("Could not find the pointer for the interface mapping for \(className).")
        }
        let isRoot = self.objects.contains(where: {
            $0.baseUrl == interface.baseUrl && $0.className == interface.className })
        let baseUrl = (interface.baseUrl == self.baseUrl) ? nil : interface.baseUrl
        if objPointer.mainParent == interface, !objPointer.isRoot, baseUrl == nil, isRoot {
            // If this object is a definition within its parent interface schema,
            // then the ref is to the parent and the documentation should use "#"
            return nil
        }
        else {
            return JsonSchemaReferenceId(interface.modelName, isExternal: isRoot, baseURL: baseUrl)
        }
    }
    
    fileprivate func interface(for className: String) -> KlassPointer? {
        if let ret = self.interfaces.first(where: { $0.className == className || $0.subclassNames.contains(className) }) {
            return ret
        }
        else if let interface = self.factory?.serializerMap[className],
                  let ptr = self.interfaces.first(where: { $0.className == interface.interfaceName }) {
            ptr.subclassNames.append(className)
            return ptr
        }
        else {
            return nil
        }
    }
    
    fileprivate func objectSchemaRef(for dType: Documentable.Type, in objPointer: KlassPointer) throws -> JsonSchemaReferenceId {
        guard let defPointer = self.pointer(for: dType) else {
            throw DocumentableError.invalidMapping("Could not find the pointer for the object mapping for \(dType).")
        }
        let owner = defPointer.definitionOwner
        let baseUrl = (owner.baseUrl == self.baseUrl) ? nil : owner.baseUrl
        if !defPointer.isRoot, objPointer.definitionOwner != defPointer.definitionOwner {
            let rootId = JsonSchemaReferenceId(owner.modelName, isExternal: true, baseURL: baseUrl)
            return JsonSchemaReferenceId(defPointer.modelName, root: rootId)
        }
        else {
            return JsonSchemaReferenceId(defPointer.modelName, isExternal: defPointer.isRoot, baseURL: baseUrl)
        }
    }
    
    fileprivate func buildProperties(for dType: DocumentableBase.Type, in objPointer: KlassPointer) throws
        -> (properties: [String : JsonSchemaProperty], required: [String]) {
            
            let parentDocType = objPointer.mainParent?.klass.documentableType() as? DocumentableInterface.Type
            let parentKeys = parentDocType?.codingKeys() ?? []
            
            let codingKeys = dType.codingKeys()
            var required = codingKeys.compactMap { dType.isRequired($0) ? $0.stringValue : nil }
            let properties = try codingKeys.reduce(into: [String : JsonSchemaProperty]()) { (hashtable, key) in
                let prop = try dType.documentProperty(for: key)
                
                // If there is a matching key on the parent
                if prop.constValue == nil, prop.defaultValue == nil,
                   let parentKey = parentKeys.first(where: { $0.stringValue == key.stringValue }),
                   let parentProp = try parentDocType?.documentProperty(for: parentKey),
                   prop.propertyType == parentProp.propertyType
                {
                    required.removeAll(where: { $0 == key.stringValue })
                    return
                }
                
                hashtable[key.stringValue] = try self.buildSchemaProperty(for: prop, in: objPointer)
            }
            return (properties, required)
    }
    
    fileprivate func buildSchemaProperty(for prop: DocumentProperty, in objPointer: KlassPointer) throws -> JsonSchemaProperty {
        switch prop.propertyType {
        case .any:
            return .primitive(JsonSchemaPrimitive(description: prop.propertyDescription))

        case .format(let format):
            return .primitive(JsonSchemaPrimitive(format: format, description: prop.propertyDescription))

        case .reference(let dType):
            let schemaRef = try objectSchemaRef(for: dType, in: objPointer)
            if let const = prop.constValue {
                return .const(JsonSchemaConst(const: const, ref: schemaRef, description: prop.propertyDescription))
            }
            else {
                return .reference(JsonSchemaObjectRef(ref: schemaRef, description: prop.propertyDescription))
            }

        case .referenceArray(let dType):
            let schemaRef = try objectSchemaRef(for: dType, in: objPointer)
            return .array(JsonSchemaArray(items: .reference(JsonSchemaObjectRef(ref: schemaRef)), description: prop.propertyDescription))

        case .referenceDictionary(let dType):
            let schemaRef = try objectSchemaRef(for: dType, in: objPointer)
            return .dictionary(JsonSchemaTypedDictionary(items: .reference(JsonSchemaObjectRef(ref: schemaRef)), description: prop.propertyDescription))

        case .interface(let className):
            let schemaRef = try interfaceSchemaRef(for: className, in: objPointer)
            return .reference(JsonSchemaObjectRef(ref: schemaRef, description: prop.propertyDescription))

        case .interfaceArray(let className):
            let schemaRef = try interfaceSchemaRef(for: className, in: objPointer)
            return .array(JsonSchemaArray(items: .reference(JsonSchemaObjectRef(ref: schemaRef)), description: prop.propertyDescription))

        case .interfaceDictionary(let className):
            let schemaRef = try interfaceSchemaRef(for: className, in: objPointer)
            return .dictionary(JsonSchemaTypedDictionary(items: .reference(JsonSchemaObjectRef(ref: schemaRef)), description: prop.propertyDescription))

        case .primitive(let jsonType):
            if let defaultValue = prop.defaultValue {
                return .primitive(JsonSchemaPrimitive(defaultValue: defaultValue, description: prop.propertyDescription))
            }
            else {
                return .primitive(JsonSchemaPrimitive(jsonType: jsonType, description: prop.propertyDescription))
            }

        case .primitiveArray(let jsonType):
            return .array(JsonSchemaArray(items: .primitive(JsonSchemaPrimitive(jsonType: jsonType)), description: prop.propertyDescription))

        case .primitiveDictionary(let jsonType):
            return .dictionary(JsonSchemaTypedDictionary(items: .primitive(JsonSchemaPrimitive(jsonType: jsonType)), description: prop.propertyDescription))
        }
    }
    
    struct RootObjectHolder : DocumentableRoot {
        let jsonSchema: URL
        let rootDocumentType: DocumentableBase.Type
        
        var documentDescription: String? { nil }
        var isDocumentTypeArray: Bool { false }
        var className: String { "\(rootDocumentType)" }
    }
    
    class KlassPointer : Hashable {
        let klass: Documentable.Type
        let className: String
        let baseUrl: URL
        let isArray: Bool
        private let _refId: JsonSchemaReferenceId?
        
        var isRoot: Bool
        var isInterface: Bool
        var isSealed: Bool = false
        lazy var modelName: String = self.className
        var subclassNames: [String] = []
        
        var definitionOwner: KlassPointer {
            self.isRoot ? self : (mainParent ?? self)
        }
        
        var mainParent: KlassPointer?
        var interfaces = Set<KlassPointer>()
        var parentPointers: Set<KlassPointer>!
        var definitions = Set<KlassPointer>()
        var documentDescription: String?
        
        init(klass: Documentable.Type, baseUrl: URL, parent: KlassPointer) {
            self.klass = klass
            self.isArray = false
            self.parentPointers = [parent]
            self.isInterface = false
            if parent.klass is DocumentableRootObject.Type {
                self.mainParent = parent
            }
            else {
                self.mainParent = parent.mainParent ?? parent
            }
            if let rootKlass = klass as? DocumentableRootObject.Type {
                let example = rootKlass.init()
                let refId = JsonSchemaReferenceId(url: example.jsonSchema)
                self.mainParent = parent
                self.baseUrl = refId.baseURL ?? baseUrl
                self.className = example.className
                self.isRoot = true
                self._refId = refId
            }
            else {
                self.baseUrl = baseUrl
                self.className = "\(klass)"
                self.isRoot = (parent.baseUrl != baseUrl)
                self._refId = nil
            }
        }
        
        init(root: DocumentableRoot, baseUrl: URL) {
            self.klass = root.rootDocumentType
            self.isArray = root.isDocumentTypeArray
            self.parentPointers = []
            self.mainParent = nil
            let refId = JsonSchemaReferenceId(url: root.jsonSchema)
            self.baseUrl = refId.baseURL ?? baseUrl
            self.isRoot = true
            self.isInterface = root is DocumentableInterface
            self.className = root.className
            self._refId = refId
            self.documentDescription = root.documentDescription
            self.modelName = refId.className
        }
        
        deinit {
            parentPointers = nil
        }
        
        var refId: JsonSchemaReferenceId {
            _refId ?? JsonSchemaReferenceId(modelName, isExternal: isRoot, baseURL: isRoot ? baseUrl : nil)
        }
        
        fileprivate func updateIsRootIfNeeded() -> Bool {
            // Only change to root if this is not part of an interface.
            guard !self.isRoot, klass is DocumentableBase.Type, self.interfaces.count == 0
                else {
                    return false
            }
            let roots = Set(_recursiveRootParents())
            self.isRoot = (roots.count > 1)
            return self.isRoot
        }
        
        private func _recursiveRootParents() -> [KlassPointer] {
            self.isRoot ? [self] : self.parentPointers.flatMap { $0._recursiveRootParents() }
        }
        
        func allDefinitions(using builder: JsonDocumentBuilder) throws -> [JsonSchemaDefinition] {
            let defs = _filteredRecursiveDefinitions().filter { $0.mainParent == self }
            return try defs.map {
                try $0.buildDefinition(using: builder)
            }
        }
        
        private func _filteredRecursiveDefinitions() -> [KlassPointer] {
            self.definitions.flatMap { $0.isRoot ? [] : $0._recursiveFlatMap() }
        }
        
        private func _recursiveFlatMap() -> Set<KlassPointer> {
            Set([self]).union(self._filteredRecursiveDefinitions())
        }
        
        func buildDefinition(using builder: JsonDocumentBuilder) throws -> JsonSchemaDefinition {
            let ref = JsonSchemaReferenceId(modelName)
            if let docType = klass as? DocumentableStringLiteral.Type {
                return .stringLiteral(JsonSchemaStringLiteral(id: ref,
                                                              description: "",
                                                              examples: docType.examples()))
            }
            else if let docType = klass as? DocumentableStringEnum.Type {
                return .stringEnum(JsonSchemaStringEnum(id: ref,
                                                        values: docType.allValues()))
            }
            else if let docType = klass as? DocumentableStringOptionSet.Type {
                return .stringOptionSet(JsonSchemaStringOptionSet(id: ref,
                                                                  description: "",
                                                                  examples: docType.examples()))
            }
            else if let docType = klass as? DocumentableObject.Type {
                let examples = try docType.jsonExamples()
                let (properties, required) = try builder.buildProperties(for: docType, in: self)
                let interfaces: [JsonSchemaObjectRef] = try self.interfaces.map {
                    let refId = try builder.interfaceSchemaRef(for: $0.className, in: self)
                    return JsonSchemaObjectRef(ref: refId)
                }
                return .object(JsonSchemaObject(id: ref,
                                                additionalProperties: (docType as? FinalDocumentableObject.Type)?.additionalProperties,
                                                description: "",
                                                codingKeys: docType.codingKeys(),
                                                properties: properties,
                                                required: required,
                                                interfaces: interfaces,
                                                examples: examples))
            }
            else if let docType = klass as? DocumentableAny.Type {
                return .any(.init(id: ref, definition: docType.jsonSchemaDefinition()))
            }
            else {
                fatalError("Not implemented")
            }
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(className)
            hasher.combine(baseUrl)
        }
        
        static func == (lhs: JsonDocumentBuilder.KlassPointer, rhs: JsonDocumentBuilder.KlassPointer) -> Bool {
            return lhs.className == rhs.className && lhs.baseUrl == rhs.baseUrl
        }
    }
}
