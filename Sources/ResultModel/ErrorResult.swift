//
//  ErrorResultObject.swift
//  
//

import Foundation
import JsonModel

/// `ErrorResult` is a result that holds information about an error.
public protocol ErrorResult : ResultData {
    
    /// A description associated with an `NSError`.
    var errorDescription: String { get }
    
    /// A domain associated with an `NSError`.
    var errorDomain: String { get }
    
    /// The error code associated with an `NSError`.
    var errorCode: Int { get }
}

/// `ErrorResultObject` is a result that holds information about an error.
@Serializable
@SerialName("error")
public struct ErrorResultObject : ErrorResult, MultiplatformResultData, Equatable {

    public let identifier: String
    @SerialName("startDate") public var startDateTime: Date = Date()
    @SerialName("endDate") public var endDateTime: Date? = nil
    
    /// A description associated with an `NSError`.
    public let errorDescription: String
    
    /// A domain associated with an `NSError`.
    public let errorDomain: String
    
    /// The error code associated with an `NSError`.
    public let errorCode: Int
    
    /// Initialize using a description, domain, and code.
    /// - parameters:
    ///     - identifier: The identifier for the result.
    ///     - description: The description of the error.
    ///     - domain: The error domain.
    ///     - code: The error code.
    public init(identifier: String, description: String, domain: String, code: Int, startDate: Date = Date(), endDate: Date? = nil) {
        self.identifier = identifier
        self.startDateTime = startDate
        self.endDateTime = endDate
        self.errorDescription = description
        self.errorDomain = domain
        self.errorCode = code
    }
    
    /// Initialize using an error.
    /// - parameters:
    ///     - identifier: The identifier for the result.
    ///     - error: The error for the result.
    public init(identifier: String, error: Error) {
        self.identifier = identifier
        self.startDateTime = Date()
        self.errorDescription = (error as NSError).localizedDescription
        self.errorDomain = (error as NSError).domain
        self.errorCode = (error as NSError).code
    }
    
    public func deepCopy() -> ErrorResultObject { self }
}

extension ErrorResultObject : DocumentableStruct {
    public static func codingKeys() -> [CodingKey] {
        return CodingKeys.allCases
    }
    
    public static func isRequired(_ codingKey: CodingKey) -> Bool {
        true
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
        case .errorDomain:
            return .init(propertyType: .primitive(.string), propertyDescription:
                            "The error domain.")
        case .errorDescription:
            return .init(propertyType: .primitive(.string), propertyDescription:
                            "The description of the error.")
        case .errorCode:
            return .init(propertyType: .primitive(.integer), propertyDescription:
                            "The error code.")
        }
    }
    
    public static func examples() -> [ErrorResultObject] {
        return [ErrorResultObject(identifier: "errorResult", description: "example error", domain: "ExampleDomain", code: 1)]
    }
}
