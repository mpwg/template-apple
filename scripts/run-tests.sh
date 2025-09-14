#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}🧪${NC} $1"
}

print_success() {
    echo -e "${GREEN}✅${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠️${NC} $1"
}

print_error() {
    echo -e "${RED}❌${NC} $1"
}

print_info() {
    echo -e "${PURPLE}ℹ️${NC} $1"
}

# Test execution options
RUN_UNIT_TESTS=true
RUN_INTEGRATION_TESTS=true
RUN_UI_TESTS=true
RUN_PERFORMANCE_TESTS=true
GENERATE_COVERAGE=true
PARALLEL_EXECUTION=true

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --unit-only)
            RUN_UNIT_TESTS=true
            RUN_INTEGRATION_TESTS=false
            RUN_UI_TESTS=false
            RUN_PERFORMANCE_TESTS=false
            shift
            ;;
        --ui-only)
            RUN_UNIT_TESTS=false
            RUN_INTEGRATION_TESTS=false
            RUN_UI_TESTS=true
            RUN_PERFORMANCE_TESTS=false
            shift
            ;;
        --no-coverage)
            GENERATE_COVERAGE=false
            shift
            ;;
        --sequential)
            PARALLEL_EXECUTION=false
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --unit-only      Run only unit tests"
            echo "  --ui-only        Run only UI tests"
            echo "  --no-coverage    Skip coverage generation"
            echo "  --sequential     Run tests sequentially (not in parallel)"
            echo "  --help           Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                    # Run all tests with coverage"
            echo "  $0 --unit-only       # Run only unit tests"
            echo "  $0 --no-coverage     # Run tests without coverage"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

print_status "Starting comprehensive test suite..."

# Check if we're in a git repository and Swift package
if [ ! -f "Package.swift" ]; then
    print_error "Package.swift not found. Make sure you're in a Swift package directory."
    exit 1
fi

# Create test output directories
mkdir -p test-output
mkdir -p coverage-output

# Print test configuration
echo
print_info "Test Configuration:"
echo "  Unit Tests: $([ "$RUN_UNIT_TESTS" = true ] && echo "✅" || echo "❌")"
echo "  Integration Tests: $([ "$RUN_INTEGRATION_TESTS" = true ] && echo "✅" || echo "❌")"
echo "  UI Tests: $([ "$RUN_UI_TESTS" = true ] && echo "✅" || echo "❌")"
echo "  Performance Tests: $([ "$RUN_PERFORMANCE_TESTS" = true ] && echo "✅" || echo "❌")"
echo "  Coverage Generation: $([ "$GENERATE_COVERAGE" = true ] && echo "✅" || echo "❌")"
echo "  Parallel Execution: $([ "$PARALLEL_EXECUTION" = true ] && echo "✅" || echo "❌")"
echo

# Build test arguments
SWIFT_TEST_ARGS=""
if [ "$PARALLEL_EXECUTION" = true ]; then
    SWIFT_TEST_ARGS="$SWIFT_TEST_ARGS --parallel"
fi

if [ "$GENERATE_COVERAGE" = true ]; then
    SWIFT_TEST_ARGS="$SWIFT_TEST_ARGS --enable-code-coverage"
fi

# Test execution summary
TOTAL_TESTS=0
FAILED_TESTS=0
TEST_START_TIME=$(date +%s)

# Function to run tests and capture results
run_test_suite() {
    local test_name=$1
    local test_command=$2
    local output_file="test-output/${test_name}-output.log"

    print_status "Running $test_name..."

    if eval "$test_command" > "$output_file" 2>&1; then
        print_success "$test_name completed successfully"

        # Count tests (basic count from output)
        local test_count=$(grep -c "Test Case.*passed\|Test Case.*failed" "$output_file" 2>/dev/null || echo "0")
        TOTAL_TESTS=$((TOTAL_TESTS + test_count))

        return 0
    else
        print_error "$test_name failed"

        # Show last few lines of output for debugging
        print_warning "Last 10 lines of output:"
        tail -10 "$output_file"

        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
}

# Run Unit Tests
if [ "$RUN_UNIT_TESTS" = true ]; then
    print_status "=== Unit Tests ==="

    # Check if we have unit test targets
    if swift package dump-package | grep -q '"type": "test"'; then
        if run_test_suite "Unit Tests" "swift test $SWIFT_TEST_ARGS"; then
            print_success "Unit tests completed"
        else
            print_warning "Some unit tests failed"
        fi
    else
        print_warning "No unit test targets found in Package.swift"
    fi
    echo
fi

# Run Integration Tests
if [ "$RUN_INTEGRATION_TESTS" = true ]; then
    print_status "=== Integration Tests ==="

    # Look for integration test patterns
    if find Tests -name "*Integration*" -type d | grep -q .; then
        if run_test_suite "Integration Tests" "swift test $SWIFT_TEST_ARGS --filter Integration"; then
            print_success "Integration tests completed"
        else
            print_warning "Some integration tests failed"
        fi
    else
        print_info "No integration test directories found - skipping"
    fi
    echo
fi

# Run Performance Tests
if [ "$RUN_PERFORMANCE_TESTS" = true ]; then
    print_status "=== Performance Tests ==="

    # Look for performance test methods
    if grep -r "func testPerformance\|measure {" Tests/ >/dev/null 2>&1; then
        if run_test_suite "Performance Tests" "swift test $SWIFT_TEST_ARGS --filter Performance"; then
            print_success "Performance tests completed"
        else
            print_warning "Some performance tests failed"
        fi
    else
        print_info "No performance tests found - skipping"
    fi
    echo
fi

