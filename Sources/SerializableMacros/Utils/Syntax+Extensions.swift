// Created 11/9/23
// swift-tools-version:5.0

import SwiftSyntax
import SwiftSyntaxMacros

extension VariableDeclSyntax {
    
    var propertyName: String? {
        bindings.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier.text
    }
    
    var type: TypeSyntax? {
        bindings.first?.typeAnnotation?.type
    }
    
    var isOptionalType: Bool {
        type?.is(OptionalTypeSyntax.self) ?? false
    }
    
    var defaultValue: ExprSyntax? {
        bindings.first?.initializer?.value
    }
    
    /// Determine whether this variable has the syntax of a stored property.
    ///
    /// - Note: This syntactic check cannot account for semantic adjustments
    /// due to accessor macros or property wrappers.
    var isStoredProperty: Bool {
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
    
    func firstElement(ofType macroType: PeerMacro.Type) -> AttributeListSyntax.Element? {
        let macroName = "\(macroType)".replacingOccurrences(of: "Macro", with: "")
        return self.as(VariableDeclSyntax.self)?.attributes.first(where: { element in
            element.as(AttributeSyntax.self)?.attributeName.as(IdentifierTypeSyntax.self)?.description.trimmingCharacters(in: .whitespacesAndNewlines) == macroName
        })
    }
}

extension DeclGroupSyntax {
    
    func getPredefinedInits() -> [InitializerDeclSyntax] {
        return self.memberBlock.members.compactMap { element in
            element.decl.as(InitializerDeclSyntax.self)
        }
    }
    
    func getAccessLevel() -> AccessLevelModifier? {
        return self.modifiers.mapFirst(where: { modifier in
            AccessLevelModifier(rawValue: modifier.name.trimmedDescription)
        })
    }
    
    func getIsFinal() -> Bool {
        return self.kind == .structDecl || self.modifiers.contains(where: { $0.name.trimmed.text == "final" })
    }
}

extension Sequence {
    func mapFirst<T>(where predicate: (Self.Element) throws -> T?) rethrows -> T? {
        for element in self {
            if let ret = try predicate(element) {
                return ret
            }
        }
        return nil
    }
}
