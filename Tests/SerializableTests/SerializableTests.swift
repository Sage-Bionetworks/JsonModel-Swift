import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import SerializableMacros

let macros: [String: Macro.Type] = [
    "Serializable": SerializableMacro.self,
    "SerialName": SerialNameMacro.self,
    "Transient": TransientMacro.self,
    "Polymorphic": PolymorphicMacro.self,
]

final class SerializableTests: XCTestCase {
    
    func testExpansionAddsDefaultCodingKeys() {
        assertMacroExpansion(
        """
        @Serializable
        struct Person {
            let name: String
            let age: Int
            var magoo: String {
                "test"
            }
            var foo: String? {
                didSet {
                    print("didSet")
                }
            }
        }
        """,
        expandedSource: """
          struct Person {
              let name: String
              let age: Int
              var magoo: String {
                  "test"
              }
              var foo: String? {
                  didSet {
                      print("didSet")
                  }
              }

              enum CodingKeys: String, OrderedEnumCodingKey {
                  case name
                  case age
                  case foo
              }
          }
          
          extension Person: Codable {
          }
          """,
        macros: macros,
        indentationWidth: .spaces(4)
        )
    }

    func testExpansionWithCodableKeyAddsSerialNameKeys() {
        assertMacroExpansion(
        """
        @Serializable
        struct Person: Hashable, Codable {
            let name: String
            @SerialName("user_age") let age: Int

            func randomFunction() {}
        }
        """,
        expandedSource: """
        struct Person: Hashable, Codable {
            let name: String
            let age: Int

            func randomFunction() {}

            enum CodingKeys: String, OrderedEnumCodingKey {
                case name
                case age = "user_age"
            }
        }
        """,
        macros: macros,
        indentationWidth: .spaces(4)
        )
    }
    
    func testExpansionDoesNotAddTransient() {
        assertMacroExpansion(
        """
        @Serializable
        struct Person: Codable {
            let name: String
            let age: Int
            @Transient var foo: String? = nil
        }
        """,
        expandedSource: """
        struct Person: Codable {
            let name: String
            let age: Int
            var foo: String? = nil

            enum CodingKeys: String, OrderedEnumCodingKey {
                case name
                case age
            }
        }
        """,
        macros: macros,
        indentationWidth: .spaces(4)
        )
    }
    
    func testExpansionDoesNotAddTransientNewline() {
        assertMacroExpansion(
        """
        @Serializable
        struct Person: Codable {
            let name: String
            let age: Int
            @Transient
            var foo: String? = nil
        }
        """,
        expandedSource: """
          struct Person: Codable {
              let name: String
              let age: Int
              var foo: String? = nil

              enum CodingKeys: String, OrderedEnumCodingKey {
                  case name
                  case age
              }
          }
          """,
        macros: macros,
        indentationWidth: .spaces(4)
        )
    }
    
    func testExpansionAddDefaultValue() {
        assertMacroExpansion(
        """
        @Serializable
        struct Person : Codable {
            let name: String
            let age: Int
            var foo: String = "goo"
            var mapping: [String : Int] = [:]
            var hulu: Fish?
        }
        """,
        expandedSource: """
        struct Person : Codable {
            let name: String
            let age: Int
            var foo: String = "goo"
            var mapping: [String : Int] = [:]
            var hulu: Fish?
        
            init(name: String, age: Int, foo: String = "goo", mapping: [String : Int] = [:], hulu: Fish? = nil) {
                self.name = name
                self.age = age
                self.foo = foo
                self.mapping = mapping
                self.hulu = hulu
            }
        
            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                self.name = try container.decode(String.self, forKey: .name)
                self.age = try container.decode(Int.self, forKey: .age)
                self.foo = try container.decodeIfPresent(String.self, forKey: .foo) ?? "goo"
                self.mapping = try container.decodeIfPresent([String : Int].self, forKey: .mapping) ?? [:]
                self.hulu = try container.decodeIfPresent(Fish.self, forKey: .hulu)
            }
        
            enum CodingKeys: String, OrderedEnumCodingKey {
                case name
                case age
                case foo
                case mapping
                case hulu
            }
        
            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(self.name, forKey: .name)
                try container.encode(self.age, forKey: .age)
                try container.encode(self.foo, forKey: .foo)
                try container.encode(self.mapping, forKey: .mapping)
                try container.encodeIfPresent(self.hulu, forKey: .hulu)
            }
        }
        """,
        macros: macros,
        indentationWidth: .spaces(4)
        )
    }
    
