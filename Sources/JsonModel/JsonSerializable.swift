//
//  JsonSerializable.swift
//
//  Copyright © 2019-2020 Sage Bionetworks. All rights reserved.
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

/// Casting for any a JSON type object. Elements may be any one of the JSON types
/// (NSNull, NSNumber, String, Array<JsonSerializable>, Dictionary<String : JsonSerializable>).
/// This is a subset of ``JsonValue`` so all these objects comform to the `Encodable` protocol.
///
/// - note: `NSArray` and `NSDictionary` do not implement this protocol b/c they cannot be extended
/// using a generic `where` clause. 
public protocol JsonSerializable {
    func encode(to encoder: Encoder) throws
}

extension NSNull : JsonSerializable {
}

extension String : JsonSerializable {
}

extension NSString : JsonSerializable {
}

extension Array : JsonSerializable where Element == JsonSerializable {
}

extension Dictionary : JsonSerializable where Key == String, Value == JsonSerializable {
}

extension NSNumber : JsonSerializable {
}

extension Int : JsonSerializable {
}

extension Int8 : JsonSerializable {
}

extension Int16 : JsonSerializable {
}

extension Int32 : JsonSerializable {
}

extension Int64 : JsonSerializable {
}

extension UInt : JsonSerializable {
}

extension UInt8 : JsonSerializable {
}

extension UInt16 : JsonSerializable {
}

extension UInt32 : JsonSerializable {
}

extension UInt64 : JsonSerializable {
}

extension Bool : JsonSerializable {
}

extension Double : JsonSerializable {
}

extension Float : JsonSerializable {
}
