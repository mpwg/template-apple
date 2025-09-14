# Testing Guide

## Table of Contents

- [Overview](#overview)
- [Testing Philosophy](#testing-philosophy)
- [Test Categories](#test-categories)
- [Testing Framework Setup](#testing-framework-setup)
- [Writing Tests](#writing-tests)
- [Test Execution](#test-execution)
- [Code Coverage](#code-coverage)
- [Performance Testing](#performance-testing)
- [UI Testing](#ui-testing)
- [Integration Testing](#integration-testing)
- [Testing Best Practices](#testing-best-practices)
- [CI/CD Integration](#cicd-integration)
- [Troubleshooting](#troubleshooting)

## Overview

This guide provides comprehensive documentation for testing iOS and macOS applications in this template project. We use a multi-layered testing approach including unit tests, integration tests, UI tests, and performance tests.

### Testing Stack

- **Framework**: XCTest (Apple's native testing framework)
- **UI Testing**: XCUITest for automated UI testing
- **Performance Testing**: XCTest performance measurement
- **Code Coverage**: Xcode's built-in coverage tools
- **CI/CD**: GitHub Actions with Fastlane
- **Reporting**: HTML and JUnit reports

### Test Coverage Goals

- **Unit Tests**: ≥ 80% code coverage
- **Integration Tests**: All critical user flows
- **UI Tests**: Primary user journeys
- **Performance Tests**: Key performance metrics

## Testing Philosophy

### Test Pyramid

Our testing strategy follows the test pyramid approach:

```
    /\     UI Tests (Few)
   /  \    - End-to-end user flows
  /____\   - Critical user journeys

  /    \   Integration Tests (Some)
 /      \  - Component interactions
/________\ - API integrations

/__________\  Unit Tests (Many)
- Individual functions
- Business logic
- Edge cases
```

### Testing Principles

1. **Fast Feedback**: Tests should run quickly and provide immediate feedback
2. **Reliable**: Tests should be deterministic and not flaky
3. **Maintainable**: Tests should be easy to read and modify
4. **Comprehensive**: Tests should cover happy paths, edge cases, and error conditions
5. **Isolated**: Each test should be independent and not rely on external state

## Test Categories

### Unit Tests

**Purpose**: Test individual functions and methods in isolation

**Characteristics**:
- Fast execution (< 1 second each)
- No external dependencies
- Test single units of functionality
- Mock external dependencies

**Location**: `Tests/TemplateProjectTests/`

### Integration Tests

**Purpose**: Test interactions between components

**Characteristics**:
- Test component interactions
- May involve real dependencies
- Test data flow between layers
- Verify API contracts

**Location**: `Tests/TemplateProjectIntegrationTests/`

### UI Tests

**Purpose**: Test user interface and user interactions

**Characteristics**:
- Test complete user flows
- Interact with actual UI elements
- Verify visual states
- Test accessibility

**Location**: `Tests/TemplateProjectUITests/`

### Performance Tests

**Purpose**: Test app performance and resource usage

**Characteristics**:
- Measure execution time
- Monitor memory usage
- Test battery impact (iOS)
- Benchmark critical operations

**Location**: Integrated into unit and integration test files

## Testing Framework Setup

### XCTest Configuration

Our testing setup uses XCTest with additional utilities:

```swift
import XCTest
@testable import TemplateProject

class TemplateProjectTests: XCTestCase {
    // Test implementation
}
```

### Test Target Configuration

#### Unit Test Target
```swift
// Package.swift configuration
.testTarget(
    name: "TemplateProjectTests",
    dependencies: [
        "TemplateProject",
        // Add testing dependencies here
    ],
    path: "Tests/TemplateProjectTests"
)
```

#### UI Test Target
```swift
// Package.swift configuration
.testTarget(
    name: "TemplateProjectUITests",
    dependencies: [
        "TemplateProjectUI",
        "TemplateProject"
    ],
    path: "Tests/TemplateProjectUITests"
)
```

### Testing Dependencies

Common testing frameworks that can be added:

```swift
// In Package.swift dependencies array
.package(url: "https://github.com/pointfreeco/swift-snapshot-testing.git", from: "1.12.0"),
.package(url: "https://github.com/Quick/Quick.git", from: "7.0.0"),
.package(url: "https://github.com/Quick/Nimble.git", from: "12.0.0"),
```

## Writing Tests

### Unit Test Structure

#### Basic Test Structure
```swift
import XCTest
@testable import TemplateProject

final class ExampleServiceTests: XCTestCase {

    // MARK: - Properties

    private var sut: ExampleService! // System Under Test
    private var mockDependency: MockDependency!

    // MARK: - Setup and Teardown

    override func setUpWithError() throws {
        try super.setUpWithError()
        mockDependency = MockDependency()
        sut = ExampleService(dependency: mockDependency)
    }

    override func tearDownWithError() throws {
        sut = nil
        mockDependency = nil
        try super.tearDownWithError()
    }

    // MARK: - Test Methods

    func testExample() throws {
        // Given
        let input = "test input"

        // When
        let result = sut.processInput(input)

        // Then
        XCTAssertEqual(result, "expected output")
    }
}
```

#### Testing Async Code
```swift
func testAsyncOperation() async throws {
    // Given
    let expectation = XCTestExpectation(description: "Async operation completes")

    // When
    let result = await sut.performAsyncOperation()

    // Then
    XCTAssertNotNil(result)
    XCTAssertEqual(result.status, .success)
}
```

#### Testing Errors
```swift
func testErrorHandling() throws {
    // Given
    mockDependency.shouldThrowError = true

    // When/Then
    XCTAssertThrowsError(try sut.operationThatCanFail()) { error in
        XCTAssertTrue(error is ServiceError)
        XCTAssertEqual(error as? ServiceError, .networkFailure)
    }
}
```

### Mocking and Stubbing

#### Protocol-Based Mocking
```swift
protocol NetworkServiceProtocol {
    func fetchData() async throws -> Data
}

class MockNetworkService: NetworkServiceProtocol {
    var fetchDataResult: Result<Data, Error> = .success(Data())

    func fetchData() async throws -> Data {
        switch fetchDataResult {
        case .success(let data):
            return data
        case .failure(let error):
            throw error
        }
    }
}
```

#### Dependency Injection for Testing
```swift
class DataManager {
    private let networkService: NetworkServiceProtocol

    init(networkService: NetworkServiceProtocol = NetworkService()) {
        self.networkService = networkService
    }

    // Implementation
}

// In tests
func setUp() {
    mockNetworkService = MockNetworkService()
    sut = DataManager(networkService: mockNetworkService)
}
```

### Performance Tests

#### Measuring Performance
```swift
func testPerformanceOfCriticalOperation() throws {
    let data = generateLargeDataset()

    measure {
        _ = sut.processingLargeDataset(data)
    }
}

func testMemoryUsage() throws {
    measure(metrics: [XCTMemoryMetric()]) {
        _ = sut.memoryIntensiveOperation()
    }
}
```

#### Custom Performance Metrics
```swift
func testCustomPerformanceMetric() throws {
    let startTime = CFAbsoluteTimeGetCurrent()

    // Operation to measure
    sut.performOperation()

    let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
    XCTAssertLessThan(timeElapsed, 0.1, "Operation should complete in under 100ms")
}
```

### UI Testing

#### Basic UI Test Structure
```swift
import XCTest

final class TemplateProjectUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func testMainUserFlow() throws {
        // Test user interaction flow
        let welcomeButton = app.buttons["welcomeButton"]
        XCTAssertTrue(welcomeButton.exists)

        welcomeButton.tap()

        let resultLabel = app.staticTexts["resultLabel"]
        XCTAssertTrue(resultLabel.waitForExistence(timeout: 5.0))
        XCTAssertEqual(resultLabel.label, "Expected Result")
    }
}
```

#### Testing Different Device Sizes
```swift
func testLayoutOnDifferentScreenSizes() throws {
    let devices: [XCUIDevice.DeviceType] = [
        .iPhone, .iPadMini, .iPadPro12_9
    ]

    for deviceType in devices {
        app.setDeviceOrientation(.portrait)
        // Test layout for each device
        verifyLayoutConstraints()
    }
}
```

#### Accessibility Testing
```swift
func testAccessibility() throws {
    let welcomeButton = app.buttons["welcomeButton"]
    XCTAssertTrue(welcomeButton.isAccessibilityElement)
    XCTAssertEqual(welcomeButton.accessibilityLabel, "Welcome Button")
    XCTAssertEqual(welcomeButton.accessibilityHint, "Tap to start the app")
}
```

## Test Execution

### Local Testing

#### Running All Tests
```bash
# Swift Package Manager
swift test

# Xcode (command line)
xcodebuild test -scheme TemplateProject -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# Fastlane
bundle exec fastlane test
```

#### Running Specific Tests
```bash
# Run specific test class
swift test --filter TemplateProjectTests

# Run specific test method
swift test --filter TemplateProjectTests/testSpecificMethod

# Run tests with specific tags
swift test --filter tag:unit
```

#### Parallel Test Execution
```bash
# Run tests in parallel
swift test --parallel

# Fastlane parallel testing
bundle exec fastlane test parallel:true
```

### Testing on Multiple Simulators
```bash
# Test on specific simulator
xcrun simctl list devices
xcodebuild test -scheme TemplateProject -destination 'platform=iOS Simulator,name=iPhone 15 Pro,OS=17.0'

# Fastlane multiple device testing
bundle exec fastlane test_multiple
```

## Code Coverage

### Enabling Code Coverage

#### Xcode Configuration
1. Open scheme settings
2. Go to Test action
3. Enable "Gather coverage for some targets"
4. Select targets to measure

#### Command Line
```bash
# Swift Package Manager with coverage
swift test --enable-code-coverage

# Xcode build with coverage
xcodebuild test -scheme TemplateProject -enableCodeCoverage YES
```

### Coverage Reporting

#### Generating Coverage Reports
```bash
# Generate coverage report (requires xcov gem)
xcov --scheme TemplateProject --workspace TemplateProject.xcworkspace

# Export coverage data
xcodebuild test -scheme TemplateProject -enableCodeCoverage YES -derivedDataPath ./DerivedData
xcrun xccov view DerivedData/Logs/Test/*.xcresult --report --json > coverage.json
```

#### Coverage Thresholds
```ruby
# In Fastfile
lane :test_with_coverage do
  run_tests(
    scheme: "TemplateProject",
    code_coverage: true
  )

  # Check coverage threshold
  xcov(
    scheme: "TemplateProject",
    minimum_coverage_percentage: 80.0,
    include_test_targets: false
  )
end
```

### Coverage Analysis

#### Interpreting Coverage Reports
- **Line Coverage**: Percentage of code lines executed
- **Function Coverage**: Percentage of functions called
- **Branch Coverage**: Percentage of code branches taken

#### Improving Coverage
1. Identify uncovered code areas
2. Add tests for missing scenarios
3. Review edge cases and error paths
4. Remove dead code if appropriate

## CI/CD Integration

### GitHub Actions Configuration

The testing pipeline is configured in `.github/workflows/ci.yml`:

```yaml
name: CI Tests
on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  test:
    runs-on: macos-latest
    strategy:
      matrix:
        xcode-version: ['15.4', '16.0']
        test-type: ['unit', 'integration', 'ui']

    steps:
    - uses: actions/checkout@v4
    - name: Setup Xcode
      uses: maxim-lobanov/setup-xcode@v1
      with:
        xcode-version: ${{ matrix.xcode-version }}

    - name: Run Tests
      run: |
        case ${{ matrix.test-type }} in
          unit)
            swift test --filter tag:unit
            ;;
          integration)
            swift test --filter tag:integration
            ;;
          ui)
            bundle exec fastlane ui_tests
            ;;
        esac
```

### Test Result Reporting

#### JUnit XML Reports
```bash
# Generate JUnit XML reports
swift test --enable-code-coverage --parallel --xunit-output test-results.xml
```

#### HTML Coverage Reports
```ruby
# In Fastfile
lane :generate_coverage_report do
  run_tests(
    scheme: "TemplateProject",
    output_types: "html,junit",
    output_directory: "./test_output"
  )

  xcov(
    scheme: "TemplateProject",
    html_report: true,
    output_directory: "./coverage_output"
  )
end
```

### Quality Gates

#### Failing Builds on Test Failures
```yaml
- name: Run Tests
  run: swift test
  continue-on-error: false

- name: Check Coverage
  run: |
    coverage=$(xcrun xccov view --report --json DerivedData/Logs/Test/*.xcresult | jq '.targets[0].lineCoverage')
    if (( $(echo "$coverage < 0.8" | bc -l) )); then
      echo "Coverage $coverage is below threshold 0.8"
      exit 1
    fi
```

## Testing Best Practices

### Test Organization

#### Test File Structure
```
Tests/
├── TemplateProjectTests/          # Unit tests
│   ├── Models/
│   ├── Services/
│   ├── ViewModels/
│   └── Utilities/
├── TemplateProjectIntegrationTests/  # Integration tests
│   ├── API/
│   ├── Database/
│   └── Workflows/
└── TemplateProjectUITests/           # UI tests
    ├── UserFlows/
    ├── Accessibility/
    └── Performance/
```

#### Test Naming Conventions
```swift
// Given_When_Then format
func testUserLogin_WhenValidCredentials_ShouldReturnSuccess() { }

// Subject_Scenario_ExpectedResult format
func testPasswordValidation_EmptyPassword_ReturnsInvalidError() { }

// Action-based naming
func testTapWelcomeButton_ShowsGreeting() { }
```

### Test Data Management

#### Test Fixtures
```swift
struct TestFixtures {
    static let validUser = User(
        id: "test-user-123",
        name: "Test User",
        email: "test@example.com"
    )

    static let sampleData = Data("""
    {
        "id": "123",
        "name": "Sample"
    }
    """.utf8)
}
```

#### Factory Methods
```swift
extension User {
    static func makeTestUser(
        id: String = "test-id",
        name: String = "Test User",
        email: String = "test@example.com"
    ) -> User {
        return User(id: id, name: name, email: email)
    }
}
```

### Avoiding Flaky Tests

#### Common Causes of Flaky Tests
1. **Timing Issues**: Tests that depend on specific timing
2. **External Dependencies**: Tests that rely on network or external services
3. **Shared State**: Tests that affect global state
4. **Random Data**: Tests using non-deterministic data

#### Solutions
```swift
// Use expectations for async code
func testAsyncOperation() {
    let expectation = XCTestExpectation(description: "Operation completes")

    service.performOperation { result in
        XCTAssertEqual(result, expectedResult)
        expectation.fulfill()
    }

    wait(for: [expectation], timeout: 10.0)
}

// Mock time-dependent code
class MockTimeProvider: TimeProvider {
    var currentTime = Date()

    func now() -> Date {
        return currentTime
    }
}

// Isolate tests with proper setup/teardown
override func tearDown() {
    // Reset all state
    UserDefaults.standard.removePersistentDomain(
        forName: Bundle.main.bundleIdentifier!
    )
    super.tearDown()
}
```

## Troubleshooting

### Common Test Issues

#### Build Errors
```bash
# Clean build folder
swift package clean

# Reset simulators
xcrun simctl erase all

# Clear derived data
rm -rf ~/Library/Developer/Xcode/DerivedData
```

#### Test Timeouts
```swift
// Increase timeout for slow operations
wait(for: [expectation], timeout: 30.0)

// Use async/await for better timeout handling
func testAsyncOperation() async throws {
    let result = await service.performLongOperation()
    XCTAssertNotNil(result)
}
```

#### Memory Leaks in Tests
```swift
// Use weak references in closures
service.performOperation { [weak self] result in
    self?.handleResult(result)
}

// Properly clean up in tearDown
override func tearDown() {
    sut = nil
    mockDependencies = nil
    super.tearDown()
}
```

### Performance Issues

#### Slow Test Execution
- Run tests in parallel: `swift test --parallel`
- Use test filtering for faster feedback
- Mock expensive operations
- Optimize test setup and teardown

#### Resource Usage
- Monitor memory usage in performance tests
- Use instruments for detailed profiling
- Test on different device configurations
- Profile test execution time

### Debug Test Failures

#### Logging and Debugging
```swift
// Add debug information to assertions
XCTAssertEqual(actual, expected, "Values should match. Actual: \(actual), Expected: \(expected)")

// Use XCTContext for additional information
XCTContext.runActivity(named: "Verify user data") { _ in
    XCTAssertEqual(user.name, "Expected Name")
    XCTAssertEqual(user.email, "expected@email.com")
}

// Conditional compilation for test-only code
#if DEBUG || TESTING
    print("Debug information: \(debugInfo)")
#endif
```

#### Test Isolation
```swift
// Ensure tests don't affect each other
override func setUp() {
    super.setUp()
    // Reset to known state
    resetGlobalState()
}

override func tearDown() {
    // Clean up after test
    cleanupTestState()
    super.tearDown()
}
```

## Testing Scripts

### Local Testing Script

Create `scripts/run-tests.sh`:
```bash
#!/bin/bash
set -e

echo "🧪 Running comprehensive test suite..."

# Run unit tests
echo "Running unit tests..."
swift test --filter tag:unit --parallel

# Run integration tests
echo "Running integration tests..."
swift test --filter tag:integration

# Run UI tests (if Xcode project exists)
if [ -f "*.xcworkspace" ] || [ -f "*.xcodeproj" ]; then
    echo "Running UI tests..."
    bundle exec fastlane ui_tests
fi

# Generate coverage report
echo "Generating coverage report..."
swift test --enable-code-coverage
xcrun xccov view --report DerivedData/Logs/Test/*.xcresult

echo "✅ All tests completed successfully!"
```

Make it executable:
```bash
chmod +x scripts/run-tests.sh
```

### Coverage Report Script

Create `scripts/coverage-report.sh`:
```bash
#!/bin/bash
set -e

echo "📊 Generating code coverage report..."

# Run tests with coverage
swift test --enable-code-coverage

# Generate JSON coverage report
xcrun xccov view --report --json DerivedData/Logs/Test/*.xcresult > coverage.json

# Generate HTML report (requires xcov gem)
if command -v xcov &> /dev/null; then
    xcov --json_report coverage.json
    echo "HTML coverage report generated in xcov_output/"
else
    echo "Install xcov gem for HTML reports: gem install xcov"
fi

echo "✅ Coverage report generated!"
```

### Test Performance Monitor

Create `scripts/test-performance.sh`:
```bash
#!/bin/bash
set -e

echo "⚡ Running performance tests..."

# Run performance tests specifically
swift test --filter performance --parallel

# Generate performance report
echo "Performance test results:"
grep -r "Performance Test" DerivedData/Logs/Test/ | tail -10

echo "✅ Performance tests completed!"
```

## Integration with IDEs

### Xcode Integration
- Test navigator shows all test cases
- Live test results and coverage
- Test debugging with breakpoints
- Performance measurement visualization

### VS Code Integration
- Swift extension provides test discovery
- Test results in integrated terminal
- Debug tests with Swift debugging extension

---

This testing guide provides a comprehensive framework for testing iOS and macOS applications. Regular testing ensures code quality, prevents regressions, and maintains user confidence in your applications.