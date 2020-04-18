//
//  JsonSchemaTests.swift
//
//
//  Copyright © 2020 Sage Bionetworks. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
// 1.  Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
//
// 2.  Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation and/or
// other materials provided with the distribution.
//
// 3.  Neither the name of the copyright holder(s) nor the names of any contributors
// may be used to endorse or promote products derived from this software without
// specific prior written permission. No license is granted to the trademarks of
// the copyright holders even if such marks are included in this software.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

import XCTest
@testable import JsonModel

final class JsonSchemaTests: XCTestCase {

    func testJsonSchemaPrimitive_IntDefault() {
        let json = """
        {
            "type": "integer",
            "default": 4,
            "description": "An integer value"
        }
        """.data(using: .utf8)! // our data in native (JSON) format
        
        let original = JsonSchemaPrimitive(defaultValue: .integer(4),
                                           description: "An integer value")
        
        let decoder = SerializationFactory.defaultFactory.createJSONDecoder()
        let encoder = SerializationFactory.defaultFactory.createJSONEncoder()
        
        do {
            let decodedObject = try decoder.decode(JsonSchemaPrimitive.self, from: json)
            let decodedProperty = try decoder.decode(JsonSchemaProperty.self, from: json)
            let decodedArrayElement = try decoder.decode(JsonSchemaElement.self, from: json)
            
            XCTAssertEqual(original, decodedObject)
            XCTAssertEqual(JsonSchemaProperty.primitive(original), decodedProperty)
            XCTAssertEqual(JsonSchemaElement.primitive(original), decodedArrayElement)
            
            let encodedData = try encoder.encode(original)
            let encodedJson = try JSONSerialization.jsonObject(with: encodedData, options: [])
            let originalJson = try JSONSerialization.jsonObject(with: json, options: [])
            
            guard let expected = originalJson as? NSDictionary,
                let actual = encodedJson as? NSDictionary else {
                    XCTFail("\(originalJson) or \(encodedJson) not of expected type")
                    return
            }

            XCTAssertEqual(expected, actual)

        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
        }
    }
    
    func testJsonSchemaPrimitive_String() {
        let json = """
        {
            "type": "string"
        }
        """.data(using: .utf8)! // our data in native (JSON) format
        
        let original = JsonSchemaPrimitive.string
        
        let decoder = SerializationFactory.defaultFactory.createJSONDecoder()
        let encoder = SerializationFactory.defaultFactory.createJSONEncoder()
        
        do {
            let decodedObject = try decoder.decode(JsonSchemaPrimitive.self, from: json)
            let decodedProperty = try decoder.decode(JsonSchemaProperty.self, from: json)
            let decodedArrayElement = try decoder.decode(JsonSchemaElement.self, from: json)
            
            XCTAssertEqual(original, decodedObject)
            XCTAssertEqual(JsonSchemaProperty.primitive(original), decodedProperty)
            XCTAssertEqual(JsonSchemaElement.primitive(original), decodedArrayElement)
            
            let encodedData = try encoder.encode(original)
            let encodedJson = try JSONSerialization.jsonObject(with: encodedData, options: [])
            let originalJson = try JSONSerialization.jsonObject(with: json, options: [])
            
            guard let expected = originalJson as? NSDictionary,
                let actual = encodedJson as? NSDictionary else {
                    XCTFail("\(originalJson) or \(encodedJson) not of expected type")
                    return
            }

            XCTAssertEqual(expected, actual)

        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
        }
    }
    
    func testJsonSchemaObjectRef() {
        let json = """
        {
            "$ref": "#FooClass"
        }
        """.data(using: .utf8)! // our data in native (JSON) format
        
        let original = JsonSchemaObjectRef(ref: JsonSchemaReferenceId("FooClass"))
        
        let decoder = SerializationFactory.defaultFactory.createJSONDecoder()
        let encoder = SerializationFactory.defaultFactory.createJSONEncoder()
        
        do {
            let decodedObject = try decoder.decode(JsonSchemaObjectRef.self, from: json)
            let decodedProperty = try decoder.decode(JsonSchemaProperty.self, from: json)
            let decodedArrayElement = try decoder.decode(JsonSchemaElement.self, from: json)
            
            XCTAssertEqual(original, decodedObject)
            XCTAssertEqual(JsonSchemaProperty.reference(original), decodedProperty)
            XCTAssertEqual(JsonSchemaElement.reference(original), decodedArrayElement)
            
            let encodedData = try encoder.encode(original)
            let encodedJson = try JSONSerialization.jsonObject(with: encodedData, options: [])
            let originalJson = try JSONSerialization.jsonObject(with: json, options: [])
            
            guard let expected = originalJson as? NSDictionary,
                let actual = encodedJson as? NSDictionary else {
                    XCTFail("\(originalJson) or \(encodedJson) not of expected type")
                    return
            }

            XCTAssertEqual(expected, actual)

        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
        }
    }
    
