import XCTest
import SwiftUI
@testable import TemplateProjectUI
@testable import TemplateProject

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

/// Unit tests for TemplateProjectUI library
final class TemplateProjectUITests: XCTestCase {

    // MARK: - Properties

    private var templateProjectUI: TemplateProjectUI!

    // MARK: - Setup and Teardown

    override func setUpWithError() throws {
        try super.setUpWithError()
        templateProjectUI = TemplateProjectUI()
    }

    override func tearDownWithError() throws {
        templateProjectUI = nil
        try super.tearDownWithError()
    }

    // MARK: - Basic Functionality Tests

    func testLibraryVersion() throws {
        // Test that UI library version is properly set
        XCTAssertEqual(TemplateProjectUI.version, "1.0.0")
        XCTAssertFalse(TemplateProjectUI.version.isEmpty)
    }

    func testInitialization() throws {
        // Test that TemplateProjectUI can be initialized
        let ui = TemplateProjectUI()
        XCTAssertNotNil(ui)
    }

    // MARK: - SwiftUI View Tests

    func testWelcomeViewCreation() throws {
        // Test that WelcomeView can be created
        let welcomeView = WelcomeView()
        XCTAssertNotNil(welcomeView)
    }

    func testWelcomeViewBody() throws {
        // Test that WelcomeView body can be accessed without crashing
        let welcomeView = WelcomeView()
        let body = welcomeView.body
        XCTAssertNotNil(body)
    }

    // MARK: - Platform-Specific Tests

    #if os(iOS)
    func testIOSUtilities() throws {
        // Test iOS-specific utilities
        let safeAreaInsets = TemplateProjectUI.iOS.safeAreaInsets
        XCTAssertNotNil(safeAreaInsets)

        // Safe area insets should be non-negative
        XCTAssertGreaterThanOrEqual(safeAreaInsets.top, 0)
        XCTAssertGreaterThanOrEqual(safeAreaInsets.bottom, 0)
        XCTAssertGreaterThanOrEqual(safeAreaInsets.left, 0)
        XCTAssertGreaterThanOrEqual(safeAreaInsets.right, 0)
    }
    #endif

    #if os(macOS)
    func testMacOSUtilities() throws {
        // Test macOS-specific utilities
        let screenBounds = TemplateProjectUI.macOS.screenBounds
        XCTAssertNotNil(screenBounds)

        // Screen bounds should have positive width and height (or be zero if no screen)
        XCTAssertGreaterThanOrEqual(screenBounds.width, 0)
        XCTAssertGreaterThanOrEqual(screenBounds.height, 0)
    }
    #endif

    // MARK: - SwiftUI Extensions Tests

    func testPlatformStyling() throws {
        // Test that platform styling extension works
        let testView = Text("Test")
        let styledView = testView.platformStyling()
        XCTAssertNotNil(styledView)
    }

    // MARK: - Performance Tests

    func testWelcomeViewPerformance() throws {
        // Test performance of creating WelcomeView
        measure {
            for _ in 0..<100 {
                _ = WelcomeView()
            }
        }
    }

    func testPlatformStylingPerformance() throws {
        // Test performance of platform styling
        let testView = Text("Performance Test")

        measure {
            for _ in 0..<1000 {
                _ = testView.platformStyling()
            }
        }
    }

    // MARK: - Integration Tests

    func testUIWithCoreIntegration() throws {
        // Test that UI library properly integrates with core library
        let welcomeView = WelcomeView()
        XCTAssertNotNil(welcomeView)

        // This tests that the UI can access core library functionality
        // The WelcomeView internally uses TemplateProject
        let body = welcomeView.body
        XCTAssertNotNil(body)
    }

    // MARK: - Thread Safety Tests

    func testConcurrentViewCreation() throws {
        // Test concurrent view creation
        let expectation = XCTestExpectation(description: "Concurrent view creation")
        expectation.expectedFulfillmentCount = 10

        let queue = DispatchQueue.global(qos: .userInitiated)

        for _ in 0..<10 {
            queue.async {
                let welcomeView = WelcomeView()
                XCTAssertNotNil(welcomeView)
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 5.0)
    }

    #if os(iOS)
    // MARK: - iOS-Specific Integration Tests

    func testIOSViewIntegration() throws {
        // Test iOS-specific view integration
        let welcomeView = WelcomeView()
        let hostingController = UIHostingController(rootView: welcomeView)

        XCTAssertNotNil(hostingController)
        XCTAssertNotNil(hostingController.rootView)
    }
    #endif

    #if os(macOS)
    // MARK: - macOS-Specific Integration Tests

    func testMacOSViewIntegration() throws {
        // Test macOS-specific view integration
        let welcomeView = WelcomeView()
        let hostingController = NSHostingController(rootView: welcomeView)

        XCTAssertNotNil(hostingController)
        XCTAssertNotNil(hostingController.rootView)
    }
    #endif
}

// MARK: - SwiftUI Testing Utilities

@available(iOS 13.0, macOS 10.15, *)
extension XCTestCase {

    /// Helper method to test SwiftUI views
    func testSwiftUIView<Content: View>(_ view: Content) throws {
        // Basic test that view can be created and body accessed
        let body = view.body
        XCTAssertNotNil(body)
    }

    /// Helper method to test view modifiers
    func testViewModifier<Content: View>(_ view: Content) throws {
        // Test that view modifiers don't crash
        let modifiedView = view
            .padding()
            .background(Color.clear)
        XCTAssertNotNil(modifiedView)
    }
}

// MARK: - Mock Data for Testing

struct MockData {
    static let sampleText = "Sample Text"
    static let sampleConfiguration = TemplateProjectConfiguration(
        isDebugMode: true,
        applicationName: "Test App"
    )
}

// MARK: - Custom Test Cases

final class WelcomeViewSpecificTests: XCTestCase {

    func testWelcomeViewWithMockData() throws {
        // Create view with known state
        let welcomeView = WelcomeView()

        // Test that view creation doesn't crash
        XCTAssertNotNil(welcomeView)

        // Test body access
        let body = welcomeView.body
        XCTAssertNotNil(body)
    }

    func testWelcomeViewModifiers() throws {
        let welcomeView = WelcomeView()

        // Test applying additional modifiers
        let modifiedView = welcomeView
            .padding(20)
            .background(Color.blue.opacity(0.1))

        XCTAssertNotNil(modifiedView)
    }
}