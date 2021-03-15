//
//  JsonElementResultObject.swift
//  
//
//  Copyright © 2020 Sage Bionetworks. All rights reserved.
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

/// `JsonElementResultObject` is a `ResultData` implementation that can be used to store simple
/// json values.
@available(*, deprecated, message: "Use `AnswerResultObject` instead.")
public final class JsonElementResultObject : SerializableResultData, AnswerResult {
    private enum CodingKeys : String, CodingKey, CaseIterable {
        case serializableType="type", identifier, jsonValue="value", startDate, endDate, questionText
    }
    public private(set) var serializableType: SerializableResultType = .jsonValue
    
    public let identifier: String
    public var jsonValue: JsonElement?
    public var questionText: String?
    public var startDate: Date
    public var endDate: Date
    
    public var jsonAnswerType: AnswerType? { _answerType }
    private var _answerType: AnswerType? = nil
    
    public init(identifier: String, value: JsonElement, questionText: String? = nil) {
        self.identifier = identifier
        self.startDate = Date()
        self.endDate = Date()
        self.jsonValue = value
        self._answerType = value.answerType
        self.questionText = questionText
    }
    
    public func deepCopy() -> JsonElementResultObject {
        let copy = JsonElementResultObject(identifier: identifier, value: jsonValue ?? .null, questionText: questionText)
        copy.startDate = self.startDate
        copy.endDate = self.endDate
        return copy
    }
}

@available(*, deprecated, message: "Use `AnswerResultObject` instead.")
extension JsonElementResultObject : DocumentableStruct {
    public static func codingKeys() -> [CodingKey] {
        CodingKeys.allCases
    }
    
    public static func isRequired(_ codingKey: CodingKey) -> Bool {
        guard let key = codingKey as? CodingKeys else { return false }
        return key == .serializableType || key == .identifier || key == .startDate || key == .endDate
    }
    
    public static func documentProperty(for codingKey: CodingKey) throws -> DocumentProperty {
        guard let key = codingKey as? CodingKeys else {
            throw DocumentableError.invalidCodingKey(codingKey, "\(codingKey) is not recognized for this class")
        }
        switch key {
        case .serializableType:
            return .init(constValue: SerializableResultType.jsonValue)
        case .identifier:
            return .init(propertyType: .primitive(.string))
        case .startDate, .endDate:
            return .init(propertyType: .format(.dateTime))
        case .jsonValue:
            return .init(propertyType: .any)
        case .questionText:
            return .init(propertyType: .primitive(.string))
        }
    }

    public static func examples() -> [JsonElementResultObject] {
        let date = ISO8601TimestampFormatter.date(from: "2017-10-16T22:28:09.000-07:00")!
        let values: [JsonElement] = [.string("foo"), .integer(42), .boolean(true)]
        return values.enumerated().map {
            let result = JsonElementResultObject(identifier: "\($0.offset)", value: $0.element)
            result.startDate = date
            result.endDate = date
            return result
        }
    }
}