    func testExpansionPublicAddDefaultValue() {
        assertMacroExpansion(
        """
        @Serializable
        public struct Person : Codable {
            public let name: String
            public var age: Int = 21
        }
        """,
        expandedSource: """
        public struct Person : Codable {
            public let name: String
            public var age: Int = 21
        
            public init(name: String, age: Int = 21) {
                self.name = name
                self.age = age
            }
        
            public init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                self.name = try container.decode(String.self, forKey: .name)
                self.age = try container.decodeIfPresent(Int.self, forKey: .age) ?? 21
            }
        
            enum CodingKeys: String, OrderedEnumCodingKey {
                case name
                case age
            }
        
            public func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(self.name, forKey: .name)
                try container.encode(self.age, forKey: .age)
            }
        }
        """,
        macros: macros,
        indentationWidth: .spaces(4)
        )
    }
    
    func testExpansionAddDefaultValue_DoNotAddInit() {
        assertMacroExpansion(
        """
        @Serializable
        public struct Person : Codable {
            public let name: String
            public var age: Int = 21
        
            public init(name: String) {
                self.name = name
            }
        }
        """,
        expandedSource: """
        public struct Person : Codable {
            public let name: String
            public var age: Int = 21
        
            public init(name: String) {
                self.name = name
            }
        
            public init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                self.name = try container.decode(String.self, forKey: .name)
                self.age = try container.decodeIfPresent(Int.self, forKey: .age) ?? 21
            }
        
            enum CodingKeys: String, OrderedEnumCodingKey {
                case name
                case age
            }
        
            public func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(self.name, forKey: .name)
                try container.encode(self.age, forKey: .age)
            }
        }
        """,
        macros: macros,
        indentationWidth: .spaces(4)
        )
    }
    
    func testExpansionNonFinalClass() {
        // If a class is not final, then it *could* be overridden and must explicitly
        // define the init and encode methods.
        assertMacroExpansion(
        """
        @Serializable
        class UniquePerson {
            private let id: UUID
        }
        """,
        expandedSource: """
        class UniquePerson {
            private let id: UUID
        
            required init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                self.id = try container.decode(UUID.self, forKey: .id)
            }
        
            enum CodingKeys: String, OrderedEnumCodingKey, OpenOrderedCodingKey {
                case id

                var relativeIndex: Int {
                    return 0
                }
            }
        
            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(self.id, forKey: .id)
            }
        }
        
        extension UniquePerson: Codable {
        }
        """,
        macros: macros,
        indentationWidth: .spaces(4)
        )
    }
    
    func testExpansionFinalClass() {
        assertMacroExpansion(
        """
        @Serializable
        final class UniquePerson : Codable {
            let id: UUID
        }
        """,
        expandedSource: """
        final class UniquePerson : Codable {
            let id: UUID
        
            enum CodingKeys: String, OrderedEnumCodingKey {
                case id
            }
        }
        """,
        macros: macros,
        indentationWidth: .spaces(4)
        )
    }
    
    func testExpansionFinalClassWithDefaultValues() {
        assertMacroExpansion(
        """
        @Serializable
        final class UniquePerson : Codable {
            let name: String
            var age: Int = 21
        }
        """,
        expandedSource: """
        final class UniquePerson : Codable {
            let name: String
            var age: Int = 21
        
            init(name: String, age: Int = 21) {
                self.name = name
                self.age = age
            }
        
            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                self.name = try container.decode(String.self, forKey: .name)
                self.age = try container.decodeIfPresent(Int.self, forKey: .age) ?? 21
            }
        
            enum CodingKeys: String, OrderedEnumCodingKey {
                case name
                case age
            }
        
            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(self.name, forKey: .name)
                try container.encode(self.age, forKey: .age)
            }
        }
        """,
        macros: macros,
        indentationWidth: .spaces(4)
        )
    }
    
