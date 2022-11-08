//
//  ResultDataFactory.swift
//  
//

import Foundation
import JsonModel

/// `ResultDataFactory` is a subclass of the `SerializationFactory` that registers a serializer
/// for `JsonResultData` objects that can be used to deserialize the results.
open class ResultDataFactory : SerializationFactory {
    
    public let resultSerializer = ResultDataSerializer()
    public let answerTypeSerializer = AnswerTypeSerializer()
    
    public required init() {
        super.init()
        self.registerSerializer(resultSerializer)
        self.registerSerializer(answerTypeSerializer)
    }
}

