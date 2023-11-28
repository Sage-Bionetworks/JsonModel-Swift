//
//  ResultData.swift
//

import Foundation
import JsonModel

/// `ResultData` is the base protocol for an object that stores data.
///
///  syoung 12/09/2020 `ResultData` is included as a part of the JsonModel module to allow
///  progress and additions to be made to the frameworks used by SageResearch that are independent
///  of the version of https://github.com/Sage-Bionetworks/SageResearch-Apple.git that is
///  referenced by third-party frameworks. Our experience is that third-party developers will
///  pin to a specific version of SageResearch, which breaks the dependency model that we use
///  internally in our applications.
///
///  The work-around to this is to include a lightweight model here since this framework is fairly
///  static and in most cases where the `RSDResult` is referenced, those classes already import
///  JsonModel. This will allow us to divorce *our* code from SageResearch so that we can iterate
///  independently of third-party frameworks.
///
public protocol ResultData : PolymorphicTyped, Encodable, DictionaryRepresentable {
    
    /// The identifier associated with the task, step, or asynchronous action.
    var identifier: String { get }
    
    /// The start date timestamp for the result.
    var startDate: Date { get set }
    
    /// The end date timestamp for the result.
    var endDate: Date { get set }
    
    /// The `deepCopy()` method is intended to allow copying a result to retain the previous result
    /// when revisiting an action. Since a class with get/set variables will use a pointer to the instance
    /// this allows results to either be structs *or* classes and allows collections of results to use
    /// mapping to deep copy their children.
    func deepCopy() -> Self
}

/// Implementation of the interface used by Sage for cross-platform support where the serialized
/// ``endDate`` may be nil.
public protocol MultiplatformTimestamp {
    var startDateTime: Date { get set }
    var endDateTime: Date? { get set }
}
 
extension MultiplatformTimestamp {
    
    public var startDate: Date {
        get { self.startDateTime }
        set { self.startDateTime = newValue }
    }
    
    public var endDate: Date {
        get { self.endDateTime ?? self.startDateTime }
        set { self.endDateTime = newValue }
    }
}

public protocol MultiplatformResultData : ResultData, MultiplatformTimestamp, PolymorphicSerializableTyped {
}

extension ResultData {
    public func jsonDictionary() throws -> [String : JsonSerializable] {
        try jsonEncodedDictionary()
    }
}

/// `ResultObject` is a concrete implementation of the base result associated with a task, step, or asynchronous action
@Serializable
@SerialName("base")
public struct ResultObject : MultiplatformResultData {
    public let identifier: String
    @SerialName("startDate") public var startDateTime: Date = Date()
    @SerialName("endDate") public var endDateTime: Date? = nil
    
    public func deepCopy() -> ResultObject {
        self
    }
}

extension ResultObject : DocumentableStruct {
    public static func codingKeys() -> [CodingKey] {
        CodingKeys.allCases
    }
    
    public static func isRequired(_ codingKey: CodingKey) -> Bool {
        (codingKey as? CodingKeys).map { $0 == .endDateTime } ?? true
    }
    
    public static func documentProperty(for codingKey: CodingKey) throws -> DocumentProperty {
        guard let key = codingKey as? CodingKeys else {
            throw DocumentableError.invalidCodingKey(codingKey, "\(codingKey) is not recognized for this class")
        }
        switch key {
        case .typeName:
            return .init(constValue: serialTypeName)
        case .identifier:
            return .init(propertyType: .primitive(.string))
        case .startDateTime, .endDateTime:
            return .init(propertyType: .format(.dateTime))
        }
    }
    
    public static func examples() -> [ResultObject] {
        var result = ResultObject(identifier: "step1")
        result.startDateTime = ISO8601TimestampFormatter.date(from: "2017-10-16T22:28:09.000-07:00")!
        result.endDateTime = result.startDateTime.addingTimeInterval(5 * 60)
        return [result]
    }
}

