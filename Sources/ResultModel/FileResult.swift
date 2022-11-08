//
//  FileResultObject.swift
//  
//

import Foundation
import JsonModel

/// `FileResult` is a result that holds a pointer to a file url.
public protocol FileResult : ResultData {
    
    /// The URL with the full path to the file-based result. This should *not*
    /// be encoded in the file result if the results are encoded and uploaded
    /// to a server. This is included for use in local file system management
    /// **only**.
    ///
    /// - note: It is the responsibility of the developer to ensure that the
    /// participant's private data is managed securely.
    var url: URL? { get }
    
    /// The relative path to the file-based result.
    var relativePath: String { get }
    
    /// The MIME content type of the result.
    /// - example: `"application/json"`
    var contentType: String? { get }
    
    /// The system clock uptime when the recorder was started (if applicable).
    var startUptime: TimeInterval? { get }
}

/// `FileResultObject` is a concrete implementation of a result that holds a pointer to a file url.
public struct FileResultObject : SerializableResultData, FileResult, MultiplatformTimestamp, Equatable {
    private enum CodingKeys : String, OrderedEnumCodingKey {
        case serializableType="type", identifier, startDateTime = "startDate", endDateTime = "endDate", relativePath, contentType, startUptime, jsonSchema
    }
    public private(set) var serializableType: SerializableResultType = .StandardTypes.file.resultType
    
    public let identifier: String
    public var startDateTime: Date
    public var endDateTime: Date?
    
    /// The system clock uptime when the recorder was started (if applicable).
    public let startUptime: TimeInterval?
    
    /// The URL with the full path to the file-based result. This should *not*
    /// be encoded in the file result.
    public private(set) var url: URL? = nil
    
    /// The relative path to the file-based result.
    public var relativePath: String
    
    /// The MIME content type of the result.
    public var contentType: String?
    
    /// The url for the json schema that defined the content if this file has a content type of "application/json".
    public var jsonSchema: URL?
    
    public init(identifier: String, url: URL, contentType: String? = nil, startUptime: TimeInterval? = nil, jsonSchema: URL? = nil) {
        self.identifier = identifier
        self.url = url
        self.relativePath = url.relativePath
        self.contentType = contentType
        self.jsonSchema = jsonSchema
        self.startUptime = startUptime
        self.startDateTime = Date()
    }
    
    public init(identifier: String, url: URL, rootSchema: DocumentableRootArray, startUptime: TimeInterval? = nil) {
        self.identifier = identifier
        self.url = url
        self.relativePath = url.relativePath
        self.contentType = "application/json"
        self.jsonSchema = rootSchema.jsonSchema
        self.startUptime = startUptime
        self.startDateTime = Date()
    }
    
    public func deepCopy() -> FileResultObject { self }
}

extension FileResultObject : FileArchivable {
    
    /// Build the archiveable or uploadable data for this result.
    public func buildArchivableFileData(at stepPath: String?) throws -> (fileInfo: FileInfo, data: Data)? {
        let filename = self.relativePath
        guard let url = self.url else { return nil }
        let manifest = FileInfo(filename: filename, timestamp: self.startDateTime, contentType: self.contentType, identifier: self.identifier, stepPath: stepPath, jsonSchema: self.jsonSchema)
        let data = try Data(contentsOf: url)
        return (manifest, data)
    }
}

extension FileResultObject : DocumentableStruct {
    public static func codingKeys() -> [CodingKey] {
        return CodingKeys.allCases
    }
    
    public static func isRequired(_ codingKey: CodingKey) -> Bool {
        guard let key = codingKey as? CodingKeys else { return false }
        return key == .identifier || key == .serializableType
    }
    
    public static func documentProperty(for codingKey: CodingKey) throws -> DocumentProperty {
        guard let key = codingKey as? CodingKeys else {
            throw DocumentableError.invalidCodingKey(codingKey, "\(codingKey) is not recognized for this class")
        }
        switch key {
        case .serializableType:
            return .init(constValue: SerializableResultType.StandardTypes.file.resultType)
        case .identifier:
            return .init(propertyType: .primitive(.string))
        case .startDateTime, .endDateTime:
            return .init(propertyType: .format(.dateTime))
        case .relativePath:
            return .init(propertyType: .primitive(.string), propertyDescription:
                            "The relative path to the file-based result.")
        case .contentType:
            return .init(propertyType: .primitive(.string), propertyDescription:
                            "The MIME content type of the result.")
        case .startUptime:
            return .init(propertyType: .primitive(.number), propertyDescription:
                            "The system clock uptime when the recorder was started (if applicable).")
        case .jsonSchema:
            return .init(propertyType: .format(.uri), propertyDescription:
                            "The URL for the json schema of the JSON for this file.")
        }
    }
    
    public static func examples() -> [FileResultObject] {
        var fileResult = FileResultObject(identifier: "fileResult", url: URL(string: "file://temp/foo.json")!, contentType: "application/json", startUptime: 1234.567, jsonSchema: URL(string: "file://temp/foo.schema.json")!)
        fileResult.startDateTime = ISO8601TimestampFormatter.date(from: "2017-10-16T22:28:09.000-07:00")!
        fileResult.endDateTime = fileResult.startDateTime.addingTimeInterval(5 * 60)
        return [fileResult]
    }
}