    func testJsonSchemaArray_Ref() {
        let json = """
        {
            "type": "array",
            "items": { "$ref": "#FooClass" },
            "description": "Test of a reference array"
        }
        """.data(using: .utf8)! // our data in native (JSON) format
        
        let items = JsonSchemaObjectRef(ref: JsonSchemaReferenceId("FooClass"))
        let original = JsonSchemaArray(items: .reference(items),
                                       description: "Test of a reference array")
        
        let decoder = SerializationFactory.defaultFactory.createJSONDecoder()
        let encoder = SerializationFactory.defaultFactory.createJSONEncoder()
        
        do {
            let decodedObject = try decoder.decode(JsonSchemaArray.self, from: json)
            let decodedProperty = try decoder.decode(JsonSchemaProperty.self, from: json)
            
            XCTAssertEqual(original, decodedObject)
            XCTAssertEqual(JsonSchemaProperty.array(original), decodedProperty)
            
            let encodedData = try encoder.encode(original)
            let encodedJson = try JSONSerialization.jsonObject(with: encodedData, options: [])
            let originalJson = try JSONSerialization.jsonObject(with: json, options: [])
            
            guard let expected = originalJson as? NSDictionary,
                let actual = encodedJson as? NSDictionary else {
                    XCTFail("\(originalJson) or \(encodedJson) not of expected type")
                    return
            }

            XCTAssertEqual(expected, actual)

        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
        }
    }
    
    func testJsonSchemaArray_Primitive() {
        let json = """
        {
            "type": "array",
            "items": { "type": "boolean" },
            "description": "Test of a reference array"
        }
        """.data(using: .utf8)! // our data in native (JSON) format
        
        let original = JsonSchemaArray(items: .primitive(JsonSchemaPrimitive(jsonType: .boolean)),
                                       description: "Test of a reference array")
        
        let decoder = SerializationFactory.defaultFactory.createJSONDecoder()
        let encoder = SerializationFactory.defaultFactory.createJSONEncoder()
        
        do {
            let decodedObject = try decoder.decode(JsonSchemaArray.self, from: json)
            let decodedProperty = try decoder.decode(JsonSchemaProperty.self, from: json)
            
            XCTAssertEqual(original, decodedObject)
            XCTAssertEqual(JsonSchemaProperty.array(original), decodedProperty)
            
            let encodedData = try encoder.encode(original)
            let encodedJson = try JSONSerialization.jsonObject(with: encodedData, options: [])
            let originalJson = try JSONSerialization.jsonObject(with: json, options: [])
            
            guard let expected = originalJson as? NSDictionary,
                let actual = encodedJson as? NSDictionary else {
                    XCTFail("\(originalJson) or \(encodedJson) not of expected type")
                    return
            }

            XCTAssertEqual(expected, actual)

        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
        }
    }
    
    func testJsonSchemaTypedDictionary_Ref() {
        let json = """
        {
            "type": "object",
            "additionalProperties": { "$ref": "#FooClass" },
            "description": "Test of a typed dictionary"
        }
        """.data(using: .utf8)! // our data in native (JSON) format
        
        let items = JsonSchemaObjectRef(ref: JsonSchemaReferenceId("FooClass"))
        let original = JsonSchemaTypedDictionary(items: .reference(items),
                                                 description: "Test of a typed dictionary")
        
        let decoder = SerializationFactory.defaultFactory.createJSONDecoder()
        let encoder = SerializationFactory.defaultFactory.createJSONEncoder()
        
        do {
            let decodedObject = try decoder.decode(JsonSchemaTypedDictionary.self, from: json)
            let decodedProperty = try decoder.decode(JsonSchemaProperty.self, from: json)
            
            XCTAssertEqual(original, decodedObject)
            XCTAssertEqual(JsonSchemaProperty.dictionary(original), decodedProperty)
            
            let encodedData = try encoder.encode(original)
            let encodedJson = try JSONSerialization.jsonObject(with: encodedData, options: [])
            let originalJson = try JSONSerialization.jsonObject(with: json, options: [])
            
            guard let expected = originalJson as? NSDictionary,
                let actual = encodedJson as? NSDictionary else {
                    XCTFail("\(originalJson) or \(encodedJson) not of expected type")
                    return
            }

            XCTAssertEqual(expected, actual)

        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
        }
    }
    
