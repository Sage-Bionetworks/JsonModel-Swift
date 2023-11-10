import SwiftSyntax
import SwiftSyntaxMacros

public struct SerializableMacro {
}

// TODO: syoung 11/10/2023 support polymorphic serialization

extension SerializableMacro: MemberMacro {
    
    private static func checkExpectations(
        node: AttributeSyntax,
        declaration: some DeclGroupSyntax
    ) throws {
        
        guard [SwiftSyntax.SyntaxKind.classDecl, .structDecl].contains(declaration.kind)
        else {
            throw SerializableMacroError.invalidDeclarationKind(declaration, "Only classes and structs are supported.")
        }
    }
    
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        
        try checkExpectations(node: node, declaration: declaration)

        // Get the list of members
        var hasDefaultValues = false
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
            return varDecl
        }
                
        // Get each case
        let cases = memberList.map { ivar -> String in
            return "case \(ivar.propertyName!)" + (ivar.customCodingKey.map { " = \($0)"} ?? "")
        }
        
        // Build the return syntax
        let codingKeysEnum = DeclSyntax(
        """
        enum CodingKeys: String, OrderedEnumCodingKey {
        \(raw: cases.joined(separator: "\n"))
        }
        """
        )
        
        var ret: [DeclSyntax] = [codingKeysEnum]
        
        // If there are no default values then we're done - exit early
        guard hasDefaultValues
        else {
            return ret
        }
        
        // TODO: syoung 11/10/2023 support classes
        if declaration.kind == .classDecl {
            throw SerializableMacroError.invalidDeclarationKind(declaration, "Only structs are supported.")
        }
        
        // TODO: syoung 11/10/2023 support custom access level
        let accessLevel = declaration.getAccessLevel() ?? .internal
        let predefinedInits = declaration.getPredefinedInits()

        // Add init for decoding
        let decodeInitializer = try buildDecodeInitializer(memberList, accessLevel)
        ret.insert(DeclSyntax(decodeInitializer), at: 0)

        // Add init with all the properties, but only if there aren't any predefined inits.
        if predefinedInits.count == 0 {
            let propInitializer = try buildDefaultInitializer(memberList, accessLevel)
            ret.insert(DeclSyntax(propInitializer), at: 0)
        }
        
        // Add encoding func
        let encodeFunc = try buildEncodeFunc(memberList, accessLevel)
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
    
    private static func buildDecodeInitializer(_ memberList: [VariableDeclSyntax], _ inAccessLevel: AccessLevelModifier) throws -> InitializerDeclSyntax {
        
        // Pre-build the assignments
        let assignments = memberList.map { ivar -> String in
            let type = ivar.type!.as(OptionalTypeSyntax.self)?.wrappedType.trimmed ?? ivar.type!.trimmed
            let isOptional = ivar.type!.is(OptionalTypeSyntax.self) || (ivar.defaultValue != nil)
            let decodeSyntax = isOptional ? "decodeIfPresent" : "decode"
            let assignment = "self.\(ivar.propertyName!) = try container.\(decodeSyntax)(\(type).self, forKey: .\(ivar.propertyName!))"
            return assignment + (ivar.defaultValue.map { " ?? \($0)" } ?? "")
        }
        
        // For an initializer, if the access level is "open" then init() uses public
        let accessLevel = (inAccessLevel == .open) ? .public : inAccessLevel
        
        return try InitializerDeclSyntax("\(raw: accessLevel.stringLiteral())init(from decoder: Decoder) throws") {
            try VariableDeclSyntax("let container = try decoder.container(keyedBy: CodingKeys.self)")
            for assignment in assignments {
                ExprSyntax(stringLiteral: assignment)
            }
        }
    }
    
    private static func buildEncodeFunc(_ memberList: [VariableDeclSyntax], _ accessLevel: AccessLevelModifier) throws -> FunctionDeclSyntax {
        let encodings = memberList.map { ivar -> String in
            let isOptional = ivar.type!.is(OptionalTypeSyntax.self)
            let encodeSyntax = isOptional ? "encodeIfPresent" : "encode"
            return "try container.\(encodeSyntax)(self.\(ivar.propertyName!), forKey: .\(ivar.propertyName!))"
        }
        return try FunctionDeclSyntax("\(raw: accessLevel.stringLiteral())func encode(to encoder: Encoder) throws") {
            try VariableDeclSyntax("var container = encoder.container(keyedBy: CodingKeys.self)")
            for encoding in encodings {
                ExprSyntax(stringLiteral: encoding)
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

        // If there is an explicit conformance to Codable already, don't add one.
        if let inheritedTypes = declaration.inheritanceClause?.inheritedTypes,
           inheritedTypes.contains(where: { inherited in inherited.type.trimmedDescription == "Codable" }) {
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

extension VariableDeclSyntax {
    
    fileprivate var customCodingKey: ExprSyntax? {
        self.firstElement(ofType: SerialNameMacro.self)?.as(AttributeSyntax.self)?.arguments?.as(LabeledExprListSyntax.self)?.first?.expression
    }
    
    fileprivate var isTransient: Bool {
        return self.firstElement(ofType: TransientMacro.self) != nil
    }
    
    fileprivate var isReadWrite: Bool {
        isStoredProperty && self.bindingSpecifier.text.trimmingCharacters(in: .whitespacesAndNewlines) == "var"
    }
}

public enum SerializableMacroError : Error {
    case missingRequiredSyntax(String)
    case invalidDeclarationKind(DeclGroupSyntax, String)
}

