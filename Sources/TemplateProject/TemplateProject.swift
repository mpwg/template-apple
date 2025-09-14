// TemplateProject.swift
//
// Main library module for the Template Project
// This file provides the core functionality and public API

import Foundation

/// Main Template Project library
///
/// This library provides core functionality for iOS and macOS applications
/// following modern Swift and platform best practices.
public struct TemplateProject {

    /// Library version
    public static let version = "1.0.0"

    /// Initialize the Template Project library
    public init() {}

    /// Example public method demonstrating the library API
    /// - Returns: A greeting message
    public func greet() -> String {
        return "Hello from Template Project!"
    }
}

/// Configuration for the Template Project library
public struct TemplateProjectConfiguration {

    /// Debug mode flag
    public let isDebugMode: Bool

    /// Application name
    public let applicationName: String

    /// Initialize configuration
    /// - Parameters:
    ///   - isDebugMode: Enable debug mode
    ///   - applicationName: Name of the application
    public init(isDebugMode: Bool = false, applicationName: String = "Template App") {
        self.isDebugMode = isDebugMode
        self.applicationName = applicationName
    }
}

/// Shared instance access
public extension TemplateProject {

    /// Shared instance of Template Project
    static let shared = TemplateProject()

    /// Configure the shared instance
    /// - Parameter configuration: Configuration to apply
    static func configure(with configuration: TemplateProjectConfiguration) {
        // Configuration logic would go here
        if configuration.isDebugMode {
            print("Template Project configured in debug mode for \(configuration.applicationName)")
        }
    }
}