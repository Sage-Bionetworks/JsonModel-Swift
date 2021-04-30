//
//  SerializationFactory.swift
//
//  Copyright © 2017-2020 Sage Bionetworks. All rights reserved.
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

public protocol FactoryRegistration : AnyObject {
    init()
    func isRegistered<T>(for type: T.Type, with typeName: String) -> Bool
}

fileprivate var registeredFactories = [String : SerializationFactory]()
extension FactoryRegistration {
    
    public static var defaultFactory : Self {
        let identifier = String(reflecting: self)
        if let factory = registeredFactories[identifier] {
            return factory as! Self
        }
        else {
            guard let factory = self.init() as? SerializationFactory else {
                fatalError("Registered Factory *must* be a subclass of `SerializationFactory`.")
            }
            registeredFactories[identifier] = factory
            return factory as! Self
        }
    }
    
    public static func factory(with identifier: String) -> SerializationFactory? {
        registeredFactories[identifier]
    }
    
    public static func factory<T>(for type: T.Type, with typeName: String) -> SerializationFactory? {
        registeredFactories.first { $0.value.isRegistered(for: type, with: typeName) }?.value
    }
}

/// `SerializationFactory` handles customization of decoding the elements of a json file. Applications can either
/// register custom elements or use override to decode them.
open class SerializationFactory : FactoryRegistration {
    
    public final var identifier: String { String(reflecting: type(of: self)) }
    
    // Initializer
    public required init() {
    }

    // MARK: Polymorphic Decodable
    
    public private(set) var serializerMap: [String : GenericSerializer] = [:]
        
    public final func registerSerializer(_ serializer: GenericSerializer) {
        serializerMap[serializer.interfaceName] = serializer
    }
    
    public final func registerSerializer<T>(_ serializer: GenericSerializer, for type: T.Type) {
        serializerMap["\(type)"] = serializer
    }
    
    open func serializer<T>(for type: T.Type) -> GenericSerializer? {
        serializerMap["\(type)"]
    }
    
    public final func isRegistered<T>(for type: T.Type, with typeName: String) -> Bool {
        guard let serializer = self.serializer(for: type) else { return false }
        return serializer.canDecode(typeName)
    }
    
    public final func decodePolymorphicArray<T>(_ type: T.Type, from container: UnkeyedDecodingContainer) throws -> [T] {
        var objects : [T] = []
        var mutableContainer = container
        while !mutableContainer.isAtEnd {
            let nestedDecoder = try mutableContainer.superDecoder()
            let object = try self.decodePolymorphicObject(type, from: nestedDecoder)
            objects.append(object)
        }
        return try self.mapDecodedArray(objects)
    }
    
    public final func decodePolymorphicObject<T>(_ type: T.Type, from decoder: Decoder) throws -> T {
        let name = "\(type)"
        guard let serializer = serializer(for: type) else {
            let context = DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Could not serializer for \(name) is not registered with factory: \(self).")
            throw DecodingError.typeMismatch(type, context)
        }
        try serializer.validate()
        let decodedObject: T = try {
            do {
                let obj = try serializer.decode(from: decoder)
                return try mapDecodedObject(type, object: obj, codingPath: decoder.codingPath)
            }
            catch PolymorphicSerializerError.exampleNotFound(let typeName) {
                debugPrint("WARNING!!! Using a default object is not a strategy that is supported by Kotlin serialization. '\(name)' for '\(typeName)' in \(decoder.codingPath)")
                return try self.decodeDefaultObject(type, from: decoder)
            }
            catch PolymorphicSerializerError.typeKeyNotFound {
                debugPrint("WARNING!!! Using a default object is not a strategy that is supported by Kotlin serialization. '\(name)' in \(decoder.codingPath)")
                return try self.decodeDefaultObject(type, from: decoder)
            }
        }()
        if let obj = decodedObject as? DecodableBundleInfo {
            var resource = obj
            resource.factoryBundle = decoder.bundle
            resource.packageName = decoder.packageName
            return resource as! T
        }
        else {
            return decodedObject
        }
    }
    
