//
//  ResourceInfo.swift
//  
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

/// The resource info is used to generically describe codable info for loading resources from a
/// bundle or package.
public protocol ResourceInfo {

    // MARK: Apple
    
    /// The bundle for a given factory that was used to decode an object can use to load its
    /// resources. This is *always* a pointer to the `Bundle` from which a JSON file was decoded
    /// but is defined generically here so that the lowest level of the model does not include
    /// bundle information directly.
    var factoryBundle: ResourceBundle? { get }
    
    /// The identifier of the bundle within which the resource is embedded on Apple platforms.
    var bundleIdentifier: String? { get }
    
    
    // MARK: Android
    
    /// The package within which the resource is embedded on Android platforms.
    var packageName: String? { get }
}

/// A resource bundle is used on Apple platforms to point to the `Bundle` for the resource. It is
/// not directly referenced within this framework to avoid any Apple-specific resource handling
/// classes and to allow for testing.
public protocol ResourceBundle : AnyObject {
    
    /// The identifier of the bundle within which the resource is embedded on Apple platforms.
    var bundleIdentifier: String? { get }
}

extension Bundle : ResourceBundle {
}


/// `RSDDecodableBundleInfo` is a convenience protocol for setting the resource information on a
/// decoded object.
public protocol DecodableBundleInfo : Decodable, ResourceInfo {
    
    /// The bundle identifier. Decodable identifier that can be used to get the bundle.
    var bundleIdentifier : String? { get }
    
    /// A pointer to the bundle set by the factory (if applicable).
    var factoryBundle: ResourceBundle? { get set }
    
    /// The package name (if applicable)
    var packageName: String? { get set }
}
