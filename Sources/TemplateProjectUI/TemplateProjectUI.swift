// TemplateProjectUI.swift
//
// UI components and SwiftUI extensions for the Template Project

import SwiftUI
import TemplateProject

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

/// UI library for Template Project
///
/// Provides SwiftUI views and UI utilities for iOS, macOS, and Mac Catalyst
public struct TemplateProjectUI {

    /// Library version
    public static let version = "1.0.0"

    /// Initialize the UI library
    public init() {}
}

/// Example SwiftUI view demonstrating the UI library
public struct WelcomeView: View {

    /// Template Project instance
    private let templateProject = TemplateProject()

    public init() {}

    public var body: some View {
        VStack(spacing: 20) {
            Text("Welcome to Template Project")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text(templateProject.greet())
                .font(.title2)
                .foregroundColor(.secondary)

            #if os(iOS)
            Button("iOS Specific Action") {
                // iOS-specific functionality
            }
            .buttonStyle(.borderedProminent)
            #elseif os(macOS)
            Button("macOS Specific Action") {
                // macOS-specific functionality
            }
            .buttonStyle(.borderedProminent)
            #endif
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

/// Platform-specific UI utilities
public extension TemplateProjectUI {

    #if os(iOS)
    /// iOS-specific UI utilities
    enum iOS {
        /// Get safe area insets
        public static var safeAreaInsets: UIEdgeInsets {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first else {
                return .zero
            }
            return window.safeAreaInsets
        }
    }
    #endif

    #if os(macOS)
    /// macOS-specific UI utilities
    enum macOS {
        /// Get current screen bounds
        public static var screenBounds: CGRect {
            return NSScreen.main?.frame ?? .zero
        }
    }
    #endif
}

/// SwiftUI View extensions
public extension View {

    /// Apply platform-specific styling
    func platformStyling() -> some View {
        #if os(iOS)
        return self
            .navigationBarTitleDisplayMode(.large)
        #elseif os(macOS)
        return self
            .frame(minWidth: 400, minHeight: 300)
        #endif
    }
}

/// Preview support
struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView()
            .previewDisplayName("Welcome View")

        #if os(iOS)
        WelcomeView()
            .previewDevice("iPhone 15")
            .previewDisplayName("iPhone 15")

        WelcomeView()
            .previewDevice("iPad Pro (12.9-inch)")
            .previewDisplayName("iPad Pro")
        #endif

        #if os(macOS)
        WelcomeView()
            .frame(width: 500, height: 400)
            .previewDisplayName("macOS Window")
        #endif
    }
}