    func testJsonSchemaTypedDictionary_Primitive() {
        let json = """
        {
            "type": "object",
            "additionalProperties": { "type": "boolean" },
            "description": "Test of a typed dictionary"
        }
        """.data(using: .utf8)! // our data in native (JSON) format
        
        let original = JsonSchemaTypedDictionary(items: .primitive(JsonSchemaPrimitive(jsonType: .boolean)),
                                                 description: "Test of a typed dictionary")
        
        let decoder = SerializationFactory.defaultFactory.createJSONDecoder()
        let encoder = SerializationFactory.defaultFactory.createJSONEncoder()
        
        do {
            let decodedObject = try decoder.decode(JsonSchemaTypedDictionary.self, from: json)
            let decodedProperty = try decoder.decode(JsonSchemaProperty.self, from: json)
            
            XCTAssertEqual(original, decodedObject)
            XCTAssertEqual(JsonSchemaProperty.dictionary(original), decodedProperty)
            
            let encodedData = try encoder.encode(original)
            let encodedJson = try JSONSerialization.jsonObject(with: encodedData, options: [])
            let originalJson = try JSONSerialization.jsonObject(with: json, options: [])
            
            guard let expected = originalJson as? NSDictionary,
                let actual = encodedJson as? NSDictionary else {
                    XCTFail("\(originalJson) or \(encodedJson) not of expected type")
                    return
            }

            XCTAssertEqual(expected, actual)

        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
        }
    }
    
    func testJsonSchemaConst() {
        let json = """
        {
            "$ref": "#FooType",
            "const": "boo"
        }
        """.data(using: .utf8)! // our data in native (JSON) format
        
        let original = JsonSchemaConst(const: "boo", ref: JsonSchemaReferenceId("FooType"))
        
        let decoder = SerializationFactory.defaultFactory.createJSONDecoder()
        let encoder = SerializationFactory.defaultFactory.createJSONEncoder()
        
        do {
            let decodedObject = try decoder.decode(JsonSchemaConst.self, from: json)
            let decodedProperty = try decoder.decode(JsonSchemaProperty.self, from: json)
            
            XCTAssertEqual(original, decodedObject)
            XCTAssertEqual(JsonSchemaProperty.const(original), decodedProperty)
            
            let encodedData = try encoder.encode(original)
            let encodedJson = try JSONSerialization.jsonObject(with: encodedData, options: [])
            let originalJson = try JSONSerialization.jsonObject(with: json, options: [])
            
            guard let expected = originalJson as? NSDictionary,
                let actual = encodedJson as? NSDictionary else {
                    XCTFail("\(originalJson) or \(encodedJson) not of expected type")
                    return
            }

            XCTAssertEqual(expected, actual)

        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
        }
    }
    
    func testJsonSchemaStringEnum() {
        let json = """
        {
         "$id": "#Color",
         "title": "Color",
         "type": "string",
         "enum": ["red","green","blue"],
         "description": "These are primary colors"
        }
        """.data(using: .utf8)! // our data in native (JSON) format

        let original = JsonSchemaStringEnum(id: JsonSchemaReferenceId("Color"),
                                            values: ["red","green","blue"],
                                            description: "These are primary colors")
         
        let decoder = SerializationFactory.defaultFactory.createJSONDecoder()
        let encoder = SerializationFactory.defaultFactory.createJSONEncoder()

        do {
            let decodedObject = try decoder.decode(JsonSchemaStringEnum.self, from: json)
            let decodedDefinition = try decoder.decode(JsonSchemaDefinition.self, from: json)

            XCTAssertEqual(original, decodedObject)
            XCTAssertEqual(JsonSchemaDefinition.stringEnum(original), decodedDefinition)

            let encodedData = try encoder.encode(original)
            let encodedJson = try JSONSerialization.jsonObject(with: encodedData, options: [])
            let originalJson = try JSONSerialization.jsonObject(with: json, options: [])

            guard let expected = originalJson as? NSDictionary,
                let actual = encodedJson as? NSDictionary else {
                 XCTFail("\(originalJson) or \(encodedJson) not of expected type")
                 return
            }

            XCTAssertEqual(expected, actual)

        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
        }
    }
    