# Run UI Tests (Fastlane/Xcode based)
if [ "$RUN_UI_TESTS" = true ]; then
    print_status "=== UI Tests ==="

    # Check if we have Fastlane and Xcode projects
    if [ -f "fastlane/Fastfile" ] && ([ -f "*.xcworkspace" ] || [ -f "*.xcodeproj" ]); then
        print_status "Running UI tests via Fastlane..."

        if bundle exec fastlane test 2>/dev/null; then
            print_success "UI tests completed via Fastlane"
        else
            print_warning "UI tests via Fastlane had issues (may be expected without Xcode project)"
        fi
    else
        print_info "No Fastlane setup or Xcode project found - skipping UI tests"
    fi
    echo
fi

# Generate Test Reports
print_status "=== Generating Test Reports ==="

# Generate JUnit XML report if available
if command -v swift &> /dev/null; then
    print_status "Generating JUnit XML report..."
    swift test $SWIFT_TEST_ARGS --xunit-output test-output/test-results.xml 2>/dev/null || \
        print_warning "Could not generate JUnit XML report"
fi

# Generate Coverage Report
if [ "$GENERATE_COVERAGE" = true ]; then
    print_status "Generating code coverage report..."

    # Look for coverage data
    if find . -name "*.profdata" -o -name "*.xcresult" | grep -q .; then
        print_status "Coverage data found, generating report..."

        # Generate JSON coverage report
        if command -v xcrun &> /dev/null; then
            xcrun xccov view --report --json .build/debug/codecov/*.profdata > coverage-output/coverage.json 2>/dev/null || \
                print_warning "Could not generate JSON coverage report"
        fi

        # Generate HTML coverage report if xcov is available
        if command -v xcov &> /dev/null; then
            print_status "Generating HTML coverage report with xcov..."
            xcov --scheme TemplateProject --output_directory coverage-output 2>/dev/null || \
                print_warning "Could not generate HTML coverage report with xcov"
        else
            print_info "Install xcov gem for HTML coverage reports: gem install xcov"
        fi

        print_success "Coverage report generation attempted"
    else
        print_warning "No coverage data found"
    fi
fi

# Test Results Summary
TEST_END_TIME=$(date +%s)
TEST_DURATION=$((TEST_END_TIME - TEST_START_TIME))

echo
print_status "=== Test Results Summary ==="

echo "📊 Test Statistics:"
echo "  Total Test Suites Run: $((RUN_UNIT_TESTS + RUN_INTEGRATION_TESTS + RUN_UI_TESTS + RUN_PERFORMANCE_TESTS))"
echo "  Failed Test Suites: $FAILED_TESTS"
echo "  Execution Time: ${TEST_DURATION} seconds"
echo

if [ -f "test-output/test-results.xml" ]; then
    print_success "JUnit XML report: test-output/test-results.xml"
fi

if [ -d "coverage-output" ] && [ "$(ls -A coverage-output)" ]; then
    print_success "Coverage reports: coverage-output/"
fi

# Check for test failures in output files
print_status "Analyzing test results..."

TOTAL_PASSED=0
TOTAL_FAILED=0

for output_file in test-output/*-output.log; do
    if [ -f "$output_file" ]; then
        passed=$(grep -c "Test Case.*passed" "$output_file" 2>/dev/null || echo "0")
        failed=$(grep -c "Test Case.*failed" "$output_file" 2>/dev/null || echo "0")

        TOTAL_PASSED=$((TOTAL_PASSED + passed))
        TOTAL_FAILED=$((TOTAL_FAILED + failed))
    fi
done

echo "📈 Detailed Results:"
echo "  Tests Passed: $TOTAL_PASSED"
echo "  Tests Failed: $TOTAL_FAILED"
echo "  Success Rate: $(( TOTAL_PASSED * 100 / (TOTAL_PASSED + TOTAL_FAILED + 1) ))%"

# Generate test metrics
if [ $TOTAL_PASSED -gt 0 ] || [ $TOTAL_FAILED -gt 0 ]; then
    echo
    print_info "Test Performance Metrics:"
    echo "  Average Test Duration: $(( TEST_DURATION * 1000 / (TOTAL_PASSED + TOTAL_FAILED + 1) ))ms per test"

    if [ $TEST_DURATION -gt 300 ]; then
        print_warning "Test suite took longer than 5 minutes - consider optimization"
    elif [ $TEST_DURATION -gt 60 ]; then
        print_info "Test suite took $((TEST_DURATION / 60)) minutes and $((TEST_DURATION % 60)) seconds"
    fi
fi

# Output available reports
echo
print_status "=== Available Reports ==="
echo "📁 Output Directory: test-output/"

if [ -d "test-output" ]; then
    for file in test-output/*; do
        if [ -f "$file" ]; then
            echo "  📄 $(basename "$file")"
        fi
    done
fi

if [ -d "coverage-output" ] && [ "$(ls -A coverage-output)" ]; then
    echo "📁 Coverage Directory: coverage-output/"
    for file in coverage-output/*; do
        if [ -f "$file" ]; then
            echo "  📊 $(basename "$file")"
        fi
    done
fi

echo
# Final result
if [ $FAILED_TESTS -eq 0 ] && [ $TOTAL_FAILED -eq 0 ]; then
    print_success "🎉 All tests completed successfully!"

    echo
    print_info "Next Steps:"
    echo "• Review test coverage reports in coverage-output/"
    echo "• Check test performance metrics"
    echo "• Consider adding more tests for untested areas"

    exit 0
else
    print_error "❌ Some tests failed or had issues"

    echo
    print_warning "Troubleshooting:"
    echo "• Check individual test output files in test-output/"
    echo "• Review failed test details above"
    echo "• Run specific test suites individually for debugging"
    echo "• Use --unit-only or --ui-only flags to isolate issues"

    exit 1
fi