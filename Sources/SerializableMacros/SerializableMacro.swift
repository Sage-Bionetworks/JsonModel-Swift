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
        // Get the list of members
        let memberList = declaration.memberBlock.members
                
        // Get each case
        let cases = memberList.compactMap { member -> String? in
            // Is the member a property declaration?
            guard let propertyName = member.decl.as(VariableDeclSyntax.self)?.bindings.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier.text
            else {
                return nil
            }
            
            if let customKeyMacro = member.firstElement(ofType: SerialNameMacro.self) {
                // If there is a custom key (that isn't the property name) then set that as the encoding key.
                let customKeyValue = customKeyMacro.as(AttributeSyntax.self)!.arguments!.as(LabeledExprListSyntax.self)!.first!.expression
                return "case \(propertyName) = \(customKeyValue)"
            }
            else if let _ = member.firstElement(ofType: TransientMacro.self) {
                // If the property is marked as "Transient" then do not encode it.
                return nil
            }
            else {
                // Finally, the default is to add the coding key with the property name as the key.
                return "case \(propertyName)"
            }
        }
        
        // Build the return string
        let codingKeys: DeclSyntax = """
        enum CodingKeys: String, OrderedEnumCodingKey {
        \(raw: cases.joined(separator: "\n"))
        }
        """
        
        return [codingKeys]
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
      inheritedTypes.contains(where: { inherited in inherited.type.trimmedDescription == "Codable" })
    {
      return []
    }

    return [try ExtensionDeclSyntax("extension \(type): Codable {}")]
  }
}

struct CodableProperty {
    let propertyName: String
    var customKey: String?
    
    var caseName: String? {
        "case \(propertyName)\(customKey.map { " = \($0)" } ?? "")"
    }
}

extension MemberBlockItemListSyntax.Element {
    fileprivate func firstElement(ofType macroType: PeerMacro.Type) -> AttributeListSyntax.Element? {
        var macroName = "\(macroType)".replacingOccurrences(of: "Macro", with: "")
        return self.decl.as(VariableDeclSyntax.self)?.attributes.first(where: { element in
            element.as(AttributeSyntax.self)?.attributeName.as(IdentifierTypeSyntax.self)?.description.trimmingCharacters(in: .whitespacesAndNewlines) == macroName
        })
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