    func testJsonSchemaStringLiteral() {
        let json = """
        {
         "$id": "#Color",
         "title": "Color",
         "type": "string",
         "description": "This is a freeform string liternal for color names"
        }
        """.data(using: .utf8)! // our data in native (JSON) format

        let original = JsonSchemaStringLiteral(id: JsonSchemaReferenceId("Color"),
                                               description: "This is a freeform string liternal for color names")
         
        let decoder = SerializationFactory.defaultFactory.createJSONDecoder()
        let encoder = SerializationFactory.defaultFactory.createJSONEncoder()

        do {
            let decodedObject = try decoder.decode(JsonSchemaStringLiteral.self, from: json)
            let decodedDefinition = try decoder.decode(JsonSchemaDefinition.self, from: json)

            XCTAssertEqual(original, decodedObject)
            XCTAssertEqual(JsonSchemaDefinition.stringLiteral(original), decodedDefinition)

            let encodedData = try encoder.encode(original)
            let encodedJson = try JSONSerialization.jsonObject(with: encodedData, options: [])
            let originalJson = try JSONSerialization.jsonObject(with: json, options: [])

            guard let expected = originalJson as? NSDictionary,
                let actual = encodedJson as? NSDictionary else {
                 XCTFail("\(originalJson) or \(encodedJson) not of expected type")
                 return
            }

            XCTAssertEqual(expected, actual)

        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
        }
    }
    
    func testJsonSchemaObject() {
        let json = """
        {
            "$id": "#Foo",
            "type": "object",
            "title":"Foo",
            "description": "This is an example of a polymorphic object",
            "properties": {
                "type": {
                    "$ref": "#GooType",
                    "const": "foo"
                },
                "identifier": {
                    "type": "string"
                },
                "baloo": {
                    "$ref": "#Baloo"
                },
                "luckyNumbers": {
                    "type": "array",
                    "items": {
                        "type": "integer"
                    }
                }
            },
            "additionalProperties": false,
            "required": ["type", "identifier"],
            "allOf": [{ "$ref": "#Goo" }],
            "examples": [{
                "type": "foo",
                "identifier": "boo"
            }]
        }
        """.data(using: .utf8)! // our data in native (JSON) format

        let original = JsonSchemaObject(id: JsonSchemaReferenceId("Foo"),
                                        properties: [
                                            "type" : .const(JsonSchemaConst(const: "foo", ref: JsonSchemaReferenceId("GooType"))),
                                            "identifier" : .primitive(.string),
                                            "baloo" : .reference(JsonSchemaObjectRef(ref: JsonSchemaReferenceId("Baloo"))),
                                            "luckyNumbers" : .array(JsonSchemaArray(items: .primitive(.integer)))],
                                        required: ["type", "identifier"],
                                        isOpen: false,
                                        description: "This is an example of a polymorphic object",
                                        interfaces: [JsonSchemaReferenceId("Goo")],
                                        examples: [["type":"foo","identifier":"boo"]])
        
        let decoder = SerializationFactory.defaultFactory.createJSONDecoder()
        let encoder = SerializationFactory.defaultFactory.createJSONEncoder()

        do {
            let decodedObject = try decoder.decode(JsonSchemaObject.self, from: json)
            let decodedDefinition = try decoder.decode(JsonSchemaDefinition.self, from: json)

            XCTAssertEqual(original, decodedObject)
            XCTAssertEqual(JsonSchemaDefinition.object(original), decodedDefinition)

            let encodedData = try encoder.encode(original)
            let encodedJson = try JSONSerialization.jsonObject(with: encodedData, options: [])
            let originalJson = try JSONSerialization.jsonObject(with: json, options: [])

            guard let expected = originalJson as? NSDictionary,
                let actual = encodedJson as? NSDictionary else {
                 XCTFail("\(originalJson) or \(encodedJson) not of expected type")
                 return
            }

            XCTAssertEqual(expected, actual)

        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
        }
    }
    