    func testExpansionSubclass() {
        assertMacroExpansion(
        """
        @Serializable(subclassIndex: 3)
        final class Person: UniquePerson {
            let name: String
            let age: Int
        }
        """,
        expandedSource: """
        final class Person: UniquePerson {
            let name: String
            let age: Int
        
            required init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                self.name = try container.decode(String.self, forKey: .name)
                self.age = try container.decode(Int.self, forKey: .age)
                try super.init(from: decoder)
            }
        
            enum CodingKeys: String, OrderedEnumCodingKey, OpenOrderedCodingKey {
                case name
                case age
        
                var relativeIndex: Int {
                    return 3
                }
            }
        
            override func encode(to encoder: Encoder) throws {
                try super.encode(to: encoder)
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(self.name, forKey: .name)
                try container.encode(self.age, forKey: .age)
            }
        }
        """,
        macros: macros,
        indentationWidth: .spaces(4)
        )
    }
    
    func testExpansionShouldNotAddDefaultValue() {
        assertMacroExpansion(
        """
        @Serializable
        struct Person: Codable {
            let name: String
            let age: Int
            var foo: String? = nil
        }
        """,
        expandedSource: """
        struct Person: Codable {
            let name: String
            let age: Int
            var foo: String? = nil
        
            enum CodingKeys: String, OrderedEnumCodingKey {
                case name
                case age
                case foo
            }
        }
        """,
        macros: macros,
        indentationWidth: .spaces(4)
        )
    }
    
    func testExpansionStructWithType() {
        assertMacroExpansion(
        """
        @Serializable
        @SerialName("boss")
        struct Boss : Person {
            let name: String
            let age: Int
        }
        """,
        expandedSource: """
        struct Boss : Person {
            let name: String
            let age: Int
        
            let typeName: String = "boss"
        
            enum CodingKeys: String, OrderedEnumCodingKey {
                case name
                case age
                case typeName = "type"
            }
        }
        
        extension Boss: Codable {
        }
        """,
        macros: macros,
        indentationWidth: .spaces(4)
        )
    }
    
    func testExpansionNonFinalClassWithType() {
        assertMacroExpansion(
        """
        @Serializable
        @SerialName("boss")
        class Boss : Person {
            let name: String
            let age: Int
        }
        """,
        expandedSource: """
        class Boss : Person {
            let name: String
            let age: Int
        }
        """,
        diagnostics: [.init(message: """
        invalidPolymorphicType("The @SerialName macro can only be used with structs and final classes")
        """, line: 1, column: 1)],
        macros: macros,
        indentationWidth: .spaces(4)
        )
    }
    
    func testExpansionFinalClassWithType() {
        assertMacroExpansion(
        """
        @Serializable(subclassIndex: 3)
        @SerialName("boss")
        final class Boss : Person {
            let name: String
            let age: Int
        }
        """,
        expandedSource: """
        final class Boss : Person {
            let name: String
            let age: Int
        
            required init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                self.name = try container.decode(String.self, forKey: .name)
                self.age = try container.decode(Int.self, forKey: .age)
                try super.init(from: decoder)
            }
        
            let typeName: String = "boss"
        
            enum CodingKeys: String, OrderedEnumCodingKey, OpenOrderedCodingKey {
                case name
                case age
                case typeName = "type"
        
                var relativeIndex: Int {
                    return 3
                }
            }
        
            override func encode(to encoder: Encoder) throws {
                try super.encode(to: encoder)
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(self.typeName, forKey: .typeName)
                try container.encode(self.name, forKey: .name)
                try container.encode(self.age, forKey: .age)
            }
        }
        """,
        macros: macros,
        indentationWidth: .spaces(4)
        )
    }
    
