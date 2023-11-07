import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

@main
struct SerializablePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        SerializableMacro.self,
        SerialNameMacro.self,
        TransientMacro.self,
    ]
}