    /// If required, allow the factory to set up pointers or transform the decoded objects.
    open func mapDecodedArray<T>(_ objects : [T]) throws -> [T] { objects }
    
    /// If required, allow the factory to set up pointers or transform the decoded object.
    open func mapDecodedObject<T>(_ type: T.Type, object: Any, codingPath: [CodingKey]) throws -> T {
        guard let obj = object as? T else {
            let name = "\(type)"
            let context = DecodingError.Context(codingPath: codingPath, debugDescription: "Decoded object does not implement \(name).")
            throw DecodingError.typeMismatch(type, context)
        }
        return obj
    }

    open func decodeDefaultObject<T>(_ type: T.Type, from decoder: Decoder) throws -> T {
        let context = DecodingError.Context(codingPath: decoder.codingPath,
                                            debugDescription: "Default decoder is not implemented for \(type)")
        throw DecodingError.valueNotFound(type, context)
    }
    
    // MARK: Documentation
    
    /// Return the baseUrl for building documentation for the given `Documentable` object, or `nil`
    /// if undefined.
    open func baseUrl(for docRef: Documentable.Type) -> URL? {
        nil
    }
    
    /// Returns the Json Schema model name for the given class or struct.
    open func modelName(for className: String) -> String {
        className
    }
    
    /// An ordered array of the documentable interfaces included in this factory.
    open func documentableInterfaces() -> [DocumentableInterface] {
        serializerMap.map { $0.value as DocumentableInterface }.sorted(by: { $0.interfaceName < $1.interfaceName })
    }
    
    // MARK: Date Result Format
    
    /// Get the date result formatter to use for the given calendar components.
    ///
    /// | Returned Formatter | Description                                                         |
    /// |--------------------|:-------------------------------------------------------------------:|
    /// |`dateOnlyFormatter` | If only date components (year, month, day) are included.            |
    /// |`timeOnlyFormatter` | If only time components (hour, minute, second) are included.        |
    /// |`timestampFormatter`| If both date and time components are included.                      |
    ///
    /// - parameter calendarComponents: The calendar components to include.
    /// - returns: The appropriate date formatter.
    open func dateResultFormatter(from calendarComponents: Set<Calendar.Component>) -> DateFormatter {
        let hasDateComponents = calendarComponents.intersection([.year, .month, .day]).count > 0
        let hasTimeComponents = calendarComponents.intersection([.hour, .minute, .second]).count > 0
        if hasDateComponents && hasTimeComponents {
            return timestampFormatter
        } else if hasTimeComponents {
            return timeOnlyFormatter
        } else {
            return dateOnlyFormatter
        }
    }
    
    /// `DateFormatter` to use for coding date-only strings. Default = `_ISO8601DateOnlyFormatter`.
    open var dateOnlyFormatter: DateFormatter {
        return ISO8601DateOnlyFormatter
    }
    
    /// `DateFormatter` to use for coding time-only strings. Default = `_ISO8601TimeOnlyFormatter`.
    open var timeOnlyFormatter: DateFormatter {
        return ISO8601TimeOnlyFormatter
    }
    
    /// `DateFormatter` to use for coding timestamp strings that include both date and time components.
    /// Default = `_ISO8601TimestampFormatter`.
    open var timestampFormatter: DateFormatter {
        return ISO8601TimestampFormatter
    }
    
    /// The default coding strategy to use for non-conforming elements.
    open var nonConformingCodingStrategy: (positiveInfinity: String, negativeInfinity: String, nan: String)
        = ("Infinity", "-Infinity", "NaN")

    // MARK: Decoder
    
