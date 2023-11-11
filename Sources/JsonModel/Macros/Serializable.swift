import Foundation

@attached(member, names: named(CodingKeys), named(init), named(encode))
@attached(extension, conformances: Codable)
public macro Serializable(subclassIndex: Int? = nil) = #externalMacro(module: "SerializableMacros", type: "SerializableMacro")

@attached(peer)
public macro SerialName(_ name: String) = #externalMacro(module: "SerializableMacros", type: "SerialNameMacro")

@attached(peer)
public macro Transient() = #externalMacro(module: "SerializableMacros", type: "TransientMacro")

