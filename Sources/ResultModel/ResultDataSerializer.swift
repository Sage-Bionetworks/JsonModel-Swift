//
//  ResultDataSerializer.swift
//  
//

import Foundation
import JsonModel


/// `SerializableResultData` is the base implementation for `ResultData` that is serialized using
/// the `Codable` protocol and the polymorphic serialization defined by this framework.
@available(*, deprecated, message: "Inherit from ResultData directly")
public protocol SerializableResultData : ResultData, PolymorphicRepresentable {
    var serializableType: SerializableResultType { get }
}

@available(*, deprecated, message: "Inherit from ResultData directly")
extension SerializableResultData {
    public var typeName: String { serializableType.stringValue }
}

/// `SerializableResultType` is an extendable string enum used by the `SerializationFactory` to
/// create the appropriate result type.
public struct SerializableResultType : TypeRepresentable, Codable, Hashable {
    
    public let rawValue: String
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    public enum StandardTypes : String, CaseIterable {
        case answer, assessment, base, collection, error, file, section
        
        public var resultType: SerializableResultType {
            .init(rawValue: self.rawValue)
        }
    }
    
    /// List of all the standard types.
    public static func allStandardTypes() -> [SerializableResultType] {
        StandardTypes.allCases.map { $0.resultType }
    }
}

extension SerializableResultType : ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }
}

extension SerializableResultType : DocumentableStringLiteral {
    public static func examples() -> [String] {
        return allStandardTypes().map{ $0.rawValue }
    }
}

public final class ResultDataSerializer : GenericPolymorphicSerializer<ResultData>, DocumentableInterface {
    public var documentDescription: String? {
        """
        The interface for any `ResultData` that is serialized using the `Codable` protocol and the
        polymorphic serialization defined by this framework.
        """.replacingOccurrences(of: "\n", with: " ").replacingOccurrences(of: "  ", with: "\n")
    }
    
    public var jsonSchema: URL {
        URL(string: "\(self.interfaceName).json", relativeTo: kBDHJsonSchemaBaseURL)!
    }
    
    override init() {
        super.init([
            AnswerResultObject.examples().first!,
            CollectionResultObject.examples().first!,
            ErrorResultObject.examples().first!,
            FileResultObject.examples().first!,
            ResultObject.examples().first!,
            BranchNodeResultObject.examples().first!,
            AssessmentResultObject(),
        ])
    }
    
    public override class func typeDocumentProperty() -> DocumentProperty {
        .init(propertyType: .reference(SerializableResultType.documentableType()))
    }
    
    /// Insert the given example into the example array, replacing any existing example with the
    /// same `typeName` as one of the new example.
    @available(*, deprecated, message: "Inherit from ResultData directly")
    public func add(_ example: SerializableResultData) {
        try! add(example as ResultData)
    }
    
    /// Insert the given examples into the example array, replacing any existing examples with the
    /// same `typeName` as one of the new examples.
    @available(*, deprecated, message: "Inherit from ResultData directly")
    public func add(contentsOf newExamples: [SerializableResultData]) {
        try! add(contentsOf: newExamples as [ResultData])
    }
    
    private enum InterfaceKeys : String, OrderedEnumCodingKey, OpenOrderedCodingKey {
        case identifier, startDate, endDate
        var relativeIndex: Int { 2 }
    }
    
    public override class func codingKeys() -> [CodingKey] {
        var keys = super.codingKeys()
        keys.append(contentsOf: InterfaceKeys.allCases)
        return keys
    }
    
    public override class func isRequired(_ codingKey: CodingKey) -> Bool {
        guard let key = codingKey as? InterfaceKeys else {
            return super.isRequired(codingKey)
        }
        return key == .startDate || key == .identifier
    }
    
    public override class func documentProperty(for codingKey: CodingKey) throws -> DocumentProperty {
        guard let key = codingKey as? InterfaceKeys else {
            return try super.documentProperty(for: codingKey)
        }
        switch key {
        case .identifier:
            return .init(propertyType: .primitive(.string), propertyDescription:
                            "The identifier for the result.")
        case .startDate:
            return .init(propertyType: .format(.dateTime), propertyDescription:
                            "The start date timestamp for the result.")
        case .endDate:
            return .init(propertyType: .format(.dateTime), propertyDescription:
                            "The end date timestamp for the result.")
        }
    }
}

/// Abstract implementation to allow extending a result while retaining the serializable type.
@Serializable(subclassIndex: 0)
open class AbstractResultObject : Codable, MultiplatformTimestamp {

    public let identifier: String
    @SerialName("startDate") public var startDateTime: Date
    @SerialName("endDate") public var endDateTime: Date?

    /// Default initializer for this object.
    public init(identifier: String,
                startDate: Date = Date(),
                endDate: Date? = nil) {
        self.identifier = identifier
        self.startDateTime = startDate
        self.endDateTime = endDate
    }
    
    open class func codingKeys() -> [CodingKey] {
        CodingKeys.allCases
    }

    open class func isRequired(_ codingKey: CodingKey) -> Bool {
        if codingKey.stringValue == "typeName" {
            return true
        } else if let key = codingKey as? CodingKeys {
            return [.identifier, .startDateTime].contains(key)
        } else {
            return false
        }
    }

    open class func documentProperty(for codingKey: CodingKey) throws -> DocumentProperty {
        if codingKey.stringValue == "typeName" {
            return .init(propertyType: .primitive(.string), propertyDescription: "The polymorphic type")
        }
        guard let key = codingKey as? CodingKeys else {
            throw DocumentableError.invalidCodingKey(codingKey, "\(codingKey) is not recognized for this class")
        }
        switch key {
        case .identifier:
            return .init(propertyType: .primitive(.string))
        case .startDateTime, .endDateTime:
            return .init(propertyType: .format(.dateTime))
        }
    }
}
