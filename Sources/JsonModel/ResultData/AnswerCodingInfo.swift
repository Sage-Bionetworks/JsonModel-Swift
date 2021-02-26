//
//  AnswerCodingInfo.swift
//
//
//  Copyright © 2020-2021 Sage Bionetworks. All rights reserved.
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

import Foundation

/// The coding information for an answer. This allows for adding custom information to the "kind" of question because
/// JSON only supports a small subset of value types that are often encoded and can be described using JSON Schema
/// or Swagger.
public protocol AnswerCodingInfo : PolymorphicTyped, DictionaryRepresentable {

    /// The `JsonType` for the base value.
    var baseType: JsonType { get }
    
    /// Decode the JsonElement for this AnswerType from the given decoder.
    ///
    /// - parameter decoder: The nested decoder for this json element.
    /// - returns: The decoded value or `nil` if the value is not present.
    /// - throws: `DecodingError` if the encountered stored value cannot be decoded.
    func decodeValue(from decoder: Decoder) throws -> JsonElement
    
    /// Decode a `JsonElement` into the expected class type.
    ///
    /// - parameter jsonValue: The JSON value (from an array or dictionary) with the answer.
    /// - returns: The decoded value or `nil` if the value is not present.
    /// - throws: `DecodingError` if the encountered stored value cannot be decoded.
    func decodeAnswer(from jsonValue: JsonElement?) throws -> Any?
    
    /// Returns a `JsonElement` that is encoded for this answer type from the given value.
    ///
    /// - parameter value: The value to encode.
    /// - returns: The JSON serializable object for this encodable.
    func encodeAnswer(from value: Any?) throws -> JsonElement
}

public final class AnswerCodingInfoSerializer : AbstractPolymorphicSerializer, PolymorphicSerializer {
    public var documentDescription: String? {
        """
        `AnswerCodingInfo` is used to allow carrying additional information about the properties of a
        JSON-encoded `AnswerResult`.
        """.replacingOccurrences(of: "\n", with: " ").replacingOccurrences(of: "  ", with: "\n")
    }
    
    override init() {
        examples = [
            AnswerCodingInfoArray.examples().first!,
            AnswerCodingInfoBoolean.examples().first!,
            AnswerCodingInfoDateTime.examples().first!,
            AnswerCodingInfoInteger.examples().first!,
            AnswerCodingInfoMeasurement.examples().first!,
            AnswerCodingInfoNumber.examples().first!,
            AnswerCodingInfoObject.examples().first!,
            AnswerCodingInfoString.examples().first!,
        ]
    }
    
    public private(set) var examples: [AnswerCodingInfo]
    
    public override class func typeDocumentProperty() -> DocumentProperty {
        .init(propertyType: .reference(AnswerCodingInfoType.documentableType()))
    }
    
    public func add(_ example: AnswerCodingInfo) {
        if let idx = examples.firstIndex(where: { $0.typeName == example.typeName }) {
            examples.remove(at: idx)
        }
        examples.append(example)
    }
}

public protocol SerializableAnswerCodingInfo : AnswerCodingInfo, PolymorphicRepresentable, Encodable {
    var serializableType: AnswerCodingInfoType { get }
}

extension SerializableAnswerCodingInfo {
    public var typeName: String { serializableType.stringValue }
    
    public func jsonDictionary() throws -> [String : JsonSerializable] {
        try jsonEncodedDictionary()
    }
}

public struct AnswerCodingInfoType : TypeRepresentable, Codable, Hashable {
    public let rawValue: String
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    public init(jsonType: JsonType) {
        self.rawValue = jsonType.rawValue
    }
    
    static public let measurement: AnswerCodingInfoType = "measurement"
    static public let dateTime: AnswerCodingInfoType = "date-time"
    static public let string: AnswerCodingInfoType = AnswerCodingInfoType(jsonType: .string)
    static public let number: AnswerCodingInfoType = AnswerCodingInfoType(jsonType: .number)
    static public let integer: AnswerCodingInfoType = AnswerCodingInfoType(jsonType: .integer)
    static public let boolean: AnswerCodingInfoType = AnswerCodingInfoType(jsonType: .boolean)
    static public let array: AnswerCodingInfoType = AnswerCodingInfoType(jsonType: .array)
    static public let object: AnswerCodingInfoType = AnswerCodingInfoType(jsonType: .object)
    static public let null: AnswerCodingInfoType = AnswerCodingInfoType(jsonType: .null)
    
