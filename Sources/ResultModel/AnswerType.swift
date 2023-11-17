//
//  AnswerType.swift
//
//

import Foundation
import JsonModel

/// The coding information for an answer. This allows for adding custom information to the "kind" of question because
/// JSON only supports a small subset of value types that are often encoded and can be described using JSON Schema
/// or Swagger.
public protocol AnswerType : PolymorphicTyped, Codable {

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

public final class AnswerTypeSerializer : GenericPolymorphicSerializer<AnswerType>, DocumentableInterface {
    public var documentDescription: String? {
        """
        `AnswerType` is used to allow carrying additional information about the properties of a
        JSON-encoded `AnswerResult`.
        """.replacingOccurrences(of: "\n", with: " ").replacingOccurrences(of: "  ", with: "\n")
    }
    
    public var jsonSchema: URL {
        URL(string: "\(self.interfaceName).json", relativeTo: kBDHJsonSchemaBaseURL)!
    }
    
    override init() {
        super.init([
            AnswerTypeArray.examples().first!,
            AnswerTypeBoolean.examples().first!,
            AnswerTypeDateTime.examples().first!,
            AnswerTypeDuration.examples().first!,
            AnswerTypeInteger.examples().first!,
            AnswerTypeMeasurement.examples().first!,
            AnswerTypeNumber.examples().first!,
            AnswerTypeObject.examples().first!,
            AnswerTypeString.examples().first!,
            AnswerTypeTime.examples().first!,
        ])
    }
}

public protocol BaseAnswerType : AnswerType {
}

public protocol DecimalAnswerType : BaseAnswerType {
    var significantDigits: Int? { get }
}

extension BaseAnswerType {
    
    public var baseType: JsonType {
        return JsonType(rawValue: typeName)!
    }
}

extension JsonType {
    public var answerType : AnswerType {
        switch self {
        case .boolean:
            return AnswerTypeBoolean()
        case .string:
            return AnswerTypeString()
        case .number:
            return AnswerTypeNumber()
        case .integer:
            return AnswerTypeInteger()
        case .null:
            return AnswerTypeNull()
        case .array:
            return AnswerTypeArray()
        case .object:
            return AnswerTypeObject()
        }
    }
}

extension AnswerType {
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

@Serializable
@SerialName("object")
public struct AnswerTypeObject : BaseAnswerType, Codable, Hashable {
    
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

@Serializable
@SerialName("string")
public struct AnswerTypeString : BaseAnswerType, Codable, Hashable {

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

@Serializable
@SerialName("boolean")
public struct AnswerTypeBoolean : BaseAnswerType, Codable, Hashable {

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

@Serializable
@SerialName("integer")
public struct AnswerTypeInteger : BaseAnswerType, Codable, Hashable {

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

@Serializable
@SerialName("number")
public struct AnswerTypeNumber : DecimalAnswerType, Codable, Hashable {

    public let significantDigits: Int?
    public init(significantDigits: Int? = nil) {
        self.significantDigits = significantDigits
    }
}
extension AnswerTypeNumber : NumberJsonType {
}

protocol NumberJsonType : AnswerType {
}

extension NumberJsonType {
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

@Serializable
@SerialName("null")
public struct AnswerTypeNull : BaseAnswerType, Codable, Hashable {

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

@Serializable
@SerialName("array")
public struct AnswerTypeArray : AnswerType, Codable, Hashable {

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
        switch obj {
        case .string(let stringValue):
            if let separator = sequenceSeparator {
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
                                                            debugDescription: "A base type of `object` is not valid for an AnswerTypeArray with a non-nil separator")
                        throw DecodingError.dataCorrupted(context)
                    }
                }
                return .array(arr)
            }
            else {
                throw decodingError(codingPath)
            }
        
        case .null, .array(_):
            return obj
        
        default:
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
        guard let value = value, !(value is NSNull), (value as? JsonElement) != .null
        else {
            return .null
        }
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

@Serializable
@SerialName("date-time")
public struct AnswerTypeDateTime : DateTimeAnswerType, Codable, Hashable {
    
    public let codingFormat: String
    
    public init(codingFormat: String = ISO8601TimestampFormatter.dateFormat) {
        self.codingFormat = codingFormat
    }
}

@Serializable
@SerialName("time")
public struct AnswerTypeTime : DateTimeAnswerType, Codable, Hashable {
    
    public let codingFormat: String
    
