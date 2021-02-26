//
//  AnswerResultTypeJSONTests.swift
//
//  Copyright © 2019-2021 Sage Bionetworks. All rights reserved.
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

class AnswerCodingInfoTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
        // Use a statically defined timezone.
        ISO8601TimestampFormatter.timeZone = TimeZone(secondsFromGMT: Int(-2.5 * 60 * 60))
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testAnswerCodingInfoString_Codable() {
        do {
            let expectedObject = "hello"
            let expectedJson: JsonElement = .string("hello")

            let AnswerCodingInfo = AnswerCodingInfoString()
            let objectValue = try AnswerCodingInfo.decodeAnswer(from: expectedJson)
            let jsonValue = try AnswerCodingInfo.encodeAnswer(from: expectedObject)
            
            XCTAssertEqual(objectValue as? String, expectedObject)
            XCTAssertEqual(jsonValue, expectedJson)
            
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
        }
    }

    func testAnswerCodingInfoBoolean_Codable() {
         do {
            let expectedObject = true
            let expectedJson: JsonElement = .boolean(true)
            
            let AnswerCodingInfo = AnswerCodingInfoBoolean()
            let objectValue = try AnswerCodingInfo.decodeAnswer(from: expectedJson)
            let jsonValue = try AnswerCodingInfo.encodeAnswer(from: expectedObject)
            
            XCTAssertEqual(objectValue as? Bool, expectedObject)
            XCTAssertEqual(jsonValue, expectedJson)
            
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
        }
    }

    func testAnswerCodingInfoInteger_Codable() {
        do {
            let expectedObject = 12
            let expectedJson: JsonElement = .integer(12)
            
            let AnswerCodingInfo = AnswerCodingInfoInteger()
            let objectValue = try AnswerCodingInfo.decodeAnswer(from: expectedJson)
            let jsonValue = try AnswerCodingInfo.encodeAnswer(from: expectedObject)
            
            XCTAssertEqual(objectValue as? Int, expectedObject)
            XCTAssertEqual(jsonValue, expectedJson)
            
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
        }
    }

    func testAnswerCodingInfoNumber_Codable() {
        do {
            let expectedObject = 12.5
            let expectedJson: JsonElement = .number(12.5)
            
            let AnswerCodingInfo = AnswerCodingInfoNumber()
            let objectValue = try AnswerCodingInfo.decodeAnswer(from: expectedJson)
            let jsonValue = try AnswerCodingInfo.encodeAnswer(from: expectedObject)
            
            XCTAssertEqual(objectValue as? Double, expectedObject)
            XCTAssertEqual(jsonValue, expectedJson)
            
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
        }
    }

    func testAnswerCodingInfoDateTime_Codable() {

        do {
            let expectedJson: JsonElement = .string("2016-02-20")
            
            let AnswerCodingInfo = AnswerCodingInfoDateTime(codingFormat: "yyyy-MM-dd")

            let objectValue = try AnswerCodingInfo.decodeAnswer(from: expectedJson)
            if let date = objectValue as? Date {
                let calendar = Calendar(identifier: .iso8601)
                let calendarComponents: Set<Calendar.Component> = [.year, .month, .day]
                let comp = calendar.dateComponents(calendarComponents, from: date)
                XCTAssertEqual(comp.year, 2016)
                XCTAssertEqual(comp.month, 2)
                XCTAssertEqual(comp.day, 20)
                
                let jsonValue = try AnswerCodingInfo.encodeAnswer(from: date)
                XCTAssertEqual(expectedJson, jsonValue)
            }
            else {
                XCTFail("Failed to decode String to a Date: \(String(describing: objectValue))")
            }
            
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
        }
    }

    func testAnswerCodingInfoArray_String_Codable() {
        do {
            let expectedObject = ["alpha", "beta", "gamma"]
            let expectedJson: JsonElement = .array(["alpha", "beta", "gamma"])
            
            let AnswerCodingInfo = AnswerCodingInfoArray(baseType: .string)
            let objectValue = try AnswerCodingInfo.decodeAnswer(from: expectedJson)
            let jsonValue = try AnswerCodingInfo.encodeAnswer(from: expectedObject)
            
            XCTAssertEqual(objectValue as? [String], expectedObject)
            XCTAssertEqual(jsonValue, expectedJson)
            
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
        }
    }

    func testAnswerCodingInfoArray_Integer_Codable() {
        do {
            let expectedObject = [65, 47, 99]
            let expectedJson: JsonElement = .array([65, 47, 99])
            
            let AnswerCodingInfo = AnswerCodingInfoArray(baseType: .integer)
            let objectValue = try AnswerCodingInfo.decodeAnswer(from: expectedJson)
            let jsonValue = try AnswerCodingInfo.encodeAnswer(from: expectedObject)
            
            XCTAssertEqual(objectValue as? [Int], expectedObject)
            XCTAssertEqual(jsonValue, expectedJson)
            
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
        }
    }

    func testAnswerCodingInfoArray_Double_Codable() {
        do {
            let expectedObject = [65.3, 47.2, 99.8]
            let expectedJson: JsonElement = .array([65.3, 47.2, 99.8])
            
            let AnswerCodingInfo = AnswerCodingInfoArray(baseType: .number)
            let objectValue = try AnswerCodingInfo.decodeAnswer(from: expectedJson)
            let jsonValue = try AnswerCodingInfo.encodeAnswer(from: expectedObject)
            
            XCTAssertEqual(objectValue as? [Double], expectedObject)
            XCTAssertEqual(jsonValue, expectedJson)
            
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
        }
    }
}