    func testExpansionNullablePolymorphicValue() {
        assertMacroExpansion(
        """
        @Serializable
        struct Person : Codable {
            let name: String
            let age: Int
            @Polymorphic var hulu: Fish?
        }
        """,
        expandedSource: """
        struct Person : Codable {
            let name: String
            let age: Int
            var hulu: Fish?
        
            init(name: String, age: Int, hulu: Fish? = nil) {
                self.name = name
                self.age = age
                self.hulu = hulu
            }
        
            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                self.name = try container.decode(String.self, forKey: .name)
                self.age = try container.decode(Int.self, forKey: .age)
                if container.contains(.hulu) {
                    let nestedDecoder = try container.superDecoder(forKey: .hulu)
                    self.hulu = try decoder.serializationFactory.decodePolymorphicObject(Fish.self, from: nestedDecoder)
                }
            }
        
            enum CodingKeys: String, OrderedEnumCodingKey {
                case name
                case age
                case hulu
            }
        
            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(self.name, forKey: .name)
                try container.encode(self.age, forKey: .age)
                if let obj = self.hulu {
                    var nestedEncoder = container.superEncoder(forKey: .hulu)
                    try nestedEncoder.encodePolymorphic(obj)
                }
            }
        }
        """,
        macros: macros,
        indentationWidth: .spaces(4)
        )
    }
    
    func testExpansionNonnullPolymorphicValue() {
        assertMacroExpansion(
        """
        @Serializable
        struct Person : Codable {
            let name: String
            let age: Int
            @Polymorphic let hulu: Fish
        }
        """,
        expandedSource: """
        struct Person : Codable {
            let name: String
            let age: Int
            let hulu: Fish
        
            init(name: String, age: Int, hulu: Fish) {
                self.name = name
                self.age = age
                self.hulu = hulu
            }
        
            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                self.name = try container.decode(String.self, forKey: .name)
                self.age = try container.decode(Int.self, forKey: .age)
                let huluDecoder = try container.superDecoder(forKey: .hulu)
                self.hulu = try decoder.serializationFactory.decodePolymorphicObject(Fish.self, from: huluDecoder)
            }
        
            enum CodingKeys: String, OrderedEnumCodingKey {
                case name
                case age
                case hulu
            }
        
            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(self.name, forKey: .name)
                try container.encode(self.age, forKey: .age)
                var huluEncoder = container.superEncoder(forKey: .hulu)
                try huluEncoder.encodePolymorphic(self.hulu)
            }
        }
        """,
        macros: macros,
        indentationWidth: .spaces(4)
        )
    }
    
    func testExpansionDefaultPolymorphicValue() {
        assertMacroExpansion(
        """
        @Serializable
        struct Person : Codable {
            let name: String
            let age: Int
            @Polymorphic let hulu: Fish = Salmon()
        }
        """,
        expandedSource: """
        struct Person : Codable {
            let name: String
            let age: Int
            let hulu: Fish = Salmon()
        
            init(name: String, age: Int, hulu: Fish = Salmon()) {
                self.name = name
                self.age = age
                self.hulu = hulu
            }
        
            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                self.name = try container.decode(String.self, forKey: .name)
                self.age = try container.decode(Int.self, forKey: .age)
                if container.contains(.hulu) {
                    let nestedDecoder = try container.superDecoder(forKey: .hulu)
                    self.hulu = try decoder.serializationFactory.decodePolymorphicObject(Fish.self, from: nestedDecoder)
                } else {
                    self.hulu = Salmon()
                }
            }
        
            enum CodingKeys: String, OrderedEnumCodingKey {
                case name
                case age
                case hulu
            }
        
            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(self.name, forKey: .name)
                try container.encode(self.age, forKey: .age)
                var huluEncoder = container.superEncoder(forKey: .hulu)
                try huluEncoder.encodePolymorphic(self.hulu)
            }
        }
        """,
        macros: macros,
        indentationWidth: .spaces(4)
        )
    }
    
