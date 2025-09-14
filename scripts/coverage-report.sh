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
    echo -e "${BLUE}📊${NC} $1"
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

# Configuration
COVERAGE_THRESHOLD=80.0
OUTPUT_DIR="coverage-output"
GENERATE_HTML=true
GENERATE_JSON=true
SHOW_UNCOVERED=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --threshold)
            COVERAGE_THRESHOLD="$2"
            shift 2
            ;;
        --output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --json-only)
            GENERATE_HTML=false
            GENERATE_JSON=true
            shift
            ;;
        --html-only)
            GENERATE_HTML=true
            GENERATE_JSON=false
            shift
            ;;
        --show-uncovered)
            SHOW_UNCOVERED=true
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --threshold PERCENT  Coverage threshold (default: 80.0)"
            echo "  --output-dir DIR     Output directory (default: coverage-output)"
            echo "  --json-only          Generate only JSON report"
            echo "  --html-only          Generate only HTML report"
            echo "  --show-uncovered     Show uncovered lines in output"
            echo "  --help               Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                           # Generate all reports with 80% threshold"
            echo "  $0 --threshold 90            # Set 90% coverage threshold"
            echo "  $0 --show-uncovered          # Show which lines are not covered"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

print_status "Generating code coverage report..."

# Check if we're in a Swift package
if [ ! -f "Package.swift" ]; then
    print_error "Package.swift not found. Make sure you're in a Swift package directory."
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

print_status "Running tests with code coverage enabled..."

# Run tests with coverage
START_TIME=$(date +%s)

if swift test --enable-code-coverage --parallel; then
    print_success "Tests completed successfully"
else
    print_warning "Tests completed with some failures - continuing with coverage analysis"
fi

END_TIME=$(date +%s)
TEST_DURATION=$((END_TIME - START_TIME))

print_success "Test execution completed in ${TEST_DURATION} seconds"

# Look for coverage data
print_status "Searching for coverage data..."

# Find .profdata files
PROFDATA_FILES=$(find . -name "*.profdata" -type f 2>/dev/null || echo "")
XCRESULT_FILES=$(find . -name "*.xcresult" -type d 2>/dev/null || echo "")

if [ -z "$PROFDATA_FILES" ] && [ -z "$XCRESULT_FILES" ]; then
    print_error "No coverage data found. Make sure tests were run with --enable-code-coverage"
    exit 1
fi

print_success "Coverage data found"

# Generate JSON coverage report
if [ "$GENERATE_JSON" = true ]; then
    print_status "Generating JSON coverage report..."

    JSON_OUTPUT="$OUTPUT_DIR/coverage.json"

    if [ -n "$PROFDATA_FILES" ]; then
        # Use profdata files
        for profdata in $PROFDATA_FILES; do
            if xcrun llvm-cov export -format=text -summary-only "$profdata" > "$JSON_OUTPUT" 2>/dev/null; then
                print_success "JSON coverage report generated: $JSON_OUTPUT"
                break
            fi
        done
    elif [ -n "$XCRESULT_FILES" ]; then
        # Use xcresult files
        for xcresult in $XCRESULT_FILES; do
            if xcrun xccov view --report --json "$xcresult" > "$JSON_OUTPUT" 2>/dev/null; then
                print_success "JSON coverage report generated: $JSON_OUTPUT"
                break
            fi
        done
    fi

    if [ ! -f "$JSON_OUTPUT" ] || [ ! -s "$JSON_OUTPUT" ]; then
        print_warning "Could not generate JSON coverage report"
    fi
fi

# Generate detailed text report
print_status "Generating detailed coverage report..."

TEXT_OUTPUT="$OUTPUT_DIR/coverage.txt"

if [ -n "$XCRESULT_FILES" ]; then
    for xcresult in $XCRESULT_FILES; do
        if xcrun xccov view --report "$xcresult" > "$TEXT_OUTPUT" 2>/dev/null; then
            print_success "Text coverage report generated: $TEXT_OUTPUT"
            break
        fi
    done
fi