    static func allStandardTypes() -> [AnswerCodingInfoType] {
        return [.array, .boolean, .dateTime, .integer, .measurement, .null, .number, .object]
    }
}

extension AnswerCodingInfoType : ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }
}

extension AnswerCodingInfoType : DocumentableStringLiteral {
    public static func examples() -> [String] {
        allStandardTypes().map { $0.rawValue }
    }
}

public protocol BaseAnswerCodingInfo : SerializableAnswerCodingInfo {
    static var defaultJsonType: JsonType { get }
}

extension BaseAnswerCodingInfo {
    public var typeName: String { serializableType.rawValue }
    
    public var baseType: JsonType {
        return type(of: self).defaultJsonType
    }
}

extension JsonType {
    public var AnswerCodingInfo : AnswerCodingInfo {
        switch self {
        case .boolean:
            return AnswerCodingInfoBoolean()
        case .string:
            return AnswerCodingInfoString()
        case .number:
            return AnswerCodingInfoNumber()
        case .integer:
            return AnswerCodingInfoInteger()
        case .null:
            return AnswerCodingInfoNull()
        case .array:
            return AnswerCodingInfoArray()
        case .object:
            return AnswerCodingInfoObject()
        }
    }
}

extension AnswerCodingInfo {
    fileprivate func decodingError(_ codingPath: [CodingKey] = []) -> DecodingError {
        let context = DecodingError.Context(codingPath: codingPath,
                                            debugDescription: "Could not decode the value into the expected JsonType for \(self)")
        return DecodingError.dataCorrupted(context)
    }
    fileprivate func encodingError(_ value: Any, _ codingPath: [CodingKey] = []) -> EncodingError {
        let context = EncodingError.Context(codingPath: codingPath,
                                            debugDescription: "Could not encode \(value) to the expected JsonType for \(self)")
        return EncodingError.invalidValue(value, context)
    }
}

public struct AnswerCodingInfoObject : BaseAnswerCodingInfo, Codable, Hashable {
    private enum CodingKeys : String, CodingKey, CaseIterable {
        case serializableType = "type"
    }
    public static let defaultJsonType: JsonType = .object
    public static let defaultType: AnswerCodingInfoType = .object
    public private(set) var serializableType: AnswerCodingInfoType = Self.defaultType
    public init() {
    }
    
    public func decodeValue(from decoder: Decoder) throws -> JsonElement {
        let obj = try JsonElement(from: decoder)
        switch obj {
        case .null, .object(_):
            return obj
        default:
            throw decodingError(decoder.codingPath)
        }
    }
    
    public func decodeAnswer(from jsonValue: JsonElement?) throws -> Any? {
        guard let value = jsonValue, value != .null else { return nil }
        guard case .object(let obj) = value else {
            throw decodingError()
        }
        return obj
    }
    
    public func encodeAnswer(from value: Any?) throws -> JsonElement {
        guard let value = value else { return .null }
        if let jsonElement = value as? JsonElement, case .object(_) = jsonElement {
            return jsonElement
        }
        else if let obj = value as? NSDictionary {
            return JsonElement(obj)
        }
        else {
            throw encodingError(value)
        }
    }
}

public struct AnswerCodingInfoString : BaseAnswerCodingInfo, Codable, Hashable {
    private enum CodingKeys : String, CodingKey, CaseIterable {
        case serializableType = "type"
    }
    public static let defaultJsonType: JsonType = .string
    public static let defaultType: AnswerCodingInfoType = .string
    public private(set) var serializableType: AnswerCodingInfoType = Self.defaultType
    public init() {
    }
    
    public func decodeValue(from decoder: Decoder) throws -> JsonElement {
        let obj = try JsonElement(from: decoder)
        switch obj {
        case .null, .string(_):
            return obj
        default:
            throw decodingError(decoder.codingPath)
        }
    }
    