    public init(codingFormat: String = ISO8601TimeOnlyFormatter.dateFormat) {
        self.codingFormat = codingFormat
    }
}

public protocol DateTimeAnswerType : BaseAnswerType {
    var codingFormat: String { get }
}

extension DateTimeAnswerType {
    
    public var formatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = codingFormat
        return formatter
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

/// The duration answer type represents a duration of time where duration is measured in seconds.
@Serializable
@SerialName("duration")
public struct AnswerTypeDuration : DecimalAnswerType, Codable, Hashable {
    
    /// The units used to build the question for the participant.
    public let displayUnits: [DurationUnit]?
    
    /// The number of significant digits for the value in seconds.
    public let significantDigits: Int?
    
    public init(significantDigits: Int = 0, displayUnits: [DurationUnit] = DurationUnit.defaultDispayUnits) {
        self.displayUnits = displayUnits
        self.significantDigits = significantDigits
    }
}
extension AnswerTypeDuration : NumberJsonType {
}

public enum DurationUnit : String, StringEnumSet, DocumentableStringEnum {
    case hour, minute, second
    public static let defaultDispayUnits: [DurationUnit] = [.hour, .minute]
}

@Serializable
@SerialName("measurement")
public struct AnswerTypeMeasurement : DecimalAnswerType, Codable, Hashable {
    
    public let unit: String?
    public let significantDigits: Int?
    
    public init(unit: String? = nil, significantDigits: Int? = nil) {
        self.unit = unit
        self.significantDigits = significantDigits
    }
}
extension AnswerTypeMeasurement : NumberJsonType {
}

// MARK: Documentable

protocol AnswerTypeDocumentable {
    static func exampleTypeAndValues() -> [(AnswerType, JsonElement)]
}

struct AnswerTypeExamples {
    
    static func examplesWithValues() -> [(AnswerType, JsonElement)] {
        documentableTypes.flatMap { $0.exampleTypeAndValues() }
    }
    
    static let documentableTypes: [AnswerTypeDocumentable.Type] = [
        AnswerTypeBoolean.self,
        AnswerTypeInteger.self,
        AnswerTypeNumber.self,
        AnswerTypeObject.self,
        AnswerTypeString.self,
        AnswerTypeArray.self,
        AnswerTypeDateTime.self,
        AnswerTypeTime.self,
        AnswerTypeDuration.self,
        AnswerTypeMeasurement.self,
    ]
}

extension AnswerTypeObject : AnswerTypeDocumentable, DocumentableStruct {
    public static func codingKeys() -> [CodingKey] { CodingKeys.allCases }
    public static func isRequired(_ codingKey: CodingKey) -> Bool { true }
    public static func documentProperty(for codingKey: CodingKey) throws -> DocumentProperty {
        .init(propertyType: .primitive(.string))
    }
    
    public static func examples() -> [AnswerTypeObject] {
        exampleTypeAndValues().map { $0.0 as! Self }
    }

    static func exampleTypeAndValues() -> [(AnswerType, JsonElement)] {
        [(AnswerTypeObject(), .object(["foo":"ba"]))]
    }
}

extension AnswerTypeString : AnswerTypeDocumentable, DocumentableStruct {
    public static func codingKeys() -> [CodingKey] { CodingKeys.allCases }
    public static func isRequired(_ codingKey: CodingKey) -> Bool { true }
    public static func documentProperty(for codingKey: CodingKey) throws -> DocumentProperty {
        .init(propertyType: .primitive(.string))
    }

    public static func examples() -> [AnswerTypeString] {
        exampleTypeAndValues().map { $0.0 as! Self }
    }

    static func exampleTypeAndValues() -> [(AnswerType, JsonElement)] {
        [(AnswerTypeString(), .string("foo"))]
    }
}

extension AnswerTypeBoolean : AnswerTypeDocumentable, DocumentableStruct {
    public static func codingKeys() -> [CodingKey] { CodingKeys.allCases }
    public static func isRequired(_ codingKey: CodingKey) -> Bool { true }
    public static func documentProperty(for codingKey: CodingKey) throws -> DocumentProperty {
        .init(propertyType: .primitive(.string))
    }

    public static func examples() -> [AnswerTypeBoolean] {
        exampleTypeAndValues().map { $0.0 as! Self }
    }

    static func exampleTypeAndValues() -> [(AnswerType, JsonElement)] {
        [(AnswerTypeBoolean(), .boolean(true))]
    }
}

extension AnswerTypeInteger : AnswerTypeDocumentable, DocumentableStruct {
    public static func codingKeys() -> [CodingKey] { CodingKeys.allCases }
    public static func isRequired(_ codingKey: CodingKey) -> Bool { true }
    public static func documentProperty(for codingKey: CodingKey) throws -> DocumentProperty {
        .init(propertyType: .primitive(.string))
    }

