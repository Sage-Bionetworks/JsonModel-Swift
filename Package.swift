// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "JsonModel",
    platforms: [
        // Add support for all platforms starting from a specific version.
        .macOS(.v11),
        .iOS(.v14),
        .watchOS(.v6),
        .tvOS(.v14),
        .macCatalyst(.v14),
    ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "JsonModel",
            targets: ["JsonModel", "ResultModel"]),
    ],
    dependencies: [
        // Depend on the Swift 5.9 release of SwiftSyntax
        .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        
        // The library that can be used to implement polymorphic serialization, json schema documentation,
        // and JsonElement definitions.
        .target(
            name: "JsonModel",
            dependencies: [
                "SerializableMacros",
            ]
        ),
        .testTarget(
            name: "JsonModelTests",
            dependencies: ["JsonModel"]),
        
        // The base model library for JsonModel results.
        .target(
            name: "ResultModel",
            dependencies: ["JsonModel"]),
        .testTarget(
            name: "ResultModelTests",
            dependencies: ["ResultModel"]),
        
        // Macro implementation that performs the source transformation of a macro.
        .macro(
            name: "SerializableMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),

        // A test target used to develop the macro implementation.
        .testTarget(
            name: "SerializableTests",
            dependencies: [
                "SerializableMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
    ]
)