    public func decodeAnswer(from jsonValue: JsonElement?) throws -> Any? {
        guard let value = jsonValue, value != .null else { return nil }
        guard case .string(let obj) = value else {
            throw decodingError()
        }
        return obj
    }
    
    public func encodeAnswer(from value: Any?) throws -> JsonElement {
        guard let value = value else { return .null }
        if let jsonElement = value as? JsonElement, case .string(_) = jsonElement {
            return jsonElement
        }
        else {
            if let comparableValue = value as? CustomStringConvertible {
                return .string(comparableValue.description)
            }
            else {
                return .string("\(value)")
            }
        }
    }
}

public struct AnswerCodingInfoBoolean : BaseAnswerCodingInfo, Codable, Hashable {
    private enum CodingKeys : String, CodingKey, CaseIterable {
        case serializableType = "type"
    }
    public static let defaultJsonType: JsonType = .boolean
    public static let defaultType: AnswerCodingInfoType = .boolean
    public private(set) var serializableType: AnswerCodingInfoType = Self.defaultType
    public init() {
    }
    
    public func decodeValue(from decoder: Decoder) throws -> JsonElement {
        let obj = try JsonElement(from: decoder)
        switch obj {
        case .null, .boolean(_):
            return obj
        case .integer(let value):
            return .boolean((value as NSNumber).boolValue)
        case .number(let value):
            return .boolean(value.jsonNumber()?.boolValue ?? false)
        case .string(let value):
            return .boolean((value as NSString).boolValue)
        default:
            throw decodingError(decoder.codingPath)
        }
    }
    
    public func decodeAnswer(from jsonValue: JsonElement?) throws -> Any? {
        guard let value = jsonValue, value != .null else { return nil }
        switch value {
        case .boolean(let boolValue):
            return boolValue
        case .integer(let intValue):
            return intValue != 0
        case .number(let numValue):
            return numValue.jsonNumber()?.boolValue
        case .string(let stringValue):
            return (stringValue as NSString).boolValue
        default:
            throw decodingError()
        }
    }
    
    public func encodeAnswer(from value: Any?) throws -> JsonElement {
        guard let value = value else { return .null }
        if let jsonElement = value as? JsonElement, case .boolean(_) = jsonElement {
            return jsonElement
        }
        else if let obj = value as? Bool {
            return .boolean(obj)
        }
        else {
            throw encodingError(value)
        }
    }
}

public struct AnswerCodingInfoInteger : BaseAnswerCodingInfo, Codable, Hashable {
    private enum CodingKeys : String, CodingKey, CaseIterable {
        case serializableType = "type"
    }
    public static let defaultJsonType: JsonType = .integer
    public static let defaultType: AnswerCodingInfoType = .integer
    public private(set) var serializableType: AnswerCodingInfoType = Self.defaultType
    public init() {
    }
    
    public func decodeValue(from decoder: Decoder) throws -> JsonElement {
        let obj = try JsonElement(from: decoder)
        switch obj {
        case .null, .integer(_):
            return obj
        case .number(let value):
            return .integer(value.jsonNumber()?.intValue ?? 0)
        case .string(let value):
            return .integer((value as NSString).integerValue)
        default:
            throw decodingError(decoder.codingPath)
        }
    }
    
    public func decodeAnswer(from jsonValue: JsonElement?) throws -> Any? {
        guard let value = jsonValue, value != .null else { return nil }
        switch value {
        case .integer(let intValue):
            return intValue
        case .number(let numValue):
            return numValue.jsonNumber()?.intValue
        case .string(let stringValue):
            return (stringValue as NSString).integerValue
        default:
            throw decodingError()
        }
    }
    
    public func encodeAnswer(from value: Any?) throws -> JsonElement {
        guard let value = value else { return .null }
        if let jsonElement = value as? JsonElement, case .integer(_) = jsonElement {
            return jsonElement
        }
        else if let num = (value as? NSNumber) ?? (value as? JsonNumber)?.jsonNumber() {
            return .integer(num.intValue)
        }
        else {
            throw encodingError(value)
        }
    }
}

