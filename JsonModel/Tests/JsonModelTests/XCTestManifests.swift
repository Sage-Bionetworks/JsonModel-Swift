import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(JsonModelTests.allTests),
        testCase(AnyCodableTests.allTests),
        testCase(DocumentableTests.allTests),
        testCase(JsonElementTests.allTests),
        testCase(PolymorphicSerializerTests.allTests),
        testCase(JsonSchemaTests.allTests),
    ]
}
#endif
