//
//  JsonSchemaTests.swift
//
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
            "$ref": "#/definitions/FooClass"
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
            "items": { "$ref": "#/definitions/FooClass" },
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
            "additionalProperties": { "$ref": "#/definitions/FooClass" },
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
                    "const": "foo"
                },
                "identifier": {
                    "type": "string"
                },
                "baloo": {
                    "$ref": "Boo.json#Baloo"
                },
                "luckyNumbers": {
                    "type": "array",
                    "items": {
                        "type": "integer"
                    }
                }
            },
            "required": ["type", "identifier"],
            "allOf": [{ "$ref": "#/definitions/Goo" }],
            "examples": [{
                "type": "foo",
                "identifier": "boo"
            }]
        }
        """.data(using: .utf8)! // our data in native (JSON) format

        let orderedKeys = ["type", "identifier", "baloo", "luckyNumbers"]
        let codingKeys: [AnyCodingKey] = orderedKeys.enumerated().map {
            .init(stringValue: $0.element, intValue: $0.offset)
        }
        let original = JsonSchemaObject(id: JsonSchemaReferenceId("Foo"),
                                        description: "This is an example of a polymorphic object",
                                        codingKeys: codingKeys,
                                        properties: [
                                            "type" : .const(JsonSchemaConst(const: "foo", ref: JsonSchemaReferenceId("GooType"))),
                                            "identifier" : .primitive(.string),
                                            "baloo" : .reference(JsonSchemaObjectRef(ref: JsonSchemaReferenceId("Baloo", root: .init("Boo", isExternal: true)))),
                                            "luckyNumbers" : .array(JsonSchemaArray(items: .primitive(.integer)))],
                                        required: ["type", "identifier"],
                                        interfaces: [.init(ref: JsonSchemaReferenceId("Goo"))],
                                        examples: [["type":"foo","identifier":"boo"]])
        
        let decoder = SerializationFactory.defaultFactory.createJSONDecoder()
        let encoder = SerializationFactory.defaultFactory.createJSONEncoder()

        do {
            let decodedObject = try decoder.decode(JsonSchemaObject.self, from: json)
            XCTAssertEqual(original, decodedObject)
            
            XCTAssertEqual(original.id, decodedObject.id)
            XCTAssertEqual(original.title, decodedObject.title)
            XCTAssertEqual(original.className, decodedObject.className)
            XCTAssertEqual(original.jsonType, decodedObject.jsonType)
            XCTAssertEqual(original.description, decodedObject.description)
            XCTAssertEqual(original.allOf, decodedObject.allOf)
            XCTAssertEqual(original.properties, decodedObject.properties)
            if let originalBaloo = original.properties?["baloo"],
               case .reference(let ogBaloo) = originalBaloo,
               let decodedBaloo = decodedObject.properties?["baloo"],
               case .reference(let newBaloo) = decodedBaloo {
                XCTAssertEqual(ogBaloo.refId, newBaloo.refId)
                print(ogBaloo)
            }
            else {
                XCTFail("Failed to decode the 'baloo' property")
            }
            
            XCTAssertEqual(original.required, decodedObject.required)
            XCTAssertEqual(original.examples, decodedObject.examples)
            XCTAssertEqual(original.additionalProperties, decodedObject.additionalProperties)
            
            let decodedDefinition = try decoder.decode(JsonSchemaDefinition.self, from: json)
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
    
    func testJsonSchemaRootElement_object() {
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
                    "const": "foo"
                },
                "identifier": {
                    "type": "string"
                },
                "baloo": {
                    "$ref": "#/definitions/Baloo"
                },
                "ruType": {
                    "$ref": "#/definitions/RuType"
                }
            },
            "required": ["type", "identifier"],
            "allOf": [
                { "$ref": "#/definitions/Goo" },
                { "$ref": "Moo.json" }
            ],
            "examples": [{
                "type": "foo",
                "identifier": "boo"
            }]
        }
        """.data(using: .utf8)! // our data in native (JSON) format

        let origObjectDef: JsonSchemaDefinition = .object(JsonSchemaObject(id: JsonSchemaReferenceId("Baloo"), additionalProperties: false, properties: ["value": .primitive(.string)]))
        let origDefinitions: [JsonSchemaDefinition] = [
            origObjectDef,
            .stringLiteral(JsonSchemaStringLiteral(id: JsonSchemaReferenceId("GooType"))),
            .stringEnum(JsonSchemaStringEnum(id: JsonSchemaReferenceId("RuType"), values: ["moo", "loo", "twentyToo"]))]

        let codingKeys: [AnyCodingKey] = ["type","identifier","baloo","ruType"].enumerated().map {
            .init(stringValue: $0.element, intValue: $0.offset)
        }
        let original = JsonSchema(id: URL(string: "http://sagebionetworks.org/Foo.json")!,
                                  description: "This is an example of a polymorphic object",
                                  isArray: false,
                                  codingKeys: codingKeys,
                                  interfaces: [.init(ref: JsonSchemaReferenceId("Goo")),
                                               .init(ref: JsonSchemaReferenceId("Moo", isExternal: true))],
                                  definitions: origDefinitions,
                                  properties: [
                                        "type": .const(JsonSchemaConst(const: "foo", ref: JsonSchemaReferenceId("GooType"))),
                                        "identifier": .primitive(.string),
                                        "baloo": .reference(JsonSchemaObjectRef(ref: JsonSchemaReferenceId("Baloo"))),
                                        "ruType": .reference(JsonSchemaObjectRef(ref: JsonSchemaReferenceId("RuType")))
                                  ],
                                  required: ["type", "identifier"],
                                  examples:  [["type": "foo","identifier": "boo"]])

        let decoder = SerializationFactory.defaultFactory.createJSONDecoder()
        let encoder = SerializationFactory.defaultFactory.createJSONEncoder()

        do {
            let decodedObject = try decoder.decode(JsonSchema.self, from: json)

            XCTAssertEqual(original, decodedObject)

            XCTAssertEqual(original.id, decodedObject.id)
            XCTAssertEqual(original.schema, decodedObject.schema)
            XCTAssertEqual(original.definitions, decodedObject.definitions)
            XCTAssertEqual(original.jsonType, decodedObject.jsonType)
            XCTAssertEqual(.object, original.jsonType)
            XCTAssertEqual(original.root, decodedObject.root)
            
            XCTAssertEqual(original.root.id, decodedObject.root.id)
            XCTAssertEqual(original.root.title, decodedObject.root.title)
            XCTAssertEqual(original.root.className, decodedObject.root.className)
            XCTAssertEqual(original.root.jsonType, decodedObject.root.jsonType)
            XCTAssertEqual(original.root.description, decodedObject.root.description)
            XCTAssertEqual(original.root.allOf, decodedObject.root.allOf)
            XCTAssertEqual(original.root.properties, decodedObject.root.properties)
            XCTAssertEqual(original.root.required, decodedObject.root.required)
            XCTAssertEqual(original.root.examples, decodedObject.root.examples)
            XCTAssertEqual(original.root.additionalProperties, decodedObject.root.additionalProperties)
            
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
                
                if case .object(let objDef) = definition {
                    if case .object(let decodedObjDef) = decodedDef {
                        XCTAssertEqual(objDef.className, decodedObjDef.className)
                        XCTAssertEqual(objDef.description, decodedObjDef.description)
                        XCTAssertEqual(objDef.title, decodedObjDef.title)
                        XCTAssertEqual(objDef.id, decodedObjDef.id)
                        XCTAssertEqual(objDef.required, decodedObjDef.required)
                        XCTAssertEqual(objDef.allOf, decodedObjDef.allOf)
                        XCTAssertEqual(objDef.additionalProperties, decodedObjDef.additionalProperties)
                        XCTAssertEqual(objDef.examples, decodedObjDef.examples)
                    }
                    else {
                        XCTFail("The decoded object type does not match expected")
                    }
                }
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
    
    func testJsonSchemaRootElement_array() {
        let json = """
        {
            "$schema": "http://json-schema.org/draft-07/schema#",
            "$id": "http://sagebionetworks.org/Foo.json",
            "type": "array",
            "description": "An array of `Foo` objects.",
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
            "items": {
                "type": "object",
                "title": "Foo",
                "description": "This is an example of a polymorphic object",
                "properties": {
                    "type": {
                        "const": "foo"
                    },
                    "identifier": {
                        "type": "string"
                    },
                    "baloo": {
                        "$ref": "#/definitions/Baloo"
                    },
                    "ruType": {
                        "$ref": "#/definitions/RuType"
                    }
                },
                "required": ["type", "identifier"],
                "allOf": [{
                        "$ref": "#/definitions/Goo"
                    },
                    {
                        "$ref": "Moo.json"
                    }
                ],
                "examples": [{
                    "type": "foo",
                    "identifier": "boo"
                }]
            }
        }
        """.data(using: .utf8)! // our data in native (JSON) format

        let origDefinitions: [JsonSchemaDefinition] = [
            .object(JsonSchemaObject(id: JsonSchemaReferenceId("Baloo"), additionalProperties: false, properties: ["value": .primitive(.string)])),
            .stringLiteral(JsonSchemaStringLiteral(id: JsonSchemaReferenceId("GooType"))),
            .stringEnum(JsonSchemaStringEnum(id: JsonSchemaReferenceId("RuType"), values: ["moo", "loo", "twentyToo"]))]

        let orderedKeys = ["type", "identifier", "baloo", "ruType"]
        let codingKeys: [AnyCodingKey] = orderedKeys.enumerated().map {
            .init(stringValue: $0.element, intValue: $0.offset)
        }
        let original = JsonSchema(id: URL(string: "http://sagebionetworks.org/Foo.json")!,
                                  description: "This is an example of a polymorphic object",
                                  isArray: true,
                                  codingKeys: codingKeys,
                                  interfaces: [.init(ref: JsonSchemaReferenceId("Goo")),
                                               .init(ref: JsonSchemaReferenceId("Moo", isExternal: true))],
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

            XCTAssertEqual(original.id, decodedObject.id)
            XCTAssertEqual(original.schema, decodedObject.schema)
            XCTAssertEqual(original.definitions, decodedObject.definitions)
            XCTAssertEqual(original.jsonType, decodedObject.jsonType)
            XCTAssertEqual(.array, original.jsonType)
            XCTAssertEqual(original.root, decodedObject.root)
            
            XCTAssertEqual(original.root.id, decodedObject.root.id)
            XCTAssertEqual(original.root.title, decodedObject.root.title)
            XCTAssertEqual(original.root.className, decodedObject.root.className)
            XCTAssertEqual(original.root.jsonType, decodedObject.root.jsonType)
            XCTAssertEqual(original.root.description, decodedObject.root.description)
            XCTAssertEqual(original.root.allOf, decodedObject.root.allOf)
            XCTAssertEqual(original.root.properties, decodedObject.root.properties)
            XCTAssertEqual(original.root.required, decodedObject.root.required)
            XCTAssertEqual(original.root.examples, decodedObject.root.examples)
            XCTAssertEqual(original.root.additionalProperties, decodedObject.root.additionalProperties)
            
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
