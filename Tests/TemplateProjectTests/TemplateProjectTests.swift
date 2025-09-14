import XCTest
@testable import TemplateProject

/// Unit tests for TemplateProject core library
final class TemplateProjectTests: XCTestCase {

    // MARK: - Properties

    private var templateProject: TemplateProject!

    // MARK: - Setup and Teardown

    override func setUpWithError() throws {
        try super.setUpWithError()
        templateProject = TemplateProject()
    }

    override func tearDownWithError() throws {
        templateProject = nil
        try super.tearDownWithError()
    }

    // MARK: - Basic Functionality Tests

    func testLibraryVersion() throws {
        // Test that library version is properly set
        XCTAssertEqual(TemplateProject.version, "1.0.0")
        XCTAssertFalse(TemplateProject.version.isEmpty)
    }

    func testInitialization() throws {
        // Test that TemplateProject can be initialized
        let project = TemplateProject()
        XCTAssertNotNil(project)
    }

    func testSharedInstance() throws {
        // Test shared instance access
        let shared1 = TemplateProject.shared
        let shared2 = TemplateProject.shared

        // Verify it's the same instance (reference equality for class types)
        // Note: For struct types, this tests that shared access works consistently
        XCTAssertNotNil(shared1)
        XCTAssertNotNil(shared2)
    }

    func testGreeting() throws {
        // Test the example greet method
        let greeting = templateProject.greet()
        XCTAssertFalse(greeting.isEmpty)
        XCTAssertEqual(greeting, "Hello from Template Project!")
    }

    // MARK: - Configuration Tests

    func testDefaultConfiguration() throws {
        // Test default configuration values
        let config = TemplateProjectConfiguration()

        XCTAssertFalse(config.isDebugMode)
        XCTAssertEqual(config.applicationName, "Template App")
    }

    func testCustomConfiguration() throws {
        // Test custom configuration
        let config = TemplateProjectConfiguration(
            isDebugMode: true,
            applicationName: "Test App"
        )

        XCTAssertTrue(config.isDebugMode)
        XCTAssertEqual(config.applicationName, "Test App")
    }

    func testConfigureSharedInstance() throws {
        // Test configuring the shared instance
        let config = TemplateProjectConfiguration(
            isDebugMode: true,
            applicationName: "Test Configuration"
        )

        // This should not throw or crash
        XCTAssertNoThrow(TemplateProject.configure(with: config))
    }

    // MARK: - Performance Tests

    func testGreetingPerformance() throws {
        // Test performance of greet method
        measure {
            for _ in 0..<1000 {
                _ = templateProject.greet()
            }
        }
    }

    func testInitializationPerformance() throws {
        // Test performance of initialization
        measure {
            for _ in 0..<1000 {
                _ = TemplateProject()
            }
        }
    }

    // MARK: - Thread Safety Tests

    func testConcurrentAccess() throws {
        // Test concurrent access to shared instance
        let expectation = XCTestExpectation(description: "Concurrent access")
        expectation.expectedFulfillmentCount = 10

        let queue = DispatchQueue.global(qos: .userInitiated)

        for i in 0..<10 {
            queue.async {
                let shared = TemplateProject.shared
                let greeting = shared.greet()
                XCTAssertFalse(greeting.isEmpty)
                XCTAssertEqual(greeting, "Hello from Template Project!")
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 5.0)
    }

    // MARK: - Edge Cases

    func testMultipleConfigurations() throws {
        // Test multiple configuration calls
        let config1 = TemplateProjectConfiguration(isDebugMode: false, applicationName: "App1")
        let config2 = TemplateProjectConfiguration(isDebugMode: true, applicationName: "App2")

        XCTAssertNoThrow(TemplateProject.configure(with: config1))
        XCTAssertNoThrow(TemplateProject.configure(with: config2))
    }

    // MARK: - Integration Tests

    func testEndToEndUsage() throws {
        // Test typical usage pattern
        let project = TemplateProject()
        let config = TemplateProjectConfiguration(isDebugMode: false, applicationName: "Integration Test")

        TemplateProject.configure(with: config)

        let greeting = project.greet()
        XCTAssertEqual(greeting, "Hello from Template Project!")

        let sharedGreeting = TemplateProject.shared.greet()
        XCTAssertEqual(sharedGreeting, greeting)
    }
}

// MARK: - TemplateProjectConfiguration Tests

final class TemplateProjectConfigurationTests: XCTestCase {

    func testConfigurationEquality() throws {
        // Note: This test assumes Equatable conformance would be added
        let config1 = TemplateProjectConfiguration(isDebugMode: true, applicationName: "Test")
        let config2 = TemplateProjectConfiguration(isDebugMode: true, applicationName: "Test")
        let config3 = TemplateProjectConfiguration(isDebugMode: false, applicationName: "Test")

        // For now, just test property values individually
        XCTAssertEqual(config1.isDebugMode, config2.isDebugMode)
        XCTAssertEqual(config1.applicationName, config2.applicationName)
        XCTAssertNotEqual(config1.isDebugMode, config3.isDebugMode)
    }

    func testConfigurationDefaults() throws {
        let config = TemplateProjectConfiguration()

        // Test all default values
        XCTAssertFalse(config.isDebugMode)
        XCTAssertEqual(config.applicationName, "Template App")
        XCTAssertFalse(config.applicationName.isEmpty)
    }
}