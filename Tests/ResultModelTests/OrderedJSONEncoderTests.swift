//
//  OrderedJSONEncoderTests.swift
//

import XCTest
import JsonModel
@testable import ResultModel

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
            
            let expectedKeyOrder = [
                "identifier", "startDate", "endDate",
                "assessmentIdentifier", "versionString", "schemaIdentifier", "taskRunUUID", "$schema",
                "stepHistory", "asyncResults", "path",
                "type"]
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
