//
//  AnyCodableTests.swift
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

final class AnyCodableTests: XCTestCase {
    
    func testDictionary_Encodable() {
        
        let factory = SerializationFactory.defaultFactory
        let encoder = factory.createJSONEncoder()
        let decoder = factory.createJSONDecoder()
        
        let now = Date()
        var dateComponents = DateComponents()
        dateComponents.day = 1
        dateComponents.month = 6
        let data = Data(base64Encoded: "ABCD")!
        let uuid = UUID()
        let url = URL(string: "http://test.example.org")!
        
        let input: [String : Any] = ["string" : "String",
                                                  "number" : NSNumber(value: 23),
                                                  "infinity" : Double.infinity,
                                                  "integer" : Int(34),
                                                  "double" : Double(1.234),
                                                  "bool" : true,
                                                  "null" : NSNull(),
                                                  "date" : now,
                                                  "dateComponents" : dateComponents,
                                                  "data" : data,
                                                  "uuid" : uuid,
                                                  "url" : url,
                                                  "array" : ["cat", "dog", "duck"],
                                                  "dictionary" : ["a" : 1, "b" : "bat", "c" : true]
                                                  ]
        do {
            
            encoder.dataEncodingStrategy = .base64
            encoder.nonConformingFloatEncodingStrategy = .convertToString(positiveInfinity: "+inf", negativeInfinity: "-inf", nan: "NaN")
            let jsonData = try encoder.encodeDictionary(input)
            
            guard let dictionary = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String : Any]
                else {
                    XCTFail("Encoded object is not a dictionary")
                    return
            }

            XCTAssertEqual("String", dictionary["string"] as? String)
            XCTAssertEqual(23, dictionary["number"] as? Int)
            XCTAssertEqual("+inf", dictionary["infinity"] as? String)
            XCTAssertEqual(34, dictionary["integer"] as? Int)
            XCTAssertEqual(1.234, dictionary["double"] as? Double)
            XCTAssertEqual(true, dictionary["bool"] as? Bool)
            XCTAssertNotNil(dictionary["null"] as? NSNull)
            XCTAssertEqual(now.jsonObject() as? String, dictionary["date"] as? String)
            XCTAssertEqual("06-01", dictionary["dateComponents"] as? String)
            XCTAssertEqual(data.base64EncodedString(), dictionary["data"] as? String)
            XCTAssertEqual(uuid.uuidString, dictionary["uuid"] as? String)
            if let array = dictionary["array"] as? [String] {
                XCTAssertEqual(["cat", "dog", "duck"], array)
            } else {
                XCTFail("Failed to encode array. \(String(describing: dictionary["array"]))")
            }
            if let subd = dictionary["dictionary"] as? [String : Any] {
                XCTAssertEqual( 1, subd["a"] as? Int)
                XCTAssertEqual("bat", subd["b"] as? String)
                XCTAssertEqual(true, subd["c"] as? Bool)
            } else {
                XCTFail("Failed to encode dictionary. \(String(describing: dictionary["dictionary"]))")
            }
            
            // Test convert to object
            let object = try decoder.decode(TestDecodable.self, from: dictionary)
            
            XCTAssertEqual("String", object.string)
            XCTAssertEqual(34, object.integer)
            XCTAssertEqual(true, object.bool)
            XCTAssertEqual(now.timeIntervalSinceReferenceDate, object.date.timeIntervalSinceReferenceDate, accuracy: 0.01)
            XCTAssertEqual(uuid, object.uuid)
            XCTAssertEqual(["cat", "dog", "duck"], object.array)
            XCTAssertNil(object.null)
            
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    func testArray_Codable() {
        
        let factory = SerializationFactory.defaultFactory
        let encoder = factory.createJSONEncoder()
        let decoder = factory.createJSONDecoder()
        
        let now = Date()
        var dateComponents = DateComponents()
        dateComponents.day = 1
        dateComponents.month = 6
        let uuid = UUID()
        
        let input: [Any] = [["string" : "String",
                             "integer" : NSNumber(value: 34),
                             "bool" : NSNumber(value:true),
                             "date" : now.jsonObject(),
                             "uuid" : uuid.uuidString,
                             "array" : ["cat", "dog", "duck"]]]
        do {
            guard let object = try decoder.decode([TestDecodable].self, from: input).first
                else {
                    XCTFail("Failed to decode object")
                    return
            }
            
            XCTAssertEqual("String", object.string)
            XCTAssertEqual(34, object.integer)
            XCTAssertEqual(true, object.bool)
            XCTAssertEqual(now.timeIntervalSinceReferenceDate, object.date.timeIntervalSinceReferenceDate, accuracy: 0.01)
            XCTAssertEqual(uuid, object.uuid)
            XCTAssertEqual(["cat", "dog", "duck"], object.array)
            XCTAssertNil(object.null)
            
            encoder.dataEncodingStrategy = .base64
            encoder.nonConformingFloatEncodingStrategy = .convertToString(positiveInfinity: "+inf", negativeInfinity: "-inf", nan: "NaN")
            let jsonData = try encoder.encodeArray(input)
            
            guard let array = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [[String: Any]],
                let dictionary = array.first
                else {
                    XCTFail("Encoded object is not a dictionary")
                    return
            }
            
            XCTAssertEqual("String", dictionary["string"] as? String)
            XCTAssertEqual(34, dictionary["integer"] as? Int)
            XCTAssertEqual(true, dictionary["bool"] as? Bool)
            XCTAssertNotNil(dictionary["date"] as? String)
            XCTAssertEqual(uuid.uuidString, dictionary["uuid"] as? String)
            XCTAssertEqual(["cat", "dog", "duck"], dictionary["array"] as? [String])
            
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    func testEncodableToJsonElement_Object() {
        let uuid = UUID()
        let now = Date()
        let expected: [String : JsonSerializable] = ["string" : "String",
                                                     "integer" : NSNumber(value: 34),
                                                     "bool" : NSNumber(value:true),
                                                     "date" : now.jsonObject(),
                                                     "uuid" : uuid.uuidString,
                                                     "array" : ["cat", "dog", "duck"]]
        
        let test = TestDecodable(string: "String",
                                 integer: 34,
                                 uuid: uuid,
                                 date: now,
                                 bool: true,
                                 array: ["cat", "dog", "duck"],
                                 null: nil)
        
        do {
            let jsonElement = try test.jsonElement()
            XCTAssertEqual(JsonElement.object(expected), jsonElement)
        
            let dictionary = try test.jsonEncodedDictionary()
            XCTAssertEqual(expected as NSDictionary, dictionary as NSDictionary)
            
            let data = try test.jsonEncodedData()
            let obj = try SerializationFactory.defaultFactory.createJSONDecoder().decode(TestDecodable.self, from: data)
            XCTAssertEqual(test.string, obj.string)
            XCTAssertEqual(test.integer, obj.integer)
            XCTAssertEqual(test.uuid, obj.uuid)
            XCTAssertEqual(test.date.timeIntervalSinceReferenceDate, obj.date.timeIntervalSinceReferenceDate, accuracy: 1)
            XCTAssertEqual(test.bool, obj.bool)
            XCTAssertEqual(test.array, obj.array)
            XCTAssertEqual(test.null, obj.null)

        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    func testEncodableToJsonElement_Int() {
        do {
            let test = 3
            let jsonElement = try test.jsonElement()
            XCTAssertEqual(JsonElement.integer(3), jsonElement)
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
}

struct TestDecodable : Codable {
    let string: String
    let integer: Int
    let uuid: UUID
    let date: Date
    let bool: Bool
    let array: [String]
    let null: String?
}
