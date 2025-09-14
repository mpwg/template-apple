// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TemplateProject",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .macCatalyst(.v15)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "TemplateProject",
            targets: ["TemplateProject"]
        ),
        .library(
            name: "TemplateProjectUI",
            targets: ["TemplateProjectUI"]
        )
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // Add your common dependencies here following these guidelines:

        // MARK: - Networking
        // Example: URLSession alternatives for advanced networking
        // .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.8.0"),

        // MARK: - UI and SwiftUI Extensions
        // Example: UI utilities and components
        // .package(url: "https://github.com/SwiftUIX/SwiftUIX.git", from: "0.1.0"),

        // MARK: - Utility Libraries
        // Example: Common utilities and extensions
        // .package(url: "https://github.com/apple/swift-algorithms.git", from: "1.0.0"),
        // .package(url: "https://github.com/apple/swift-collections.git", from: "1.0.0"),

        // MARK: - Testing Dependencies
        // Example: Testing utilities (only used in test targets)
        // .package(url: "https://github.com/pointfreeco/swift-snapshot-testing.git", from: "1.12.0"),

        // MARK: - Development Dependencies
        // These are commented out by default - uncomment as needed
        // .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.

        // MARK: - Main Library Target
        .target(
            name: "TemplateProject",
            dependencies: [
                // Add main dependencies here
                // Example:
                // "Alamofire",
                // .product(name: "Algorithms", package: "swift-algorithms"),
            ],
            path: "Sources/TemplateProject",
            resources: [
                // Add resource files here
                // .process("Resources")
            ],
            swiftSettings: [
                // Swift settings for this target
                .enableUpcomingFeature("BareSlashRegexLiterals"),
                .enableUpcomingFeature("ConciseMagicFile"),
                .enableUpcomingFeature("ForwardTrailingClosures"),
                .enableUpcomingFeature("ImportObjcForwardDeclarations"),
                .enableUpcomingFeature("DisableOutwardActorInference"),
                .enableExperimentalFeature("StrictConcurrency"),
            ]
        ),

        // MARK: - UI Library Target
        .target(
            name: "TemplateProjectUI",
            dependencies: [
                "TemplateProject",
                // Add UI-specific dependencies here
            ],
            path: "Sources/TemplateProjectUI",
            resources: [
                // Add UI resources here
                // .process("Resources"),
                // .copy("Assets.xcassets")
            ],
            swiftSettings: [
                .enableUpcomingFeature("BareSlashRegexLiterals"),
                .enableUpcomingFeature("ConciseMagicFile"),
                .enableUpcomingFeature("ForwardTrailingClosures"),
                .enableUpcomingFeature("ImportObjcForwardDeclarations"),
                .enableUpcomingFeature("DisableOutwardActorInference"),
                .enableExperimentalFeature("StrictConcurrency"),
            ]
        ),

        // MARK: - Test Targets
        .testTarget(
            name: "TemplateProjectTests",
            dependencies: [
                "TemplateProject",
                // Add testing dependencies here
                // .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
            ],
            path: "Tests/TemplateProjectTests",
            resources: [
                // Add test resources here
                // .copy("TestData")
            ]
        ),

        .testTarget(
            name: "TemplateProjectUITests",
            dependencies: [
                "TemplateProjectUI",
                "TemplateProject",
                // Add UI testing dependencies here
            ],
            path: "Tests/TemplateProjectUITests"
        )
    ],
    swiftLanguageVersions: [.v5]
)

// MARK: - Development Configuration
#if os(macOS)
// Add macOS-specific configurations here if needed
#endif

#if os(iOS)
// Add iOS-specific configurations here if needed
#endif

// MARK: - Conditional Dependencies
// Example of conditional dependencies based on platform or other conditions
/*
#if canImport(UIKit)
// iOS/Mac Catalyst specific dependencies
package.dependencies.append(
    .package(url: "https://github.com/example/ios-specific-package.git", from: "1.0.0")
)
#endif

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
// macOS-specific dependencies
package.dependencies.append(
    .package(url: "https://github.com/example/macos-specific-package.git", from: "1.0.0")
)
#endif
*/