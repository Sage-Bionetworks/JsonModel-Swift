import SwiftSyntax
import SwiftSyntaxMacros

public struct SerializableMacro {
    
    private static func checkExpectations(
        node: AttributeSyntax,
        declaration: some DeclGroupSyntax
    ) throws {
        
        guard [SwiftSyntax.SyntaxKind.classDecl, .structDecl].contains(declaration.kind)
        else {
            throw SerializableMacroError.invalidDeclarationKind(declaration, "Only classes and structs are supported.")
        }
    }
}

extension SerializableMacro: MemberMacro {

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
 
        try checkExpectations(node: node, declaration: declaration)
        
        let isClass = declaration.kind == .classDecl
        let isFinal = declaration.getIsFinal()
        let subclassIndex = try node.getSubclassIndex() ?? (isClass && !isFinal ? 0 : nil)
        var hasDefaultValues = false
        var hasPolymorphicValues = false
        let isSubclass = isClass && (subclassIndex ?? 0) > 0
        let accessLevel = declaration.getAccessLevel() ?? .internal
        let typeVar = try declaration.customCodingKey.map {
            try VariableDeclSyntax("\(raw: accessLevel.stringLiteral())let typeName: String = \($0)")
        }
        
        if !isFinal, let _ = typeVar {
            throw SerializableMacroError.invalidPolymorphicType("The @SerialName macro can only be used with structs and final classes")
        }

        // Get the list of members
        let memberList = try declaration.memberBlock.members.compactMap { member -> VariableDeclSyntax? in
            guard let varDecl = member.decl.as(VariableDeclSyntax.self),
                  !varDecl.isTransient,
                  varDecl.isStoredProperty,
                  let propertyName = varDecl.propertyName
            else {
                return nil
            }
            if varDecl.type == nil {
                throw SerializableMacroError.missingRequiredSyntax("Cannot expand property `\(propertyName)` without a `Type`")
            }
            
            hasDefaultValues = hasDefaultValues || (!varDecl.isOptionalType && (varDecl.defaultValue != nil))
            hasPolymorphicValues = hasPolymorphicValues || varDecl.isPolymorphic
            
            return varDecl
        }
        
        // set up the return
        var ret: [DeclSyntax] = typeVar.map { [DeclSyntax($0)] } ?? []
                
        // Build `enum CodingKeys`
        var cases = memberList.map { ivar -> String in
            return "case \(ivar.propertyName!)" + (ivar.customCodingKey.map { " = \($0)"} ?? "")
        }
        if let _ = typeVar {
            cases.append("case typeName = \"type\"")
        }
        if let idx = subclassIndex {
            ret.append(DeclSyntax(
            """
            enum CodingKeys: String, OrderedEnumCodingKey, OpenOrderedCodingKey {
            \(raw: cases.joined(separator: "\n"))
            
            var relativeIndex: Int { return \(raw: idx) }
            }
            """))
        }
        else {
            ret.append(DeclSyntax(
            """
            enum CodingKeys: String, OrderedEnumCodingKey {
            \(raw: cases.joined(separator: "\n"))
            }
            """))
        }

        
        // If there are no default values then we're done - exit early
        guard hasDefaultValues || hasPolymorphicValues || !isFinal || isSubclass
        else {
            return ret
        }
        
        // TODO: syoung 11/10/2023 support custom access level
        let predefinedInits = declaration.getPredefinedInits()

        // Add init for decoding
        if memberList.count > 1 || typeVar == nil {
            let decodeInitializer = try buildDecodeInitializer(memberList, accessLevel, isSubclass || (isClass && !isFinal), isSubclass)
            ret.insert(DeclSyntax(decodeInitializer), at: 0)
        }

        // Add init with all the properties, but only if there aren't any predefined inits
        // and this isn't a final class (that isn't a subclass).
        if predefinedInits.count == 0 && subclassIndex == nil {
            let propInitializer = try buildDefaultInitializer(memberList, accessLevel)
            ret.insert(DeclSyntax(propInitializer), at: 0)
        }
        
        // Add encoding func
        let encodeFunc = try buildEncodeFunc(memberList, accessLevel, isSubclass, typeVar)
        ret.append(DeclSyntax(encodeFunc))