public struct AnswerCodingInfoNumber : BaseAnswerCodingInfo, Codable, Hashable {
    private enum CodingKeys : String, CodingKey, CaseIterable {
        case serializableType = "type"
    }
    public static let defaultJsonType: JsonType = .number
    public static let defaultType: AnswerCodingInfoType = .number
    public private(set) var serializableType: AnswerCodingInfoType = Self.defaultType
    public init() {
    }
}
extension AnswerCodingInfoNumber : RSDNumberAnswerCodingInfo {
}

protocol RSDNumberAnswerCodingInfo : AnswerCodingInfo {
}

extension RSDNumberAnswerCodingInfo {
    public func decodeValue(from decoder: Decoder) throws -> JsonElement {
        let obj = try JsonElement(from: decoder)
        switch obj {
        case .null, .number(_):
            return obj
        case .integer(let value):
            return .number(value)
        case .string(let value):
            return .number((value as NSString).doubleValue)
        default:
            throw decodingError(decoder.codingPath)
        }
    }
    
    public func decodeAnswer(from jsonValue: JsonElement?) throws -> Any? {
        guard let value = jsonValue, value != .null else { return nil }
        switch value {
        case .integer(let intValue):
            return intValue
        case .number(let numValue):
            return numValue
        case .string(let stringValue):
            return (stringValue as NSString).doubleValue
        default:
            throw decodingError()
        }
    }
    
    public func encodeAnswer(from value: Any?) throws -> JsonElement {
        guard let value = value else { return .null }
        if let jsonElement = value as? JsonElement, case .number(_) = jsonElement {
            return jsonElement
        }
        else if let num = (value as? JsonNumber) ?? (value as? NSNumber)?.doubleValue {
            return .number(num)
        }
        else {
            throw encodingError(value)
        }
    }
}

public struct AnswerCodingInfoNull : BaseAnswerCodingInfo, Codable, Hashable {
    private enum CodingKeys : String, CodingKey, CaseIterable {
        case serializableType = "type"
    }
    public static let defaultJsonType: JsonType = .null
    public static let defaultType: AnswerCodingInfoType = .null
    public private(set) var serializableType: AnswerCodingInfoType = Self.defaultType
    public init() {
    }
    
    public func decodeValue(from decoder: Decoder) throws -> JsonElement {
        throw decodingError(decoder.codingPath)
    }
    
    public func decodeAnswer(from jsonValue: JsonElement?) throws -> Any? {
        throw decodingError()
    }
    
    public func encodeAnswer(from value: Any?) throws -> JsonElement {
        return .null
    }
}

public struct AnswerCodingInfoArray : SerializableAnswerCodingInfo, Codable, Hashable {
    private enum CodingKeys : String, CodingKey, CaseIterable {
        case serializableType = "type", baseType, sequenceSeparator
    }
    public static let defaultType: AnswerCodingInfoType = .array
    public private(set) var serializableType: AnswerCodingInfoType = Self.defaultType
    public let baseType: JsonType
    public let sequenceSeparator: String?
    public init(baseType: JsonType = .string, sequenceSeparator: String? = nil) {
        self.baseType = baseType
        self.sequenceSeparator = sequenceSeparator
    }
    
    public func decodeValue(from decoder: Decoder) throws -> JsonElement {
        let obj = try JsonElement(from: decoder)
        return try _decodeArray(obj, decoder.codingPath)
    }
    
    private func _decodeArray(_ obj: JsonElement, _ codingPath: [CodingKey]) throws -> JsonElement {
        if case .string(let stringValue) = obj,
            let separator = sequenceSeparator {
            let stringArray = stringValue.components(separatedBy: separator)
            let arr: [JsonSerializable] = try stringArray.map {
                switch self.baseType {
                case .integer:
                    return ($0 as NSString).integerValue
                case .boolean:
                    return ($0 as NSString).boolValue
                case .number:
                    return ($0 as NSString).doubleValue
                case .string:
                    return $0
                default:
                    let context = DecodingError.Context(codingPath: codingPath,
                                                        debugDescription: "A base type of `object` is not valid for an AnswerCodingInfoArray with a non-nil separator")
                    throw DecodingError.dataCorrupted(context)
                }
            }
            return .array(arr)
        }
        else if case .array(_) = obj {
            return obj
        }
        else {
            throw decodingError(codingPath)
        }
    }
    
