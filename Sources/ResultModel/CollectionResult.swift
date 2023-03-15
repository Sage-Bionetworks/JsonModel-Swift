//
//  CollectionResultObject.swift
//  
//

import Foundation
import JsonModel

/// A `CollectionResult` is used to describe a collection of results.
public protocol CollectionResult : AnyObject, ResultData, AnswerFinder {

    /// The collection of results. This can be the async results of a sensor recorder, a response
    /// to a service call, or the results from a form where all the fields are displayed together
    /// and the results do not represent a linear path. The results within this set should each
    /// have a unique identifier.
    var children: [ResultData] { get set }
}

public extension CollectionResult {
    
    /// The `CollectionResult` conformance to the `AnswerFinder` protocol.
    func findAnswer(with identifier: String) -> AnswerResult? {
        self.children.last(where: { $0.identifier == identifier }) as? AnswerResult
    }
    
    /// Insert the result at the end of the `children` collection and, if found,  remove the previous instance
    /// with the same identifier.
    /// - parameter result: The result to add to the input results.
    /// - returns: The previous result or `nil` if there wasn't one.
    @discardableResult
    func insert(_ result: ResultData) -> ResultData? {
        var previousResult: ResultData?
        if let idx = children.firstIndex(where: { $0.identifier == result.identifier }) {
            previousResult = children.remove(at: idx)
        }
        children.append(result)
        return previousResult
    }
    
    /// Remove the result with the given identifier.
    /// - parameter result: The result to remove from the input results.
    /// - returns: The previous result or `nil` if there wasn't one.
    @discardableResult
    func remove(with identifier: String) -> ResultData? {
        guard let idx = children.firstIndex(where: { $0.identifier == identifier }) else {
            return nil
        }
        return children.remove(at: idx)
    }
}

open class AbstractCollectionResultObject : AbstractResultObject {
    private enum CodingKeys : String, OrderedEnumCodingKey, OpenOrderedCodingKey {
        case children
        var relativeIndex: Int { 1 }
    }
    
    public var children: [ResultData]
    
    public init(identifier: String, children: [ResultData] = [], startDate: Date = Date(), endDate: Date? = nil) {
        self.children = children
        super.init(identifier: identifier, startDate: startDate, endDate: endDate)
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let resultsContainer = try container.nestedUnkeyedContainer(forKey: .children)
        self.children = try decoder.serializationFactory.decodePolymorphicArray(ResultData.self, from: resultsContainer)
        try super.init(from: decoder)
    }
    
    /// Encode the result to the given encoder.
    /// - parameter encoder: The encoder to use to encode this instance.
    /// - throws: `EncodingError`
    open override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        var nestedContainer = container.nestedUnkeyedContainer(forKey: .children)
        try nestedContainer.encodePolymorphic(children)
    }
    
    override open class func codingKeys() -> [CodingKey] {
        var keys = super.codingKeys()
        keys.append(contentsOf: CodingKeys.allCases)
        return keys
    }

    override open class func isRequired(_ codingKey: CodingKey) -> Bool {
        (codingKey as? CodingKeys).map { $0 == .children } ?? super.isRequired(codingKey)
    }
    
    override open class func documentProperty(for codingKey: CodingKey) throws -> DocumentProperty {
        guard let key = codingKey as? CodingKeys else {
            return try super.documentProperty(for: codingKey)
        }
        switch key {
        case .children:
            return .init(propertyType: .interfaceArray("\(ResultData.self)"), propertyDescription:
                            "The list of input results associated with this step or recorder.")
        }
    }
}

/// `CollectionResultObject` is used to include multiple results associated with a single action.
public final class CollectionResultObject : AbstractCollectionResultObject, SerializableResultData, CollectionResult {
    
    public override class func defaultType() -> SerializableResultType {
        .StandardTypes.collection.resultType
    }
    
    public func deepCopy() -> CollectionResultObject {
        let copyChildren = self.children.map { $0.deepCopy() }
        let copy = CollectionResultObject(identifier: self.identifier,
                                          children: copyChildren)
        copy.startDateTime = self.startDateTime
        copy.endDateTime = self.endDateTime
        return copy
    }
}

extension CollectionResultObject : DocumentableStruct {
    
    public static func examples() -> [CollectionResultObject] {
        let result = CollectionResultObject(identifier: "answers")
        result.startDateTime = ISO8601TimestampFormatter.date(from: "2017-10-16T22:28:09.000-07:00")!
        result.endDateTime = result.startDateTime.addingTimeInterval(5 * 60)
        result.children = AnswerResultObject.examples()
        return [result]
    }
}
