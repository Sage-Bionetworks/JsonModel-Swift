//
//  DocumentableTests.swift
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

final class DocumentableTests: XCTestCase {
    
    func testFactoryDocumentBuilder() {
        
        let factory = TestFactory.defaultFactory
        let baseUrl = URL(string: "http://sagebionetworks.org/jsonSchema/")!
        
        let doc = JsonDocumentBuilder(baseUrl: baseUrl,
                                      rootName: "Example",
                                      factory: factory)
        
        XCTAssertEqual(baseUrl, doc.baseUrl)
        XCTAssertEqual("Example", doc.rootName)
        XCTAssertEqual(["Sample"], doc.interfaces.map { $0.className })
        let objects = doc.objects.map { $0.className }
        XCTAssertEqual(["SampleType", "SampleColor", "SampleA", "SampleAnimals", "SampleB"], objects)
        
        do {
            let jsonSchema = try doc.buildSchema()
            
            XCTAssertEqual("http://sagebionetworks.org/jsonSchema/Example.json", jsonSchema.id.classPath)
            XCTAssertEqual("Example", jsonSchema.title)
            
            XCTAssertTrue(jsonSchema.isOpen)
            XCTAssertNil(jsonSchema.allOf)
            XCTAssertNil(jsonSchema.properties)
            XCTAssertNil(jsonSchema.required)
            XCTAssertNil(jsonSchema.examples)
            XCTAssertNotNil(jsonSchema.definitions)
            
            guard let definitions = jsonSchema.definitions else {
                XCTFail("Failed to build the jsonSchema definitions")
                return
            }

            XCTAssertEqual(6, definitions.count)
            
            var key: String = "Sample"
            if let def = definitions[key], case .object(let obj) = def {
                XCTAssertEqual(key, obj.id.className)
                XCTAssertEqual(key, obj.title)
                XCTAssertNil(obj.allOf)
                XCTAssertNil(obj.properties)
                XCTAssertNil(obj.required)
                XCTAssertNil(obj.examples)
                XCTAssertTrue(obj.isOpen)
            }
            else {
                XCTFail("Missing definition mapping for \(key)")
            }
            
            key = "SampleColor"
            if let def = definitions[key], case .stringEnum(let obj) = def {
                XCTAssertEqual(key, obj.id.className)
                XCTAssertEqual(key, obj.title)
                XCTAssertEqual(["red", "yellow", "blue"], obj.values)
            }
            else {
                XCTFail("Missing definition mapping for \(key)")
            }
            
            key = "SampleType"
            if let def = definitions[key], case .stringLiteral(let obj) = def {
                XCTAssertEqual(key, obj.id.className)
                XCTAssertEqual(key, obj.title)
                XCTAssertEqual(["a","b"], obj.examples)
            }
            else {
                XCTFail("Missing definition mapping for \(key)")
            }
            
            key = "SampleAnimals"
            if let def = definitions[key], case .stringOptionSet(let obj) = def {
                XCTAssertEqual(key, obj.id.className)
                XCTAssertEqual(key, obj.title)
                XCTAssertEqual(["bear", "cow", "fox"], Set(obj.examples ?? []))
            }
            else {
                XCTFail("Missing definition mapping for \(key)")
            }
            
            key = "SampleA"
            if let def = definitions[key], case .object(let obj) = def {
                XCTAssertEqual(key, obj.id.className)
                XCTAssertEqual(key, obj.title)
                XCTAssertEqual(obj.allOf?.map { $0.ref.className }, ["Sample"])
                XCTAssertEqual(Set(obj.required ?? []), ["type","value"])
                XCTAssertFalse(obj.isOpen)
                let expectedExamples = [
                    AnyCodableDictionary(["type":"a","value":3]),
                    AnyCodableDictionary(["type":"a","value":2,"color":"yellow","animalMap": ["blue":["robin","sparrow"]]])
                ]
                XCTAssertEqual(expectedExamples, obj.examples)
                let expectedProperties: [String : JsonSchemaProperty] = [
                    "type" : .const(JsonSchemaConst(const: "a", ref: JsonSchemaReferenceId("SampleType"))),
                    "value" : .primitive(.integer),
                    "color" : .reference(JsonSchemaObjectRef(ref: JsonSchemaReferenceId("SampleColor"))),
                    "animalMap" : .dictionary(JsonSchemaTypedDictionary(items: .reference(JsonSchemaObjectRef(ref: JsonSchemaReferenceId("SampleAnimals")))))
                ]
                XCTAssertEqual(expectedProperties, obj.properties)
            }
            else {
                XCTFail("Missing definition mapping for \(key)")
            }
            
            key = "SampleB"
            if let def = definitions[key], case .object(let obj) = def {
                XCTAssertEqual(key, obj.id.className)
                XCTAssertEqual(key, obj.title)
                XCTAssertEqual(obj.allOf?.map { $0.ref.className }, ["Sample"])
                XCTAssertEqual(Set(obj.required ?? []), ["type","value"])
                XCTAssertFalse(obj.isOpen)
                let expectedProperties: [String : JsonSchemaProperty] = [
                    "type" : .const(JsonSchemaConst(const: "b", ref: JsonSchemaReferenceId("SampleType"))),
                    "value" : .primitive(.string),
                    "animals" : .reference(JsonSchemaObjectRef(ref: JsonSchemaReferenceId("SampleAnimals"))),
                    "jsonBlob" : .primitive(.any),
                    "timestamp" : .primitive(JsonSchemaPrimitive(format: .dateTime)),
                    "numberMap" : .dictionary(JsonSchemaTypedDictionary(items: .primitive(.integer)))
                ]
                
                XCTAssertEqual(expectedProperties.count, obj.properties?.count)
                XCTAssertEqual(expectedProperties, obj.properties)
                XCTAssertEqual(expectedProperties["type"], obj.properties?["type"])
                XCTAssertEqual(expectedProperties["value"], obj.properties?["value"])
                XCTAssertEqual(expectedProperties["animals"], obj.properties?["animals"])
                XCTAssertEqual(expectedProperties["jsonBlob"], obj.properties?["jsonBlob"])
                XCTAssertEqual(expectedProperties["timestamp"], obj.properties?["timestamp"])
                XCTAssertEqual(expectedProperties["numberMap"], obj.properties?["numberMap"])
            }
            else {
                XCTFail("Missing definition mapping for \(key)")
            }
        }
        catch let err {
            XCTFail("Failed to build the JsonSchema: \(err)")
        }
    }
}