    func testJsonSchemaRootElement() {
        let json = """
        {
            "$schema": "http://json-schema.org/draft-07/schema#",
            "$id": "http://sagebionetworks.org/Foo.json",
            "type": "object",
            "title": "Foo",
            "description": "This is an example of a polymorphic object",
            "definitions": {
                "Goo": {
                    "type": "object",
                    "$id": "#Goo",
                    "title": "Goo",
                    "description": ""
                },
                "Baloo": {
                    "type": "object",
                    "$id": "#Baloo",
                    "title": "Baloo",
                    "description": "",
                    "additionalProperties": false,
                    "properties": {
                        "value": {
                            "type": "string"
                        }
                    }
                },
                "GooType": {
                    "$id": "#GooType",
                    "title": "GooType",
                    "type": "string",
                    "description": ""
                },
                "RuType": {
                    "$id": "#RuType",
                    "title": "RuType",
                    "type": "string",
                    "description": "",
                    "enum": ["moo", "loo", "twentyToo"]
                }
            },
            "properties": {
                "type": {
                    "$ref": "#GooType",
                    "const": "foo"
                },
                "identifier": {
                    "type": "string"
                },
                "baloo": {
                    "$ref": "#Baloo"
                },
                "ruType": {
                    "$ref": "#RuType"
                }
            },
            "required": ["type", "identifier"],
            "allOf": [
                { "$ref": "#Goo" },
                { "$ref": "Moo.json" }],
            "examples": [{
                "type": "foo",
                "identifier": "boo"
            }]
        }
        """.data(using: .utf8)! // our data in native (JSON) format

        let origDefinitions: [JsonSchemaDefinition] = [
        .object(JsonSchemaObject(id: JsonSchemaReferenceId("Baloo"), properties: ["value": .primitive(.string)])),
        .stringLiteral(JsonSchemaStringLiteral(id: JsonSchemaReferenceId("GooType"))),
        .stringEnum(JsonSchemaStringEnum(id: JsonSchemaReferenceId("RuType"), values: ["moo", "loo", "twentyToo"]))]

        let original = JsonSchema(id: URL(string: "http://sagebionetworks.org/Foo.json")!,
                                  description: "This is an example of a polymorphic object",
                                  isOpen: true,
                                  interfaces: [JsonSchemaReferenceId("Goo"),
                                               JsonSchemaReferenceId("Moo", isExternal: true)],
                                  definitions: origDefinitions,
                                  properties:[
                                    "type": .const(JsonSchemaConst(const: "foo", ref: JsonSchemaReferenceId("GooType"))),
                                    "identifier": .primitive(.string),
                                    "baloo": .reference(JsonSchemaObjectRef(ref: JsonSchemaReferenceId("Baloo"))),
                                    "ruType": .reference(JsonSchemaObjectRef(ref: JsonSchemaReferenceId("RuType")))],
                                  required: ["type", "identifier"],
                                  examples: [["type": "foo","identifier": "boo"]])

        let decoder = SerializationFactory.defaultFactory.createJSONDecoder()
        let encoder = SerializationFactory.defaultFactory.createJSONEncoder()

        do {
            let decodedObject = try decoder.decode(JsonSchema.self, from: json)

            XCTAssertEqual(original, decodedObject)
            
            XCTAssertEqual(original.schema, decodedObject.schema)
            XCTAssertEqual(original.id, decodedObject.id)
            XCTAssertEqual(original.title, decodedObject.title)
            XCTAssertEqual(original.description, decodedObject.description)
            XCTAssertEqual(original.definitions, decodedObject.definitions)
            XCTAssertEqual(original.allOf, decodedObject.allOf)
            XCTAssertEqual(original.isOpen, decodedObject.isOpen)
            XCTAssertEqual(original.examples, decodedObject.examples)
            XCTAssertEqual(original.properties, decodedObject.properties)
            XCTAssertEqual(original.required, decodedObject.required)
           
            origDefinitions.forEach { definition in
                guard let className = definition.className else {
                    XCTFail("\(definition) has a nil class name")
                    return
                }
                guard let decodedDef = decodedObject.definitions?[className] else {
                    XCTFail("\(className) has a nil definition")
                    return
                }
                XCTAssertEqual(definition, decodedDef)
            }

            let encodedData = try encoder.encode(original)
            let encodedJson = try JSONSerialization.jsonObject(with: encodedData, options: [])
            let originalJson = try JSONSerialization.jsonObject(with: json, options: [])

            guard let expected = originalJson as? NSDictionary,
                let actual = encodedJson as? NSDictionary else {
                 XCTFail("\(originalJson) or \(encodedJson) not of expected type")
                 return
            }

            XCTAssertEqual(expected, actual)

        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
        }
    }
}
