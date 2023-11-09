import SwiftSyntax
import SwiftSyntaxMacros

public struct SerializableMacro {
}

extension SerializableMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        
        var hasDefaultValues = false
        
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
        
        // TODO: syoung 11/09/2023 do not add if there is already an initializer and/or encoder func
        // TODO: syoung 11/09/2023 handle public/internal modifier
        // TODO: syoung 11/09/2023 support final classes
        
        // Check that this macro supports creating initializers for this object
        guard declaration.is(StructDeclSyntax.self)
        else {
            throw SerializableMacroError.onlyApplicableToStructOrFinal
        }

        // Add init for decoding
        let decodeInitializer = try buildDecodeInitializer(memberList)
        ret.insert(DeclSyntax(decodeInitializer), at: 0)

        // Add init with all the properties
        let propInitializer = try buildDefaultInitializer(memberList)
        ret.insert(DeclSyntax(propInitializer), at: 0)
        
        // Add encoding func
        let encodeFunc = try buildEncodeFunc(memberList)
        ret.append(DeclSyntax(encodeFunc))

        return ret
    }
    
    static func buildDefaultInitializer(_ memberList: [VariableDeclSyntax]) throws -> InitializerDeclSyntax {
        let parameters = memberList.map { ivar -> String in
            let defaultParam = ivar.defaultValue ?? (ivar.isOptionalType ? ExprSyntax(stringLiteral: "nil") : nil)
            return "\(ivar.propertyName!): \(ivar.type!.trimmed)" + (defaultParam.map { " = \($0)"} ?? "")
        }
        let assignments = memberList.map { ivar -> String in
            return "self.\(ivar.propertyName!) = \(ivar.propertyName!)"
        }
        return try InitializerDeclSyntax("init(\(raw: parameters.joined(separator: ", ")))") {
            for assignment in assignments {
                ExprSyntax(stringLiteral: assignment)
            }
        }
    }
    
    static func buildDecodeInitializer(_ memberList: [VariableDeclSyntax]) throws -> InitializerDeclSyntax {
        let assignments = memberList.map { ivar -> String in
            let type = ivar.type!.as(OptionalTypeSyntax.self)?.wrappedType.trimmed ?? ivar.type!.trimmed
            let isOptional = ivar.type!.is(OptionalTypeSyntax.self) || (ivar.defaultValue != nil)
            let decodeSyntax = isOptional ? "decodeIfPresent" : "decode"
            let assignment = "self.\(ivar.propertyName!) = try container.\(decodeSyntax)(\(type).self, forKey: .\(ivar.propertyName!))"
            return assignment + (ivar.defaultValue.map { " ?? \($0)" } ?? "")
        }
        return try InitializerDeclSyntax("init(from decoder: Decoder) throws") {
            try VariableDeclSyntax("let container = try decoder.container(keyedBy: CodingKeys.self)")
            for assignment in assignments {
                ExprSyntax(stringLiteral: assignment)
            }
        }
    }
    
    static func buildEncodeFunc(_ memberList: [VariableDeclSyntax]) throws -> FunctionDeclSyntax {
        let encodings = memberList.map { ivar -> String in
            let isOptional = ivar.type!.is(OptionalTypeSyntax.self)
            let encodeSyntax = isOptional ? "encodeIfPresent" : "encode"
            return "try container.\(encodeSyntax)(self.\(ivar.propertyName!), forKey: .\(ivar.propertyName!))"
        }
        return try FunctionDeclSyntax("func encode(to encoder: Encoder) throws") {
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
    
    fileprivate var propertyName: String? {
        bindings.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier.text
    }
    
    fileprivate var type: TypeSyntax? {
        bindings.first?.typeAnnotation?.type
    }
    
    fileprivate var isOptionalType: Bool {
        type?.is(OptionalTypeSyntax.self) ?? false
    }
    
    fileprivate var defaultValue: ExprSyntax? {
        bindings.first?.initializer?.value
    }
    
    fileprivate var customCodingKey: ExprSyntax? {
        self.firstElement(ofType: SerialNameMacro.self)?.as(AttributeSyntax.self)?.arguments?.as(LabeledExprListSyntax.self)?.first?.expression
    }
    
    fileprivate var isTransient: Bool {
        return self.firstElement(ofType: TransientMacro.self) != nil
    }
    
    fileprivate var isReadWrite: Bool {
        isStoredProperty && self.bindingSpecifier.text.trimmingCharacters(in: .whitespacesAndNewlines) == "var"
    }

    /// Determine whether this variable has the syntax of a stored property.
    ///
    /// - Note: This syntactic check cannot account for semantic adjustments
    /// due to accessor macros or property wrappers.
    fileprivate var isStoredProperty: Bool {
        guard bindings.count == 1,
              let binding = bindings.first
        else {
            return false
        }
        
        switch binding.accessorBlock?.accessors {
        case .none:
            return true
            
        case .accessors(let accessors):
            for accessor in accessors {
                switch accessor.accessorSpecifier.tokenKind {
                case .keyword(.willSet), .keyword(.didSet):
                    // Observers can occur on a stored property.
                    break
                    
                default:
                    // Other accessors make it a computed property.
                    return false
                }
            }
            return true
            
        case .getter:
            return false
        }
    }
    
    fileprivate func firstElement(ofType macroType: PeerMacro.Type) -> AttributeListSyntax.Element? {
        let macroName = "\(macroType)".replacingOccurrences(of: "Macro", with: "")
        return self.as(VariableDeclSyntax.self)?.attributes.first(where: { element in
            element.as(AttributeSyntax.self)?.attributeName.as(IdentifierTypeSyntax.self)?.description.trimmingCharacters(in: .whitespacesAndNewlines) == macroName
        })
    }
}

public enum SerializableMacroError : Error {
    case missingRequiredSyntax(String)
    case onlyApplicableToStructOrFinal
}