    public func decodeAnswer(from jsonValue: JsonElement?) throws -> Any? {
        guard let obj = jsonValue else { return nil }
        let convertedObj = try _decodeArray(obj, [])
        guard case .array(let arr) = convertedObj else {
            throw decodingError()
        }
        return arr
    }
    
    public func encodeAnswer(from value: Any?) throws -> JsonElement {
        guard let value = value else { return .null }
        let obj = (value as? JsonElement)?.jsonObject() ?? value
        let arr: [Any] = (obj as? [Any]) ?? [obj]
        if let separator = sequenceSeparator {
            let str = arr.map {
                if let comparableValue = $0 as? CustomStringConvertible {
                    return comparableValue.description
                }
                else {
                    return "\($0)"
                }
            }.joined(separator: separator)
            return .string(str)
        }
        else {
            return .array(arr.jsonArray())
        }
    }
}

public struct AnswerCodingInfoDateTime : BaseAnswerCodingInfo, Codable, Hashable {
    private enum CodingKeys : String, CodingKey, CaseIterable {
        case serializableType = "type", _codingFormat = "codingFormat"
    }
    public static let defaultJsonType: JsonType = .string
    public static let defaultType: AnswerCodingInfoType = .dateTime
    public private(set) var serializableType: AnswerCodingInfoType = Self.defaultType
    
    public var codingFormat: String {
        _codingFormat ?? ISO8601TimestampFormatter.dateFormat
    }
    private let _codingFormat: String?
    
    public var formatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = codingFormat
        return formatter
    }
    
    public init(codingFormat: String? = nil) {
        self._codingFormat = codingFormat
    }
    
    public func decodeValue(from decoder: Decoder) throws -> JsonElement {
        let obj = try JsonElement(from: decoder)
        switch obj {
        case .null, .string(_):
            return obj
        default:
            throw decodingError(decoder.codingPath)
        }
    }
    
    public func decodeAnswer(from jsonValue: JsonElement?) throws -> Any? {
        guard let value = jsonValue else { return nil }
        guard case .string(let obj) = value else {
            throw decodingError()
        }
        return formatter.date(from: obj)
    }
    
    public func encodeAnswer(from value: Any?) throws -> JsonElement {
        guard let value = value else { return .null }
        if let jsonElement = value as? JsonElement, case .string(_) = jsonElement {
            return jsonElement
        }
        else if let stringValue = value as? String {
            return .string(stringValue)
        }
        else if let dateValue = value as? Date {
            let stringValue = formatter.string(from: dateValue)
            return .string(stringValue)
        }
        else {
            throw encodingError(value)
        }
    }
}

public struct AnswerCodingInfoMeasurement : BaseAnswerCodingInfo, Codable, Hashable {
    private enum CodingKeys : String, CodingKey, CaseIterable {
        case serializableType = "type", unit
    }
    public static let defaultJsonType: JsonType = .number
    public static let defaultType: AnswerCodingInfoType = .measurement
    public private(set) var serializableType: AnswerCodingInfoType = Self.defaultType
    public let unit: String?
    
    public init(unit: String? = nil) {
        self.unit = unit
    }
}
extension AnswerCodingInfoMeasurement : RSDNumberAnswerCodingInfo {
}

// MARK: Documentable

protocol AnswerCodingInfoDocumentable {
    static func exampleTypeAndValues() -> [(AnswerCodingInfo, JsonElement)]
}

struct AnswerCodingInfoExamples {
    
    static func examplesWithValues() -> [(AnswerCodingInfo, JsonElement)] {
        documentableTypes.flatMap { $0.exampleTypeAndValues() }
    }
    
    static let documentableTypes: [AnswerCodingInfoDocumentable.Type] = [
        AnswerCodingInfoBoolean.self,
        AnswerCodingInfoInteger.self,
        AnswerCodingInfoNumber.self,
        AnswerCodingInfoObject.self,
        AnswerCodingInfoString.self,
        AnswerCodingInfoArray.self,
        AnswerCodingInfoDateTime.self,
        AnswerCodingInfoMeasurement.self,
    ]
}