        return ret
    }
    
    private static func buildDefaultInitializer(_ memberList: [VariableDeclSyntax], _ inAccessLevel: AccessLevelModifier) throws -> InitializerDeclSyntax {
        
        // Pre-build the parameters and assignments
        let parameters = memberList.map { ivar -> String in
            let defaultParam = ivar.defaultValue ?? (ivar.isOptionalType ? ExprSyntax(stringLiteral: "nil") : nil)
            return "\(ivar.propertyName!): \(ivar.type!.trimmed)" + (defaultParam.map { " = \($0)"} ?? "")
        }
        let assignments = memberList.map { ivar -> String in
            return "self.\(ivar.propertyName!) = \(ivar.propertyName!)"
        }
        
        // For an initializer, if the access level is "open" then init() uses public
        let accessLevel = (inAccessLevel == .open) ? .public : inAccessLevel
        
        return try InitializerDeclSyntax("\(raw: accessLevel.stringLiteral())init(\(raw: parameters.joined(separator: ", ")))") {
            for assignment in assignments {
                ExprSyntax(stringLiteral: assignment)
            }
        }
    }
    
    private static func buildDecodeInitializer(_ memberList: [VariableDeclSyntax], _ inAccessLevel: AccessLevelModifier, _ isRequired: Bool, _ isOverride: Bool) throws -> InitializerDeclSyntax {

        // For an initializer, if the access level is "open" then init() uses public
        let accessLevel = (inAccessLevel == .open) ? .public : inAccessLevel
        
        // Classes have to use the required keyword
        let requiredKeyword = isRequired ? "required " : ""
        
        return try InitializerDeclSyntax("\(raw: accessLevel.stringLiteral())\(raw: requiredKeyword)init(from decoder: Decoder) throws") {
            try VariableDeclSyntax("let container = try decoder.container(keyedBy: CodingKeys.self)")
            for ivar in memberList {
                
                let name = ivar.propertyName!
                let type = ivar.type!.as(OptionalTypeSyntax.self)?.wrappedType.trimmed ?? ivar.type!.trimmed
                let isOptional = ivar.type!.is(OptionalTypeSyntax.self) || (ivar.defaultValue != nil)
                
                if ivar.isPolymorphic {
                    let decoderName = isOptional ? "nestedDecoder" : "\(name)Decoder"
                    let isArray = type.is(ArrayTypeSyntax.self)
                    let innerType = isArray ? type.as(ArrayTypeSyntax.self)!.element : type
                    let funcName = isArray ? "decodePolymorphicArray" : "decodePolymorphicObject"
                    let decoderFuncName = isArray ? "nestedUnkeyedContainer" : "superDecoder"
                    let varSyntax = try VariableDeclSyntax(
                        "let \(raw: decoderName) = try container.\(raw: decoderFuncName)(forKey: .\(raw: name))")
                    let assignSyntax = ExprSyntax(stringLiteral:
                        "self.\(name) = try decoder.serializationFactory.\(funcName)(\(innerType).self, from: \(decoderName))")
                    if isOptional {
                        // Building this using an IfExprSyntax doesn't appear to allow an optional else statement
                        // so just hardcode building it.
                        let elseSyntax = ivar.defaultValue.map { "else { self.\(ivar.propertyName!) = \($0) }" } ?? ""
                        ExprSyntax(stringLiteral: """
                        if container.contains(.\(ivar.propertyName!)) {
                        \(varSyntax)
                        \(assignSyntax)
                        }\(elseSyntax)
                        """)
                    }
                    else {
                        varSyntax
                        assignSyntax
                    }
                }
                else {
                    let decodeSyntax = isOptional ? "decodeIfPresent" : "decode"
                    let assignment = "self.\(ivar.propertyName!) = try container.\(decodeSyntax)(\(type).self, forKey: .\(ivar.propertyName!))"
                    ExprSyntax(stringLiteral: assignment + (ivar.defaultValue.map { " ?? \($0)" } ?? ""))
                }
            }
            if isOverride {
                ExprSyntax(stringLiteral: "try super.init(from: decoder)")
            }
        }
    }
    
    private static func buildEncodeFunc(
        _ memberList: [VariableDeclSyntax],
        _ accessLevel: AccessLevelModifier,
        _ isOverride: Bool,
        _ typeVar: VariableDeclSyntax?
    ) throws -> FunctionDeclSyntax {
        let overrideKeyword = isOverride ? " override " : ""
        return try FunctionDeclSyntax("\(raw: accessLevel.stringLiteral())\(raw: overrideKeyword)func encode(to encoder: Encoder) throws") {
            if isOverride {
                ExprSyntax(stringLiteral: "try super.encode(to: encoder)")
            }
            try VariableDeclSyntax("var container = encoder.container(keyedBy: CodingKeys.self)")
            if let _ = typeVar {
                ExprSyntax(stringLiteral: "try container.encode(self.typeName, forKey: .typeName)")
            }
            for ivar in memberList {
                let name = ivar.propertyName!
                let isOptional = ivar.type!.is(OptionalTypeSyntax.self)
                let type = ivar.type!.as(OptionalTypeSyntax.self)?.wrappedType.trimmed ?? ivar.type!.trimmed
                
                if ivar.isPolymorphic {
                    let encoderName = isOptional ? "nestedEncoder" : "\(name)Encoder"
                    let objName = isOptional ? "obj" : "self.\(name)"
                    let encoderFuncName = type.is(ArrayTypeSyntax.self) ? "nestedUnkeyedContainer" : "superEncoder"
                    let varSyntax = try VariableDeclSyntax("var \(raw: encoderName) = container.\(raw: encoderFuncName)(forKey: .\(raw: name))")
                    let encodeSyntax = ExprSyntax(stringLiteral: "try \(encoderName).encodePolymorphic(\(objName))")
                    if isOptional {
                        try IfExprSyntax("if let obj = self.\(raw: name)") {
                            varSyntax
                            encodeSyntax
                        }
                    }
                    else {
                        varSyntax
                        encodeSyntax
                    }
                }
                else {
                    let encodeSyntax = isOptional ? "encodeIfPresent" : "encode"
                    ExprSyntax(stringLiteral: "try container.\(encodeSyntax)(self.\(name), forKey: .\(name))")
                }
            }
        }
    }
}

