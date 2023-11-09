import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import SerializableMacros

let macros: [String: Macro.Type] = [
    "Serializable": SerializableMacro.self,
    "SerialName": SerialNameMacro.self,
    "Transient": TransientMacro.self,
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
}