    /// Create a `JSONDecoder` with this factory assigned in the user info keys as the factory
    /// to use when decoding this object.
    open func createJSONDecoder(resourceInfo: ResourceInfo? = nil) -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom({ (decoder) -> Date in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            return try self.decodeDate(from: string, formatter: nil, codingPath: decoder.codingPath)
        })
        decoder.userInfo[.factory] = self
        decoder.userInfo[.bundle] = resourceInfo?.factoryBundle
        decoder.userInfo[.packageName] = resourceInfo?.packageName
        decoder.userInfo[.codingInfo] = CodingInfo()
        decoder.nonConformingFloatDecodingStrategy = .convertFromString(positiveInfinity: nonConformingCodingStrategy.positiveInfinity,
                                                                        negativeInfinity: nonConformingCodingStrategy.negativeInfinity,
                                                                        nan: nonConformingCodingStrategy.nan)
        decoder.dataDecodingStrategy = .base64
        return decoder
    }
    
    /// Create a `PropertyListDecoder` with this factory assigned in the user info keys as the factory
    /// to use when decoding this object.
    open func createPropertyListDecoder(resourceInfo: ResourceInfo? = nil) -> PropertyListDecoder {
        let decoder = PropertyListDecoder()
        decoder.userInfo[.factory] = self
        decoder.userInfo[.bundle] = resourceInfo?.factoryBundle
        decoder.userInfo[.packageName] = resourceInfo?.packageName
        decoder.userInfo[.codingInfo] = CodingInfo()
        return decoder
    }
    
    /// Decode a date from a string. This method is used during object decoding and is defined
    /// as `open` so that subclass factories can define their own formatters.
    ///
    /// This method uses drop-through to first check the `formatter` (if provided). If the date
    /// cannot be decoded using the expected *encoding* formatter, then the string will be inspected
    /// to see if it matches any of the expected formats for date and time, time only, or date only.
    ///
    /// - parameters:
    ///     - string:       The string to use in decoding the date.
    ///     - formatter:    A formatter to use.
    /// - returns: The date created from this string.
    open func decodeDate(from string: String, formatter: DateFormatter? = nil) -> Date? {
        if let dateFormatter = formatter, let date = dateFormatter.date(from: string) {
            return date
        } else if let date = timestampFormatter.date(from: string) {
            return date
        } else if let date = dateOnlyFormatter.date(from: string) {
            return date
        } else if let date = timeOnlyFormatter.date(from: string) {
            return date
        } else if let date = _oldTimeOnlyFormatter.date(from: string) {
            return date
        } else if let date = _androidTimestampFormatter.date(from: string) {
            return date
        } else {
            return nil
        }
    }
    
    /// syoung 11/06/2019 Discovered that this format does not match the format being used on Bridge.
    private lazy var _oldTimeOnlyFormatter: DateFormatter = {
        var formatter = ISO8601TimeOnlyFormatter
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()
    
    /// syoung 11/06/2019 Older Android devices do not support the timestamp formatter that we are
    /// using on iOS. Therefore, check the formatter for dates decoded from Android.
    private lazy var _androidTimestampFormatter: DateFormatter = {
        var formatter = ISO8601TimeOnlyFormatter
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return formatter
    }()
    
    public func decodeDate(from string: String, formatter: DateFormatter?, codingPath: [CodingKey]) throws -> Date {
        guard let date = decodeDate(from: string, formatter: formatter) else {
            let context = DecodingError.Context(codingPath: codingPath, debugDescription: "Could not decode \(string) into a date.")
            throw DecodingError.typeMismatch(Date.self, context)
        }
        return date
    }
    
    // MARK: Encoder
    
    /// Create a `JSONEncoder` with this factory assigned in the user info keys as the factory
    /// to use when encoding objects.
    open func createJSONEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom({ (date, encoder) in
            let string = self.encodeString(from: date, codingPath: encoder.codingPath)
            var container = encoder.singleValueContainer()
            try container.encode(string)
        })
        encoder.outputFormatting = .prettyPrinted
        encoder.userInfo[.factory] = self
        encoder.userInfo[.codingInfo] = CodingInfo()
        encoder.nonConformingFloatEncodingStrategy = .convertToString(positiveInfinity: nonConformingCodingStrategy.positiveInfinity,
                                                                        negativeInfinity: nonConformingCodingStrategy.negativeInfinity,
                                                                        nan: nonConformingCodingStrategy.nan)
        encoder.dataEncodingStrategy = .custom({ (data, encoder) in
            let string = self.encodeString(from: data, codingPath: encoder.codingPath)
            var container = encoder.singleValueContainer()
            try container.encode(string)
        })
        return encoder
    }
    
    /// Create a `PropertyListEncoder` with this factory assigned in the user info keys as the factory
    /// to use when encoding objects.
    open func createPropertyListEncoder() -> PropertyListEncoder {
        let encoder = PropertyListEncoder()
        encoder.userInfo[.factory] = self
        encoder.userInfo[.codingInfo] = CodingInfo()
        return encoder
    }
    
    /// Overridable method for encoding a date to a string. By default, this method uses the `timestampFormatter`
    /// as the date formatter.
    open func encodeString(from date: Date, codingPath: [CodingKey]) -> String {
        return timestampFormatter.string(from: date)
    }
    
    /// Overridable method for encoding data to a string. By default, this method uses base64 encoding.
    open func encodeString(from data: Data, codingPath: [CodingKey]) -> String {
        return data.base64EncodedString()
    }
}