    public static func examples() -> [AnswerTypeInteger] {
        exampleTypeAndValues().map { $0.0 as! Self }
    }

    static func exampleTypeAndValues() -> [(AnswerType, JsonElement)] {
        [(AnswerTypeInteger(), .integer(42))]
    }
}

extension AnswerTypeNumber : AnswerTypeDocumentable, DocumentableStruct {
    public static func codingKeys() -> [CodingKey] { CodingKeys.allCases }
    public static func isRequired(_ codingKey: CodingKey) -> Bool {
        guard let key = codingKey as? CodingKeys else { return false }
        return key == .typeName
    }
    public static func documentProperty(for codingKey: CodingKey) throws -> DocumentProperty {
        guard let key = codingKey as? CodingKeys else {
            throw DocumentableError.invalidCodingKey(codingKey, "\(codingKey) is not recognized for this class")
        }
        switch key {
        case .typeName:
            return .init(propertyType: .primitive(.string))
        case .significantDigits:
            return .init(propertyType: .primitive(.number), propertyDescription:
                            "The number of significant digits to use in encoding the answer.")
        }
    }

    public static func examples() -> [AnswerTypeNumber] {
        exampleTypeAndValues().map { $0.0 as! Self }
    }

    static func exampleTypeAndValues() -> [(AnswerType, JsonElement)] {
        [(AnswerTypeNumber(), .number(3.14))]
    }
}

extension AnswerTypeArray : AnswerTypeDocumentable, DocumentableStruct {
    public static func codingKeys() -> [CodingKey] { CodingKeys.allCases }
    
    public static func isRequired(_ codingKey: CodingKey) -> Bool {
        guard let key = codingKey as? CodingKeys else { return false }
        return key == .typeName || key == .baseType
    }
    
    public static func documentProperty(for codingKey: CodingKey) throws -> DocumentProperty {
        guard let key = codingKey as? CodingKeys else {
            throw DocumentableError.invalidCodingKey(codingKey, "\(codingKey) is not recognized for this class")
        }
        switch key {
        case .typeName:
            return .init(propertyType: .primitive(.string))
        case .baseType:
            return .init(propertyType: .reference(JsonType.documentableType()), propertyDescription:
                            "The base type of the array.")
        case .sequenceSeparator:
            return .init(propertyType: .primitive(.string), propertyDescription:
                            "The sequence separator to use for arrays that should be encoded as strings.")
        }
    }

    public static func examples() -> [AnswerTypeArray] {
        exampleTypeAndValues().map { $0.0 as! Self }
    }
    
    static func exampleTypeAndValues() -> [(AnswerType, JsonElement)] {
        [
            (AnswerTypeArray(baseType: .number), .array([3.2, 5.1])),
            (AnswerTypeArray(baseType: .integer), .array([1, 5])),
            (AnswerTypeArray(baseType: .string), .array(["foo", "ba", "lalala"])),
        ]
    }
}

extension AnswerTypeDateTime : AnswerTypeDocumentable, DocumentableStruct {
    public static func codingKeys() -> [CodingKey] { CodingKeys.allCases }

    public static func isRequired(_ codingKey: CodingKey) -> Bool {
        guard let key = codingKey as? CodingKeys else { return false }
        return key == .typeName
    }

    public static func documentProperty(for codingKey: CodingKey) throws -> DocumentProperty {
        guard let key = codingKey as? CodingKeys else {
            throw DocumentableError.invalidCodingKey(codingKey, "\(codingKey) is not recognized for this class")
        }
        switch key {
        case .typeName:
            return .init(propertyType: .primitive(.string))
        case .codingFormat:
            return .init(propertyType: .primitive(.string), propertyDescription:
                            "The iso8601 format for the date-time components used by this answer type.")
        }
    }

    public static func examples() -> [AnswerTypeDateTime] {
        exampleTypeAndValues().map { $0.0 as! Self }
    }
    
    static func exampleTypeAndValues() -> [(AnswerType, JsonElement)] {
        [
            (AnswerTypeDateTime(codingFormat: "yyyy-MM"), .string("2020-04")),
            (AnswerTypeDateTime(codingFormat: "HH:mm"), .string("08:30")),
            (AnswerTypeDateTime(), .string("2017-10-16T22:28:09.000-07:00")),
        ]
    }
}

extension AnswerTypeTime : AnswerTypeDocumentable, DocumentableStruct {
    public static func codingKeys() -> [CodingKey] { CodingKeys.allCases }

