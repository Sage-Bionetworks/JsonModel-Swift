//
//  AssessmentResult.swift
//  
//

import Foundation
import JsonModel

/// An ``AssessmentResult`` is the top-level ``ResultData`` for an assessment.
public protocol AssessmentResult : BranchNodeResult {

    /// A unique identifier for this run of the assessment. This property is defined as readwrite
    /// to allow the controller for the task to set this on the ``AssessmentResult`` children
    /// included in this run.
    var taskRunUUID: UUID { get set }

    /// The ``versionString`` may be a semantic version, timestamp, or sequential revision integer.
    var versionString: String? { get }
    
    /// An identifier for the assessment model associated with this result. If included, this
    /// is intended to match the identifier used by the services that requested running the
    /// assessment. This could be a schedule identifier or an identifier in a different namespace
    /// than the "task identifier" used by the assessment developers to identify their assessments.
    var assessmentIdentifier: String? { get }
    
    /// An identifier that can be used either by the assessment developers or scientists as needed.
    var schemaIdentifier: String?  { get }
}

/// Abstract implementation to allow extending an assessment result while retaining the serializable type.
@Serializable(subclassIndex: 1)
open class AbstractAssessmentResultObject : AbstractBranchNodeResultObject {

    public var assessmentIdentifier: String?
    public let versionString: String?
    public var schemaIdentifier: String?
    public var taskRunUUID: UUID
    
    @SerialName("$schema") public private(set) var jsonSchema: URL

    /// Default initializer for this object.
    public init(identifier: String,
                versionString: String? = nil,
                assessmentIdentifier: String? = nil,
                schemaIdentifier: String? = nil,
                jsonSchema: URL? = nil,
                startDate: Date = Date(),
                endDate: Date? = nil,
                taskRunUUID: UUID = UUID(),
                stepHistory: [ResultData] = [],
                asyncResults: [ResultData]? = nil,
                path: [PathMarker] = []) {
        self.versionString = versionString
        self.assessmentIdentifier = assessmentIdentifier
        self.schemaIdentifier = schemaIdentifier
        self.taskRunUUID = taskRunUUID
        self.jsonSchema = jsonSchema ?? URL(string: "\(Self.self).json", relativeTo: kBDHJsonSchemaBaseURL)!
        super.init(identifier: identifier, startDate: startDate, endDate: endDate, stepHistory: stepHistory, asyncResults: asyncResults, path: path)
    }

    override open class func isRequired(_ codingKey: CodingKey) -> Bool {
        guard let key = codingKey as? CodingKeys else {
            return super.isRequired(codingKey)
        }
        return key == .taskRunUUID
    }

    override open class func documentProperty(for codingKey: CodingKey) throws -> DocumentProperty {
        guard let key = codingKey as? CodingKeys else {
            return try super.documentProperty(for: codingKey)
        }
        switch key {
        case .assessmentIdentifier:
            return .init(propertyType: .primitive(.string), propertyDescription:
            """
            An identifier for the assessment model associated with this result. If included, this
            is intended to match the identifier used by the services that requested running the
            assessment. This could be a schedule identifier or an identifier in a different namespace
            than the "task identifier" used by the assessment developers to identify their assessments.
            """.replacingOccurrences(of: "\n", with: " ").replacingOccurrences(of: "  ", with: "\n"))
        case .schemaIdentifier:
            return .init(propertyType: .primitive(.string), propertyDescription:
            "An identifier that can be used either by the developer or researcher for custom mapping.")
        case .versionString:
            return .init(propertyType: .primitive(.string), propertyDescription:
            "The versioning key used by the developer to version this assessment.")
        case .taskRunUUID:
            return .init(propertyType: .primitive(.string), propertyDescription:
            """
            A unique identifier for this run of the assessment. This property is defined as readwrite
            to allow the controller for the task to set this on the ``AssessmentResult`` children
            included in this run.
            """.replacingOccurrences(of: "\n", with: " ").replacingOccurrences(of: "  ", with: "\n"))
        case .jsonSchema:
            return .init(propertyType: .format(.uri), propertyDescription: "The json schema URI for this result.")
        }
    }
}

/// ``AssessmentResultObject`` is a result associated with a task. This object includes a step history,
/// task run UUID,  and asynchronous results.
@Serializable(subclassIndex: 3)
@SerialName("assessment")
public final class AssessmentResultObject : AbstractAssessmentResultObject, AssessmentResult {
    
    public func deepCopy() -> AssessmentResultObject {
        let copy = AssessmentResultObject(identifier: self.identifier,
                                          versionString: self.versionString,
                                          assessmentIdentifier: self.assessmentIdentifier,
                                          schemaIdentifier: self.schemaIdentifier)
        copy.startDateTime = self.startDateTime
        copy.endDateTime = self.endDateTime
        copy.taskRunUUID = self.taskRunUUID
        copy.stepHistory = self.stepHistory.map { $0.deepCopy() }
        copy.asyncResults = self.asyncResults?.map { $0.deepCopy() }
        copy.path = self.path
        return copy
    }
}

extension AssessmentResultObject : DocumentableRootObject {

    public convenience init() {
        self.init(identifier: "example")
    }

    public var documentDescription: String? {
        "A top-level result for this assessment."
    }
}

extension AssessmentResultObject : DocumentableStruct {

    public static func examples() -> [AssessmentResultObject] {

        let result = AssessmentResultObject(identifier: "example")

        var introStepResult = ResultObject(identifier: "introduction")
        introStepResult.startDateTime = ISO8601TimestampFormatter.date(from: "2017-10-16T22:28:09.000-07:00")!
        introStepResult.endDateTime = introStepResult.startDateTime.addingTimeInterval(20)
        
        let collectionResult = CollectionResultObject.examples().first!
        collectionResult.startDateTime = introStepResult.endDateTime!
        collectionResult.endDateTime = collectionResult.startDateTime.addingTimeInterval(2 * 60)
        
        var conclusionStepResult = ResultObject(identifier: "conclusion")
        conclusionStepResult.startDateTime = collectionResult.endDateTime!
        conclusionStepResult.endDateTime = conclusionStepResult.startDateTime.addingTimeInterval(20)

        var fileResult = FileResultObject.examples().first!
        fileResult.startDateTime = collectionResult.startDateTime
        fileResult.endDateTime = collectionResult.endDateTime
        
        result.stepHistory = [introStepResult, collectionResult, conclusionStepResult]
        result.asyncResults = [fileResult]

        result.startDateTime = introStepResult.startDateTime
        result.endDateTime = conclusionStepResult.endDateTime
        result.path = [
            .init(identifier: "introduction", direction: .forward),
            .init(identifier: collectionResult.identifier, direction: .forward),
            .init(identifier: "conclusion", direction: .forward)
        ]

        return [result]
    }
}