extension AnswerCodingInfoObject : AnswerCodingInfoDocumentable, DocumentableStruct {
    public static func codingKeys() -> [CodingKey] { CodingKeys.allCases }
    public static func isRequired(_ codingKey: CodingKey) -> Bool { true }
    public static func documentProperty(for codingKey: CodingKey) throws -> DocumentProperty {
        .init(constValue: defaultType)
    }
    
    public static func examples() -> [AnswerCodingInfoObject] {
        exampleTypeAndValues().map { $0.0 as! Self }
    }

    static func exampleTypeAndValues() -> [(AnswerCodingInfo, JsonElement)] {
        [(AnswerCodingInfoObject(), .object(["foo":"ba"]))]
    }
}

extension AnswerCodingInfoString : AnswerCodingInfoDocumentable, DocumentableStruct {
    public static func codingKeys() -> [CodingKey] { CodingKeys.allCases }
    public static func isRequired(_ codingKey: CodingKey) -> Bool { true }
    public static func documentProperty(for codingKey: CodingKey) throws -> DocumentProperty {
        .init(constValue: defaultType)
    }

    public static func examples() -> [AnswerCodingInfoString] {
        exampleTypeAndValues().map { $0.0 as! Self }
    }

    static func exampleTypeAndValues() -> [(AnswerCodingInfo, JsonElement)] {
        [(AnswerCodingInfoString(), .string("foo"))]
    }
}

extension AnswerCodingInfoBoolean : AnswerCodingInfoDocumentable, DocumentableStruct {
    public static func codingKeys() -> [CodingKey] { CodingKeys.allCases }
    public static func isRequired(_ codingKey: CodingKey) -> Bool { true }
    public static func documentProperty(for codingKey: CodingKey) throws -> DocumentProperty {
        .init(constValue: defaultType)
    }

    public static func examples() -> [AnswerCodingInfoBoolean] {
        exampleTypeAndValues().map { $0.0 as! Self }
    }

    static func exampleTypeAndValues() -> [(AnswerCodingInfo, JsonElement)] {
        [(AnswerCodingInfoBoolean(), .boolean(true))]
    }
}

extension AnswerCodingInfoInteger : AnswerCodingInfoDocumentable, DocumentableStruct {
    public static func codingKeys() -> [CodingKey] { CodingKeys.allCases }
    public static func isRequired(_ codingKey: CodingKey) -> Bool { true }
    public static func documentProperty(for codingKey: CodingKey) throws -> DocumentProperty {
        .init(constValue: defaultType)
    }

    public static func examples() -> [AnswerCodingInfoInteger] {
        exampleTypeAndValues().map { $0.0 as! Self }
    }

    static func exampleTypeAndValues() -> [(AnswerCodingInfo, JsonElement)] {
        [(AnswerCodingInfoInteger(), .integer(42))]
    }
}

extension AnswerCodingInfoNumber : AnswerCodingInfoDocumentable, DocumentableStruct {
    public static func codingKeys() -> [CodingKey] { CodingKeys.allCases }
    public static func isRequired(_ codingKey: CodingKey) -> Bool { true }
    public static func documentProperty(for codingKey: CodingKey) throws -> DocumentProperty {
        .init(constValue: defaultType)
    }

    public static func examples() -> [AnswerCodingInfoNumber] {
        exampleTypeAndValues().map { $0.0 as! Self }
    }

    static func exampleTypeAndValues() -> [(AnswerCodingInfo, JsonElement)] {
        [(AnswerCodingInfoNumber(), .number(3.14))]
    }
}

extension AnswerCodingInfoArray : AnswerCodingInfoDocumentable, DocumentableStruct {
    public static func codingKeys() -> [CodingKey] { CodingKeys.allCases }
    
    public static func isRequired(_ codingKey: CodingKey) -> Bool {
        guard let key = codingKey as? CodingKeys else { return false }
        return key == .serializableType || key == .baseType
    }
    
    public static func documentProperty(for codingKey: CodingKey) throws -> DocumentProperty {
        guard let key = codingKey as? CodingKeys else {
            throw DocumentableError.invalidCodingKey(codingKey, "\(codingKey) is not recognized for this class")
        }
        switch key {
        case .serializableType:
            return .init(constValue: defaultType)
        case .baseType:
            return .init(propertyType: .reference(JsonType.documentableType()))
        case .sequenceSeparator:
            return .init(propertyType: .primitive(.string))
        }
    }