# Generate HTML coverage report
if [ "$GENERATE_HTML" = true ]; then
    print_status "Generating HTML coverage report..."

    # Try with xcov gem if available
    if command -v xcov &> /dev/null; then
        print_status "Using xcov to generate HTML report..."

        # Find xcworkspace or xcodeproj files
        WORKSPACE=$(find . -name "*.xcworkspace" -type d | head -1)
        PROJECT=$(find . -name "*.xcodeproj" -type d | head -1)

        if [ -n "$WORKSPACE" ]; then
            SCHEME_NAME=$(basename "$WORKSPACE" .xcworkspace)
            if xcov --workspace "$WORKSPACE" --scheme "$SCHEME_NAME" --output_directory "$OUTPUT_DIR/html" 2>/dev/null; then
                print_success "HTML coverage report generated with xcov: $OUTPUT_DIR/html/"
            else
                print_warning "xcov failed - may need proper Xcode project setup"
            fi
        elif [ -n "$PROJECT" ]; then
            SCHEME_NAME=$(basename "$PROJECT" .xcodeproj)
            if xcov --project "$PROJECT" --scheme "$SCHEME_NAME" --output_directory "$OUTPUT_DIR/html" 2>/dev/null; then
                print_success "HTML coverage report generated with xcov: $OUTPUT_DIR/html/"
            else
                print_warning "xcov failed - may need proper Xcode project setup"
            fi
        else
            print_info "No Xcode workspace/project found for xcov HTML generation"
        fi
    else
        print_info "xcov not available. Install with: gem install xcov"

        # Alternative: generate basic HTML from JSON
        if [ -f "$OUTPUT_DIR/coverage.json" ]; then
            print_status "Generating basic HTML report from JSON data..."

            HTML_OUTPUT="$OUTPUT_DIR/coverage.html"
            cat > "$HTML_OUTPUT" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Code Coverage Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background-color: #f0f0f0; padding: 20px; border-radius: 5px; }
        .metric { margin: 10px 0; }
        .high-coverage { color: green; }
        .medium-coverage { color: orange; }
        .low-coverage { color: red; }
        table { border-collapse: collapse; width: 100%; margin-top: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Code Coverage Report</h1>
        <p>Generated: $(date)</p>
    </div>

    <div class="metric">
        <h2>Coverage Summary</h2>
        <p>Detailed coverage data available in coverage.json</p>
    </div>

    <h2>How to Improve Coverage</h2>
    <ul>
        <li>Identify uncovered functions and add tests</li>
        <li>Add edge case testing</li>
        <li>Test error handling paths</li>
        <li>Remove dead code if appropriate</li>
    </ul>
</body>
</html>
EOF

            print_success "Basic HTML report generated: $HTML_OUTPUT"
        fi
    fi
fi

# Analyze coverage data
print_status "Analyzing coverage data..."

if [ -f "$TEXT_OUTPUT" ]; then
    # Extract overall coverage percentage
    COVERAGE_PERCENT=$(grep -E "Coverage.*%" "$TEXT_OUTPUT" | head -1 | grep -oE "[0-9]+\.[0-9]+" || echo "0")

    if [ -n "$COVERAGE_PERCENT" ]; then
        print_info "Overall Coverage: ${COVERAGE_PERCENT}%"

        # Compare with threshold
        if (( $(echo "$COVERAGE_PERCENT >= $COVERAGE_THRESHOLD" | bc -l) )); then
            print_success "Coverage meets threshold (>= ${COVERAGE_THRESHOLD}%)"
            COVERAGE_STATUS="PASS"
        else
            print_warning "Coverage below threshold (< ${COVERAGE_THRESHOLD}%)"
            COVERAGE_STATUS="FAIL"
        fi
    else
        print_warning "Could not determine coverage percentage"
        COVERAGE_STATUS="UNKNOWN"
    fi

    # Show uncovered areas if requested
    if [ "$SHOW_UNCOVERED" = true ]; then
        print_status "Uncovered areas:"
        echo
        grep -A 5 -B 2 "0.00%" "$TEXT_OUTPUT" 2>/dev/null || print_info "No specific uncovered areas identified in report"
    fi

    # Generate coverage summary
    SUMMARY_OUTPUT="$OUTPUT_DIR/coverage-summary.txt"
    cat > "$SUMMARY_OUTPUT" << EOF
# Code Coverage Summary

Generated: $(date)
Test Duration: ${TEST_DURATION} seconds
Coverage Threshold: ${COVERAGE_THRESHOLD}%
Overall Coverage: ${COVERAGE_PERCENT:-Unknown}%
Status: $COVERAGE_STATUS

## Files Generated
EOF

    if [ -f "$OUTPUT_DIR/coverage.json" ]; then
        echo "- JSON Report: coverage.json" >> "$SUMMARY_OUTPUT"
    fi

    if [ -f "$OUTPUT_DIR/coverage.txt" ]; then
        echo "- Text Report: coverage.txt" >> "$SUMMARY_OUTPUT"
    fi

    if [ -f "$OUTPUT_DIR/coverage.html" ]; then
        echo "- HTML Report: coverage.html" >> "$SUMMARY_OUTPUT"
    fi

    if [ -d "$OUTPUT_DIR/html" ]; then
        echo "- Detailed HTML Report: html/" >> "$SUMMARY_OUTPUT"
    fi

    print_success "Coverage summary generated: $SUMMARY_OUTPUT"
fi

# Generate coverage badge data (for GitHub badges, etc.)
if [ -n "$COVERAGE_PERCENT" ]; then
    BADGE_OUTPUT="$OUTPUT_DIR/coverage-badge.json"
    cat > "$BADGE_OUTPUT" << EOF
{
  "schemaVersion": 1,
  "label": "coverage",
  "message": "${COVERAGE_PERCENT}%",
  "color": "$([ $(echo "$COVERAGE_PERCENT >= 80" | bc -l) -eq 1 ] && echo "brightgreen" || ([ $(echo "$COVERAGE_PERCENT >= 60" | bc -l) -eq 1 ] && echo "yellow" || echo "red"))"
}
EOF
    print_success "Coverage badge data generated: $BADGE_OUTPUT"
fi

# Identify top uncovered files
if [ -f "$TEXT_OUTPUT" ]; then
    print_status "Analyzing file-level coverage..."

    TOP_UNCOVERED="$OUTPUT_DIR/uncovered-files.txt"
    echo "# Files with Lowest Coverage" > "$TOP_UNCOVERED"
    echo "Generated: $(date)" >> "$TOP_UNCOVERED"
    echo "" >> "$TOP_UNCOVERED"

    # Extract file coverage information (this is a simplified approach)
    grep -E "\.swift.*[0-9]+\.[0-9]+%" "$TEXT_OUTPUT" 2>/dev/null | \
        sort -t% -k1,1n | \
        head -10 >> "$TOP_UNCOVERED" || \
        echo "No file-level coverage data available" >> "$TOP_UNCOVERED"

    print_success "Uncovered files report: $TOP_UNCOVERED"
fi

# Generate improvement recommendations
RECOMMENDATIONS="$OUTPUT_DIR/coverage-recommendations.md"
cat > "$RECOMMENDATIONS" << EOF
# Coverage Improvement Recommendations

Generated: $(date)
Current Coverage: ${COVERAGE_PERCENT:-Unknown}%
Target: ${COVERAGE_THRESHOLD}%

## Quick Wins

1. **Add Unit Tests**: Focus on business logic and utility functions
2. **Test Error Paths**: Add tests for error handling and edge cases
3. **Mock Dependencies**: Use mocking to test isolated components
4. **Property Testing**: Test with various input combinations

## Areas to Focus

$(if [ -f "$TOP_UNCOVERED" ]; then
    echo "Based on the analysis, consider adding tests for:"
    head -5 "$TOP_UNCOVERED" | tail -n +4
else
    echo "Run the coverage report with detailed analysis to identify specific areas."
fi)

## Testing Strategies

### Unit Tests
- Test individual functions and methods
- Mock external dependencies
- Test edge cases and error conditions

### Integration Tests
- Test component interactions
- Verify data flow between layers
- Test external API integrations

### Property-Based Testing
- Test with random inputs
- Verify invariants hold
- Find edge cases automatically

## Implementation Steps

1. Review uncovered files list
2. Prioritize high-impact, low-effort areas
3. Add tests for critical business logic
4. Improve error handling coverage
5. Add performance and security tests

## Measuring Progress

- Run coverage reports regularly
- Set incremental coverage targets
- Review coverage in code reviews
- Monitor coverage trends over time
EOF

print_success "Coverage recommendations generated: $RECOMMENDATIONS"

# Final summary
echo
print_status "=== Coverage Report Summary ==="

echo "📊 Coverage Analysis:"
if [ -n "$COVERAGE_PERCENT" ]; then
    echo "  Overall Coverage: ${COVERAGE_PERCENT}%"
    echo "  Threshold: ${COVERAGE_THRESHOLD}%"
    echo "  Status: $COVERAGE_STATUS"
else
    echo "  Coverage percentage could not be determined"
fi

echo "  Test Duration: ${TEST_DURATION} seconds"
echo

echo "📁 Generated Reports:"
for file in "$OUTPUT_DIR"/*; do
    if [ -f "$file" ]; then
        echo "  📄 $(basename "$file")"
    elif [ -d "$file" ]; then
        echo "  📁 $(basename "$file")/"
    fi
done

echo
print_info "Next Steps:"
echo "• Review detailed coverage reports in $OUTPUT_DIR/"
echo "• Check coverage-recommendations.md for improvement suggestions"
echo "• Focus testing efforts on uncovered critical areas"
echo "• Set up coverage monitoring in your CI/CD pipeline"

# Exit with appropriate status
if [ "$COVERAGE_STATUS" = "PASS" ]; then
    print_success "🎉 Coverage report completed - threshold met!"
    exit 0
elif [ "$COVERAGE_STATUS" = "FAIL" ]; then
    print_warning "⚠️ Coverage report completed - below threshold"
    echo
    print_info "Improvement needed to meet ${COVERAGE_THRESHOLD}% threshold"
    exit 1
else
    print_success "✅ Coverage report completed"
    exit 0
fi