import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import SerializableMacros

let macros = [
    "Serializable": SerializableMacro.self,
]

final class SerializableTests: XCTestCase {
    
    func testExpansionAddsDefaultCodingKeys() {
        assertMacroExpansion(
        """
        @Serializable
        struct Person {
            let name: String
            let age: Int
        }
        """,
        expandedSource: """
          struct Person {
              let name: String
              let age: Int

              enum CodingKeys: String, OrderedEnumCodingKey {
                  case name
                  case age
              }
          }
          
          extension Person: Codable {
          }
          """,
        macros: macros,
        indentationWidth: .spaces(4)
        )
    }

    func testExpansionWithCodableKeyAddsCustomCodingKeys() {
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
              @SerialName("user_age") let age: Int

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
              @Transient var foo: String? = nil

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
              @Transient
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
}