extension SerializableMacro: ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        
        try checkExpectations(node: node, declaration: declaration)

        // If there is an explicit conformance to Codable already, don't add conformance.
        if let inheritedTypes = declaration.inheritanceClause?.inheritedTypes,
           inheritedTypes.contains(where: { inherited in inherited.type.trimmedDescription == "Codable" }) {
           return []
        }
        
        // If this is a subclass then don't add conformance.
        if let subclassIndex = try node.getSubclassIndex(), subclassIndex > 0 {
            return []
        }
        
        // If this is a non-final class with a "type" declaration, then it's invalid.
        if !declaration.getIsFinal(), let _ = declaration.customCodingKey {
            return []
        }

        return [try ExtensionDeclSyntax("extension \(type): Codable {}")]
    }
}

public struct SerialNameMacro: PeerMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingPeersOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    // Does nothing, used only to decorate members with data
    return []
  }
}

public struct TransientMacro: PeerMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingPeersOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    // Does nothing, used only to decorate members with data
    return []
  }
}

public struct PolymorphicMacro: PeerMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingPeersOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    // Does nothing, used only to decorate members with data
    return []
  }
}

extension VariableDeclSyntax {
    
    fileprivate var customCodingKey: ExprSyntax? {
        self.firstElement(ofType: SerialNameMacro.self)?.getFirstExpression()
    }
    
    fileprivate var isTransient: Bool {
        return self.firstElement(ofType: TransientMacro.self) != nil
    }
    
    fileprivate var isPolymorphic: Bool {
        return self.firstElement(ofType: PolymorphicMacro.self) != nil
    }
    
    fileprivate var isReadWrite: Bool {
        isStoredProperty && self.bindingSpecifier.text.trimmingCharacters(in: .whitespacesAndNewlines) == "var"
    }
}

extension DeclGroupSyntax {
    
    fileprivate var customCodingKey: ExprSyntax? {
        self.firstElement(ofType: SerialNameMacro.self)?.getFirstExpression()
    }
}

extension AttributeSyntax {
    
    fileprivate func getFirstExpression() -> ExprSyntax? {
        arguments?.as(LabeledExprListSyntax.self)?.first?.expression
    }
    
    fileprivate func getSubclassIndex() throws -> Int? {
        guard let arguments = self.arguments?.as(LabeledExprListSyntax.self),
              let expression = arguments.first(where: { $0.label?.trimmed.text == "subclassIndex"})?.expression
        else {
            return nil
        }
        guard let intLiteral = expression.as(IntegerLiteralExprSyntax.self)?.literal.trimmed.text,
              let idx = Int(intLiteral)
        else {
            throw SerializableMacroError.invalidAttributeSyntax("Could not convert \(expression) to an Int")
        }
        return idx
    }
}

public enum SerializableMacroError : Error {
    case missingRequiredSyntax(String)
    case invalidDeclarationKind(DeclGroupSyntax, String)
    case invalidAttributeSyntax(String)
    case invalidPolymorphicType(String)
}

