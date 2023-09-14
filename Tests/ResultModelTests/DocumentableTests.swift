//
//  DocumentableTests.swift
//
//

import XCTest
import JsonModel
@testable import ResultModel

final class DocumentableTests: XCTestCase {

    
    func testResultDataFactory() {
        do {
            let factory = TestResultFactoryA()
            let doc = JsonDocumentBuilder(factory: factory)
            let schemas = try doc.buildSchemas()
            
            XCTAssertEqual(schemas.count, 4)
            
            if let testSchema = schemas.first(where: { $0.id.className == "TestResult"}),
               let sampleDef = testSchema.definitions?["Sample"],
               case .object(let sampleObj) = sampleDef, let sampleProps = sampleObj.properties {
                XCTAssertNotNil(sampleProps["index"])
                XCTAssertNotNil(sampleProps["identifier"])
                XCTAssertNotNil(sampleProps["startDate"])
            }
            else {
                XCTFail("Failed to build schema.")
            }
            
            if let rootSchema = schemas.first(where: { $0.id.className == "ResultData"}),
               let def = rootSchema.definitions?["ResultObject"],
               case .object(let obj) = def, let props = obj.properties {
                XCTAssertNotNil(props["type"])
                XCTAssertNil(props["identifier"])
                XCTAssertNil(props["startDate"])
                XCTAssertNil(props["endDate"])
            }
            else {
                XCTFail("Failed to build schema.")
            }
        }
        catch let err {
            XCTFail("Failed to build the JsonSchema: \(err)")
        }
    }
    
    func testResultDataFactoryExternal() {
        do {
            let factory = TestResultFactoryB()
            let doc = JsonDocumentBuilder(factory: factory)
            let schemas = try doc.buildSchemas()
            
            let schemaNames = schemas.map { $0.id.className }
            XCTAssertEqual(["TestResultExternal"], schemaNames)
            
            guard let schema = schemas.first, schema.id.className == "TestResultExternal" else {
                XCTFail("Failed to build and filter schemas")
                return
            }
            
            if let interface = schema.root.allOf?.first?.refId {
                XCTAssertEqual("ResultData", interface.className)
                XCTAssertTrue(interface.isExternal)
                XCTAssertEqual("https://bridgedigitalhealth.github.io/mobile-client-json/schemas/v2/ResultData.json", interface.classPath)
            }
            else {
                XCTFail("Failed to add expected interfaces.")
            }
            
            if let props = schema.root.properties,
               let typeProp = props["type"],
               case .const(let constType) = typeProp {
                XCTAssertEqual("test", constType.const)
                // TODO: syoung 06/06/2023 Revisit this when/if we update the schema from Draft 7 to a new schema that supports both const and $ref
//                XCTAssertEqual("https://bridgedigitalhealth.github.io/mobile-client-json/schemas/v2/ResultData.json#SerializableResultType", constType.ref?.classPath)
            }
            else {
                XCTFail("Failed to add expected property.")
            }
        }
        catch let err {
            XCTFail("Failed to build the JsonSchema: \(err)")
        }
    }
}

// MARK: Test objects

class TestResultFactoryA : ResultDataFactory {
    required init() {
        super.init()
        resultSerializer.add(TestResult())
    }
}

extension SerializableResultType {
    static let test: SerializableResultType = "test"
}

struct TestResult : SerializableResultData, DocumentableStruct, DocumentableRootObject {
    private enum CodingKeys : String, OrderedEnumCodingKey {
        case serializableType="type", identifier, startDate, endDate, sample
    }
    
    var serializableType: SerializableResultType = .test
    var identifier: String = "test"
    var startDate: Date = Date()
    var endDate: Date = Date()
    var sample: Sample = .init()
    
    func deepCopy() -> TestResult {
        self
    }
    
    public var jsonSchema: URL {
        URL(string: "\(self.className).json", relativeTo: kBDHJsonSchemaBaseURL)!
    }

    public var documentDescription: String? {
        "A result used to test root serialization."
    }
    
    static func examples() -> [TestResult] {
        [.init()]
    }
    
    static func codingKeys() -> [CodingKey] {
        CodingKeys.allCases
    }
    
    static func isRequired(_ codingKey: CodingKey) -> Bool {
        true
    }
    
    static func documentProperty(for codingKey: CodingKey) throws -> DocumentProperty {
        guard let key = codingKey as? CodingKeys else {
            throw DocumentableError.invalidCodingKey(codingKey, "\(codingKey) is not recognized for this class")
        }
        switch key {
        case .serializableType:
            return .init(constValue: SerializableResultType.test)
        case .identifier:
            return .init(propertyType: .primitive(.string))
        case .startDate, .endDate:
            return .init(propertyType: .format(.dateTime))
        case .sample:
            return .init(propertyType: .reference(Sample.documentableType()))
        }
    }
    
    struct Sample : DocumentableStruct {
        private enum CodingKeys : String, OrderedEnumCodingKey {
            case index, identifier, startDate
        }
        
        var index: Int = 0
        var identifier: String = "sample"
        var startDate: Date = Date()
        
        static func examples() -> [Sample] {
            [.init()]
        }
        
        static func codingKeys() -> [CodingKey] {
            CodingKeys.allCases
        }
        
        static func isRequired(_ codingKey: CodingKey) -> Bool {
            true
        }
        
        static func documentProperty(for codingKey: CodingKey) throws -> DocumentProperty {
            guard let key = codingKey as? CodingKeys else {
                throw DocumentableError.invalidCodingKey(codingKey, "\(codingKey) is not recognized for this class")
            }
            switch key {
            case .index:
                return .init(propertyType: .primitive(.integer))
            case .identifier:
                return .init(propertyType: .primitive(.string))
            case .startDate:
                return .init(propertyType: .format(.dateTime))
            }
        }
    }
}

let testBURL = URL(string: "https://foo.org/schemas/")!

class TestResultFactoryB : ResultDataFactory {
    required init() {
        super.init()
        resultSerializer.add(TestResultExternal())
    }
    
    override var jsonSchemaBaseURL: URL {
        testBURL
    }
}

struct TestResultExternal : SerializableResultData, DocumentableStruct, DocumentableRootObject {
    private enum CodingKeys : String, OrderedEnumCodingKey {
        case serializableType="type", identifier, startDate, endDate
    }
    
    var serializableType: SerializableResultType = .test
    var identifier: String = "test"
    var startDate: Date = Date()
    var endDate: Date = Date()
    
    func deepCopy() -> TestResultExternal {
        self
    }
    
    public var jsonSchema: URL {
        URL(string: "\(self.className).json", relativeTo: testBURL)!
    }

    public var documentDescription: String? {
        "A result used to test root serialization."
    }
    
    static func examples() -> [TestResultExternal] {
        [.init()]
    }
    
    static func codingKeys() -> [CodingKey] {
        CodingKeys.allCases
    }
    
    static func isRequired(_ codingKey: CodingKey) -> Bool {
        true
    }
    
    static func documentProperty(for codingKey: CodingKey) throws -> DocumentProperty {
        guard let key = codingKey as? CodingKeys else {
            throw DocumentableError.invalidCodingKey(codingKey, "\(codingKey) is not recognized for this class")
        }
        switch key {
        case .serializableType:
            return .init(constValue: SerializableResultType.test)
        case .identifier:
            return .init(propertyType: .primitive(.string))
        case .startDate, .endDate:
            return .init(propertyType: .format(.dateTime))
        }
    }
}