    public static func examples() -> [AnswerCodingInfoArray] {
        exampleTypeAndValues().map { $0.0 as! Self }
    }
    
    static func exampleTypeAndValues() -> [(AnswerCodingInfo, JsonElement)] {
        [
            (AnswerCodingInfoArray(baseType: .number), .array([3.2, 5.1])),
            (AnswerCodingInfoArray(baseType: .integer), .array([1, 5])),
            (AnswerCodingInfoArray(baseType: .string), .array(["foo", "ba", "lalala"])),
        ]
    }
}

extension AnswerCodingInfoDateTime : AnswerCodingInfoDocumentable, DocumentableStruct {
    public static func codingKeys() -> [CodingKey] { CodingKeys.allCases }

    public static func isRequired(_ codingKey: CodingKey) -> Bool {
        guard let key = codingKey as? CodingKeys else { return false }
        return key == .serializableType
    }

    public static func documentProperty(for codingKey: CodingKey) throws -> DocumentProperty {
        guard let key = codingKey as? CodingKeys else {
            throw DocumentableError.invalidCodingKey(codingKey, "\(codingKey) is not recognized for this class")
        }
        switch key {
        case .serializableType:
            return .init(constValue: defaultType)
        case ._codingFormat:
            return .init(propertyType: .primitive(.string), propertyDescription: "The iso8601 format for the date-time components used by this answer type.")
        }
    }

    public static func examples() -> [AnswerCodingInfoDateTime] {
        exampleTypeAndValues().map { $0.0 as! Self }
    }
    
    static func exampleTypeAndValues() -> [(AnswerCodingInfo, JsonElement)] {
        [
            (AnswerCodingInfoDateTime(codingFormat: "yyyy-MM"), .string("2020-04")),
            (AnswerCodingInfoDateTime(codingFormat: "HH:mm"), .string("08:30")),
            (AnswerCodingInfoDateTime(), .string("2017-10-16T22:28:09.000-07:00")),
        ]
    }
}

extension AnswerCodingInfoMeasurement : AnswerCodingInfoDocumentable, DocumentableStruct {
    public static func codingKeys() -> [CodingKey] { CodingKeys.allCases }

    public static func isRequired(_ codingKey: CodingKey) -> Bool {
        guard let key = codingKey as? CodingKeys else { return false }
        return key == .serializableType
    }

    public static func documentProperty(for codingKey: CodingKey) throws -> DocumentProperty {
        guard let key = codingKey as? CodingKeys else {
            throw DocumentableError.invalidCodingKey(codingKey, "\(codingKey) is not recognized for this class")
        }
        switch key {
        case .serializableType:
            return .init(constValue: defaultType)
        case .unit:
            return .init(propertyType: .primitive(.string), propertyDescription: "The unit of measurement into which the value is converted for storage.")
        }
    }

    public static func examples() -> [AnswerCodingInfoMeasurement] {
        exampleTypeAndValues().map { $0.0 as! Self }
    }
    
    static func exampleTypeAndValues() -> [(AnswerCodingInfo, JsonElement)] {
        [(AnswerCodingInfoMeasurement(unit: "cm"), .number(170.2))]
    }
}

extension JsonElement {
    var codingInfo: AnswerCodingInfo {
        switch self {
        case .null:
            return AnswerCodingInfoNull()
        case .boolean(_):
            return AnswerCodingInfoBoolean()
        case .string(_):
            return AnswerCodingInfoString()
        case .integer(_):
            return AnswerCodingInfoInteger()
        case .number(_):
            return AnswerCodingInfoNumber()
        case .array(let arr):
            if arr is [Int] {
                return AnswerCodingInfoArray(baseType: .integer)
            } else if arr is [NSNumber] || arr is [JsonNumber] {
                return AnswerCodingInfoArray(baseType: .number)
            } else if arr is [String] {
                return AnswerCodingInfoArray(baseType: .string)
            } else {
                return AnswerCodingInfoArray(baseType: .object)
            }
        case .object(_):
            return AnswerCodingInfoObject()
        }
    }
}