    public static func isRequired(_ codingKey: CodingKey) -> Bool {
        guard let key = codingKey as? CodingKeys else { return false }
        return key == .typeName
    }

    public static func documentProperty(for codingKey: CodingKey) throws -> DocumentProperty {
        guard let key = codingKey as? CodingKeys else {
            throw DocumentableError.invalidCodingKey(codingKey, "\(codingKey) is not recognized for this class")
        }
        switch key {
        case .typeName:
            return .init(propertyType: .primitive(.string))
        case .codingFormat:
            return .init(propertyType: .primitive(.string), propertyDescription:
                            "The iso8601 format for the time components used by this answer type.")
        }
    }

    public static func examples() -> [AnswerTypeTime] {
        exampleTypeAndValues().map { $0.0 as! Self }
    }
    
    static func exampleTypeAndValues() -> [(AnswerType, JsonElement)] {
        [
            (AnswerTypeTime(), .string("22:28:00.000")),
        ]
    }
}

extension AnswerTypeDuration : AnswerTypeDocumentable, DocumentableStruct {
    public static func codingKeys() -> [CodingKey] { CodingKeys.allCases }

    public static func isRequired(_ codingKey: CodingKey) -> Bool {
        guard let key = codingKey as? CodingKeys else { return false }
        return key == .typeName
    }

    public static func documentProperty(for codingKey: CodingKey) throws -> DocumentProperty {
        guard let key = codingKey as? CodingKeys else {
            throw DocumentableError.invalidCodingKey(codingKey, "\(codingKey) is not recognized for this class")
        }
        switch key {
        case .typeName:
            return .init(propertyType: .primitive(.string))
        case .displayUnits:
            return .init(propertyType: .referenceArray(DurationUnit.documentableType()), propertyDescription:
                            "The units used to display the duration as a question.")
        case .significantDigits:
            return .init(propertyType: .primitive(.number), propertyDescription:
                            "The number of significant digits to use in encoding the answer.")
        }
    }

    public static func examples() -> [AnswerTypeDuration] {
        exampleTypeAndValues().map { $0.0 as! Self }
    }
    
    static func exampleTypeAndValues() -> [(AnswerType, JsonElement)] {
        [(AnswerTypeDuration(), .number(75))]
    }
}

extension AnswerTypeMeasurement : AnswerTypeDocumentable, DocumentableStruct {
    public static func codingKeys() -> [CodingKey] { CodingKeys.allCases }

    public static func isRequired(_ codingKey: CodingKey) -> Bool {
        guard let key = codingKey as? CodingKeys else { return false }
        return key == .typeName
    }

    public static func documentProperty(for codingKey: CodingKey) throws -> DocumentProperty {
        guard let key = codingKey as? CodingKeys else {
            throw DocumentableError.invalidCodingKey(codingKey, "\(codingKey) is not recognized for this class")
        }
        switch key {
        case .typeName:
            return .init(propertyType: .primitive(.string))
        case .unit:
            return .init(propertyType: .primitive(.string), propertyDescription:
                            "The unit of measurement into which the value is converted for storage.")
        case .significantDigits:
            return .init(propertyType: .primitive(.number), propertyDescription:
                            "The number of significant digits to use in encoding the answer.")
        }
    }

    public static func examples() -> [AnswerTypeMeasurement] {
        exampleTypeAndValues().map { $0.0 as! Self }
    }
    
    static func exampleTypeAndValues() -> [(AnswerType, JsonElement)] {
        [(AnswerTypeMeasurement(unit: "cm"), .number(170.2))]
    }
}

public extension JsonElement {
    var answerType: AnswerType {
        switch self {
        case .null:
            return AnswerTypeNull()
        case .boolean(_):
            return AnswerTypeBoolean()
        case .string(_):
            return AnswerTypeString()
        case .integer(_):
            return AnswerTypeInteger()
        case .number(_):
            return AnswerTypeNumber()
        case .array(let arr):
            if arr is [Int] {
                return AnswerTypeArray(baseType: .integer)
            } else if arr is [NSNumber] || arr is [JsonNumber] {
                return AnswerTypeArray(baseType: .number)
            } else if arr is [String] {
                return AnswerTypeArray(baseType: .string)
            } else {
                return AnswerTypeArray(baseType: .object)
            }
        case .object(_):
            return AnswerTypeObject()
        }
    }
}