/// Extension of CodingUserInfoKey to add keys used by the Codable objects in this framework.
extension CodingUserInfoKey {
    
    /// The key for the factory to use when coding.
    public static let factory = CodingUserInfoKey(rawValue: "Factory.factory")!
    
    /// The key for pointing to a specific bundle for the decoded resources.
    public static let bundle = CodingUserInfoKey(rawValue: "Factory.bundle")!
    
    /// The key for pointing to a specific bundle for the decoded resources.
    public static let packageName = CodingUserInfoKey(rawValue: "Factory.packageName")!
    
    /// The key for pointing to mutable coding info.
    public static let codingInfo = CodingUserInfoKey(rawValue: "Factory.codingInfo")!
}

/// `JSONDecoder` and `PropertyListDecoder` do not share a common protocol so extend them to be
/// able to create the appropriate decoder and set the userInfo keys as needed.
public protocol FactoryDecoder {
    func decode<T>(_ type: T.Type, from data: Data) throws -> T where T : Decodable
    var userInfo: [CodingUserInfoKey : Any] { get set }
}

extension JSONDecoder : FactoryDecoder {
}

extension PropertyListDecoder : FactoryDecoder {
}

extension FactoryDecoder {
    
    /// The factory to use when decoding.
    public var serializationFactory: SerializationFactory {
        return self.userInfo[.factory] as? SerializationFactory ?? SerializationFactory.defaultFactory
    }
}

/// Extension of Decoder to return the factory objects used by the Codable objects
/// in this framework.
extension Decoder {
    
    /// The factory to use when decoding.
    public var serializationFactory: SerializationFactory {
        return self.userInfo[.factory] as? SerializationFactory ?? SerializationFactory.defaultFactory
    }
    
    /// The default bundle to use for embedded resources.
    public var bundle: ResourceBundle? {
        return self.userInfo[.bundle] as? ResourceBundle
    }
    
    /// The default package to use for embedded resources.
    public var packageName: String? {
        return self.userInfo[.packageName] as? String
    }
    
    /// The coding info object to use when decoding.
    public var codingInfo: CodingInfo? {
        return self.userInfo[.codingInfo] as? CodingInfo
    }
}

/// `JSONEncoder` and `PropertyListEncoder` do not share a common protocol so extend them to be able
/// to create the appropriate decoder and set the userInfo keys as needed.
public protocol FactoryEncoder {
    func encode<T>(_ value: T) throws -> Data where T : Encodable
    var userInfo: [CodingUserInfoKey : Any] { get set }
}

extension JSONEncoder : FactoryEncoder {
}

extension PropertyListEncoder : FactoryEncoder {
}

/// Extension of Encoder to return the factory objects used by the Codable objects
/// in this framework.
extension Encoder {
    
    /// The factory to use when encoding.
    public var serializationFactory: SerializationFactory {
        return self.userInfo[.factory] as? SerializationFactory ?? SerializationFactory.defaultFactory
    }
    
    /// The coding info object to use when encoding.
    public var codingInfo: CodingInfo? {
        return self.userInfo[.codingInfo] as? CodingInfo
    }
}

/// `CodingInfo` is used as a pointer to a mutable class that can be used to assign any info that must be
/// mutated during the Decoding of an object.
public class CodingInfo {
    public var userInfo : [CodingUserInfoKey : Any] = [:]
}


