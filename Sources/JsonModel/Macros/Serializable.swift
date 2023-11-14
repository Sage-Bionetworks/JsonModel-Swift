import Foundation

@attached(member, names: named(CodingKeys), named(init), named(encode), named(typeName))
@attached(extension, conformances: Codable)
public macro Serializable(subclassIndex: Int? = nil) = #externalMacro(module: "SerializableMacros", type: "SerializableMacro")

@attached(peer)
public macro SerialName(_ name: String) = #externalMacro(module: "SerializableMacros", type: "SerialNameMacro")

@attached(peer)
public macro Transient() = #externalMacro(module: "SerializableMacros", type: "TransientMacro")

@attached(peer)
public macro Polymorphic() = #externalMacro(module: "SerializableMacros", type: "PolymorphicMacro")

