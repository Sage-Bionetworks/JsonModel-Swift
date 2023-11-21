//
//  ResourceInfo.swift
//  
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


/// `DecodableBundleInfo` is a convenience protocol for setting the resource information on a
/// decoded object.
public protocol DecodableBundleInfo : Decodable, ResourceInfo {
    
    /// The bundle identifier. Decodable identifier that can be used to get the bundle.
    var bundleIdentifier : String? { get }
    
    /// A pointer to the bundle set by the factory (if applicable).
    var factoryBundle: ResourceBundle? { get set }
    
    /// The package name (if applicable)
    var packageName: String? { get set }
}
