//
//  ResultDataTests.swift
//
//  Copyright © 2020-2021 Sage Bionetworks. All rights reserved.
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

class ResultDataTests: XCTestCase {
    
    let decoder: JSONDecoder = ResultDataFactory().createJSONDecoder()

    var encoder: JSONEncoder = ResultDataFactory().createJSONEncoder()

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testCreateJsonSchemaDocumentation() {
        let factory = ResultDataFactory()
        let baseUrl = URL(string: "http://sagebionetworks.org/SageResearch/jsonSchema/")!
        
        let doc = JsonDocumentBuilder(baseUrl: baseUrl,
                                      factory: factory,
                                      rootDocuments: [])
        
        do {
            let _ = try doc.buildSchemas()
        }
        catch let err {
            XCTFail("Failed to build the JsonSchema: \(err)")
        }
    }
    
    func testCollectionResultObject_Codable() {
        let collectionResult = CollectionResultObject(identifier: "foo")
        let answerResult1 = AnswerResultObject(identifier: "input1", value: .boolean(true))
        let answerResult2 = AnswerResultObject(identifier: "input2", value: .integer(42))
        collectionResult.children = [answerResult1, answerResult2]
        
        do {
            let jsonData = try encoder.encode(collectionResult)
            guard let dictionary = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String : Any]
                else {
                    XCTFail("Encoded object is not a dictionary")
                    return
            }
            
            XCTAssertEqual(dictionary["identifier"] as? String, "foo")
            XCTAssertNotNil(dictionary["startDate"])
            XCTAssertNotNil(dictionary["endDate"])
            if let results = dictionary["inputResults"] as? [[String : Any]] {
                XCTAssertEqual(results.count, 2)
                if let result1 = results.first {
                    XCTAssertEqual(result1["identifier"] as? String, "input1")
                }
            } else {
                XCTFail("Failed to encode the input results.")
            }
            
            let object = try decoder.decode(CollectionResultObject.self, from: jsonData)
            
            XCTAssertEqual(object.identifier, collectionResult.identifier)
            XCTAssertEqual(object.startDate.timeIntervalSinceNow, collectionResult.startDate.timeIntervalSinceNow, accuracy: 1)
            XCTAssertEqual(object.endDate.timeIntervalSinceNow, collectionResult.endDate.timeIntervalSinceNow, accuracy: 1)
            XCTAssertEqual(object.children.count, 2)
            
            if let result1 = object.children.first as? AnswerResultObject {
                XCTAssertEqual(result1.identifier, answerResult1.identifier)
                let expected = AnswerTypeBoolean()
                XCTAssertEqual(expected, answerResult1.answerType as? AnswerTypeBoolean)
                XCTAssertEqual(result1.startDate.timeIntervalSinceNow, answerResult1.startDate.timeIntervalSinceNow, accuracy: 1)
                XCTAssertEqual(result1.endDate.timeIntervalSinceNow, answerResult1.endDate.timeIntervalSinceNow, accuracy: 1)
                XCTAssertEqual(result1.jsonValue, answerResult1.jsonValue)
            } else {
                XCTFail("\(object.children) did not decode the results as expected")
            }
            
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
        }
    }
    
    func testFileResultObject_Init() {
        let fileResult = FileResultObject(identifier: "fileResult", url: URL(string: "file://temp/foo.json")!, contentType: "application/json", startUptime: 1234.567)
        XCTAssertEqual("/foo.json", fileResult.relativePath)
    }
    
    func testFileResultObject_Codable() {
        let json = """
        {
            "identifier": "foo",
            "type": "file",
            "startDate": "2017-10-16T22:28:09.000-02:30",
            "endDate": "2017-10-16T22:30:09.000-02:30",
            "relativePath": "temp.json",
            "contentType": "application/json"
        }
        """.data(using: .utf8)! // our data in native (JSON) format
        
        do {
            
            let object = try decoder.decode(FileResultObject.self, from: json)
            
            XCTAssertEqual(object.identifier, "foo")
            XCTAssertEqual(object.serializableType, "file")
            XCTAssertGreaterThan(object.endDate, object.startDate)
            XCTAssertEqual(object.relativePath, "temp.json")
            XCTAssertEqual(object.contentType, "application/json")
            
            let jsonData = try encoder.encode(object)
            guard let dictionary = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String : Any]
                else {
                    XCTFail("Encoded object is not a dictionary")
                    return
            }
            
            XCTAssertEqual(dictionary["identifier"] as? String, "foo")
            XCTAssertEqual(dictionary["type"] as? String, "file")
            XCTAssertEqual(dictionary["startDate"] as? String, "2017-10-16T22:28:09.000-02:30")
            XCTAssertEqual(dictionary["endDate"] as? String, "2017-10-16T22:30:09.000-02:30")
            XCTAssertEqual(dictionary["relativePath"] as? String, "temp.json")
            XCTAssertEqual(dictionary["contentType"] as? String, "application/json")
            XCTAssertNil(dictionary["url"])
            
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
        }
    }
    
    func testFileResultObject_Copy() {
        let result = FileResultObject(identifier: "fileResult", url: URL(string: "file://temp/foo.json")!, contentType: "application/json", startUptime: 1234.567)
        var copy = result.deepCopy()
        XCTAssertEqual(result, copy)
        copy.startDate = Date()
        XCTAssertNotEqual(result, copy)
    }
    
    func testErrorResultObject_Copy() {
        let result = ErrorResultObject(identifier: "foo", description: "It broke", domain: "com.fixme.foo", code: 42)
        var copy = result.deepCopy()
        XCTAssertEqual(result, copy)
        copy.startDate = Date()
        XCTAssertNotEqual(result, copy)
    }
    
    func testAnswerResultObject_Copy() {
        let result = AnswerResultObject(identifier: "foo",
                                        answerType: AnswerTypeMeasurement(unit: "cm"),
                                        value: .number(42),
                                        questionText: "What is your favorite color?",
                                        questionData: .boolean(true))
        let copy = result.deepCopy()
        
        XCTAssertFalse(result === copy)
        XCTAssertEqual(result.identifier, copy.identifier)
        XCTAssertEqual(result.startDate, copy.startDate)
        XCTAssertEqual(result.endDate, copy.endDate)
        XCTAssertEqual(result.jsonValue, copy.jsonValue)
        XCTAssertEqual(result.questionText, copy.questionText)
        XCTAssertEqual(result.questionData, copy.questionData)
        XCTAssertEqual("cm", (copy.answerType as? AnswerTypeMeasurement)?.unit)
    }
    
    func testSerializers() {
        let factory = ResultDataFactory()
        
        XCTAssertTrue(checkPolymorphicExamples(for: factory.resultSerializer.examples,
                                                using: factory, protocolType: ResultData.self))
        XCTAssertTrue(checkPolymorphicExamples(for: factory.answerTypeSerializer.examples,
                                                using: factory, protocolType: AnswerType.self))

    }
    
    func checkPolymorphicExamples<ProtocolType>(for objects: [ProtocolType], using factory: SerializationFactory, protocolType: ProtocolType.Type) -> Bool {
        var success = true
        objects.forEach {
            guard let original = $0 as? DocumentableObject else {
                XCTFail("Object does not conform to DocumentableObject. \($0)")
                success = false
                return
            }

            do {
                let decoder = factory.createJSONDecoder()
                let examples = try type(of: original).jsonExamples()
                examples.forEach { example in
                    do {
                        // Check that the example can be decoded without errors.
                        let wrapper = example.jsonObject()
                        let encodedObject = try JSONSerialization.data(withJSONObject: wrapper, options: [])
                        let decodingWrapper = try decoder.decode(_DecodablePolymorphicWrapper.self, from: encodedObject)
                        let decodedObject = try factory.decodePolymorphicObject(protocolType, from: decodingWrapper.decoder)
                        
                        // Check that the decoded object is the same Type as the original.
                        let originalType = type(of: original as Any)
                        let decodedType = type(of: decodedObject as Any)
                        let isSameType = (originalType == decodedType)
                        XCTAssertTrue(isSameType, "\(decodedType) is not equal to \(originalType)")
                        success = success && isSameType
                        
                        // Check that the decoded type name is the same as the original type name
                        guard let decodedTypeName = (decodedObject as? PolymorphicRepresentable)?.typeName
                            else {
                                XCTFail("Decoded object does not conform to PolymorphicRepresentable. \(decodedObject)")
                                return
                        }
                        guard let originalTypeName = (original as? PolymorphicRepresentable)?.typeName
                            else {
                                XCTFail("Example object does not conform to PolymorphicRepresentable. \(original)")
                                return
                        }
                        XCTAssertEqual(originalTypeName, decodedTypeName)
                        success = success && (originalTypeName == decodedTypeName)
                        
                    } catch let err {
                        XCTFail("Failed to decode \(example) for \(protocolType). \(err)")
                        success = false
                    }
                }
            }
            catch let err {
                XCTFail("Failed to decode \(original). \(err)")
                success = false
            }
        }
        return success
    }
    
    fileprivate struct _DecodablePolymorphicWrapper : Decodable {
        let decoder: Decoder
        init(from decoder: Decoder) throws {
            self.decoder = decoder
        }
    }
}