    func testExpansionNullablePolymorphicArray() {
        assertMacroExpansion(
        """
        @Serializable
        struct Person : Codable {
            let name: String
            let age: Int
            @Polymorphic var hulu: [Fish]?
        }
        """,
        expandedSource: """
        struct Person : Codable {
            let name: String
            let age: Int
            var hulu: [Fish]?
        
            init(name: String, age: Int, hulu: [Fish]? = nil) {
                self.name = name
                self.age = age
                self.hulu = hulu
            }
        
            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                self.name = try container.decode(String.self, forKey: .name)
                self.age = try container.decode(Int.self, forKey: .age)
                if container.contains(.hulu) {
                    let nestedDecoder = try container.nestedUnkeyedContainer(forKey: .hulu)
                    self.hulu = try decoder.serializationFactory.decodePolymorphicArray(Fish.self, from: nestedDecoder)
                }
            }
        
            enum CodingKeys: String, OrderedEnumCodingKey {
                case name
                case age
                case hulu
            }
        
            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(self.name, forKey: .name)
                try container.encode(self.age, forKey: .age)
                if let obj = self.hulu {
                    var nestedEncoder = container.nestedUnkeyedContainer(forKey: .hulu)
                    try nestedEncoder.encodePolymorphic(obj)
                }
            }
        }
        """,
        macros: macros,
        indentationWidth: .spaces(4)
        )
    }
    
    func testExpansionNonnullPolymorphicArray() {
        assertMacroExpansion(
        """
        @Serializable
        struct Person : Codable {
            let name: String
            let age: Int
            @Polymorphic let hulu: [Fish]
        }
        """,
        expandedSource: """
        struct Person : Codable {
            let name: String
            let age: Int
            let hulu: [Fish]
        
            init(name: String, age: Int, hulu: [Fish]) {
                self.name = name
                self.age = age
                self.hulu = hulu
            }
        
            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                self.name = try container.decode(String.self, forKey: .name)
                self.age = try container.decode(Int.self, forKey: .age)
                let huluDecoder = try container.nestedUnkeyedContainer(forKey: .hulu)
                self.hulu = try decoder.serializationFactory.decodePolymorphicArray(Fish.self, from: huluDecoder)
            }
        
            enum CodingKeys: String, OrderedEnumCodingKey {
                case name
                case age
                case hulu
            }
        
            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(self.name, forKey: .name)
                try container.encode(self.age, forKey: .age)
                var huluEncoder = container.nestedUnkeyedContainer(forKey: .hulu)
                try huluEncoder.encodePolymorphic(self.hulu)
            }
        }
        """,
        macros: macros,
        indentationWidth: .spaces(4)
        )
    }
    
    func testExpansionDefaultPolymorphicArray() {
        assertMacroExpansion(
        """
        @Serializable
        struct Person : Codable {
            let name: String
            let age: Int
            @Polymorphic var hulu: [Fish] = []
        }
        """,
        expandedSource: """
        struct Person : Codable {
            let name: String
            let age: Int
            var hulu: [Fish] = []
        
            init(name: String, age: Int, hulu: [Fish] = []) {
                self.name = name
                self.age = age
                self.hulu = hulu
            }
        
            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                self.name = try container.decode(String.self, forKey: .name)
                self.age = try container.decode(Int.self, forKey: .age)
                if container.contains(.hulu) {
                    let nestedDecoder = try container.nestedUnkeyedContainer(forKey: .hulu)
                    self.hulu = try decoder.serializationFactory.decodePolymorphicArray(Fish.self, from: nestedDecoder)
                } else {
                    self.hulu = []
                }
            }
        
            enum CodingKeys: String, OrderedEnumCodingKey {
                case name
                case age
                case hulu
            }
        
            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(self.name, forKey: .name)
                try container.encode(self.age, forKey: .age)
                var huluEncoder = container.nestedUnkeyedContainer(forKey: .hulu)
                try huluEncoder.encodePolymorphic(self.hulu)
            }
        }
        """,
        macros: macros,
        indentationWidth: .spaces(4)
        )
    }
}

