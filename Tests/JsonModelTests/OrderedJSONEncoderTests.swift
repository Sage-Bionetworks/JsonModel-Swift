//
//  OrderedJSONEncoderTests.swift
//
//  Copyright © 2022 Sage Bionetworks. All rights reserved.
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

class OrderedJSONEncoderTests: XCTestCase {
    
    let decoder: JSONDecoder = ResultDataFactory().createJSONDecoder()

    let encoder: JSONEncoder = ResultDataFactory().createJSONEncoder()

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // Use a statically defined timezone.
        ISO8601TimestampFormatter.timeZone = TimeZone(secondsFromGMT: Int(-2.5 * 60 * 60))
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testAssessmentResultKeyOrder() {
        let result = AssessmentResultObject(identifier: "foo",
                                            versionString: "1.0.2",
                                            assessmentIdentifier: "baruu",
                                            schemaIdentifier: "baloo",
                                            startDate: Date(),
                                            endDate: Date(),
                                            asyncResults: [])

        do {
            let encoder = OrderedJSONEncoder()
            encoder.shouldOrderKeys = true
            let data = try encoder.encode(result)
            
            let expectedKeyOrder = ["type", "identifier", "startDate", "endDate", "assessmentIdentifier", "versionString", "taskRunUUID", "schemaIdentifier", "stepHistory", "asyncResults", "path"]
            guard let pretty = String(data: data, encoding: .utf8) else {
                XCTFail("Unexpected NULL string")
                return
            }
            
            expectedKeyOrder.forEach { key in
                XCTAssertTrue(pretty.contains("\"\(key)\""), "MISSING: \(key)")
            }
            
            let positions: [Range<String.Index>] = expectedKeyOrder.compactMap { key in
                pretty.range(of: key)
            }.sorted(by: { $0.lowerBound < $1.lowerBound })
            
            let actualKeyOrder = positions.map { String(pretty[$0]) }
            XCTAssertEqual(expectedKeyOrder, actualKeyOrder)

        }
        catch {
            XCTFail("Failed to encode result. \(error)")
        }
    }
    
// syoung 10/06/2022 This test takes about 12 seconds to run b/c it's huge so commenting out
// but leaving in place as a reference. The issue discovered is that attempting to sort the
// keys to make them more readable was causing a crash on the old regex and the replacement
// is more memory efficient but still very slow.
//    func testOrderedJSONEncoderMemoryCrash() throws {
//        let assessmentResult = AssessmentResultObject(identifier: "foo")
//        for ii in 1...2 {
//            let collectionResult = CollectionResultObject(identifier: "collection\(ii)")
//            for nn in 1...5000 {
//                collectionResult.children.append(ResultObject(identifier: "result\(nn)", startDate: Date(), endDate: Date()))
//            }
//            collectionResult.endDateTime = collectionResult.children.last?.endDate
//            assessmentResult.appendStepHistory(with: collectionResult)
//        }
//
//        let encoder = OrderedJSONEncoder()
//        encoder.shouldOrderKeys = true
//        let _ = try encoder.encode(assessmentResult)
//    }
}
