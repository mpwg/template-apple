#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}🔍${NC} $1"
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

print_status "Starting Swift Package Manager validation..."
echo

# Check if Package.swift exists
if [ ! -f "Package.swift" ]; then
    print_error "Package.swift not found in current directory"
    exit 1
fi

print_success "Package.swift found"

# Check Package.swift syntax
print_status "Validating Package.swift syntax..."
if swift package dump-package > /dev/null 2>&1; then
    print_success "Package.swift syntax is valid"
else
    print_error "Package.swift syntax validation failed"
    swift package dump-package
    exit 1
fi

# Check Swift version compatibility
print_status "Checking Swift version compatibility..."
SWIFT_VERSION=$(swift --version | head -n 1)
print_success "Using Swift version: $SWIFT_VERSION"

# Resolve dependencies
print_status "Resolving package dependencies..."
if swift package resolve; then
    print_success "Dependencies resolved successfully"
else
    print_error "Dependency resolution failed"
    exit 1
fi

# Show dependency tree
print_status "Package dependency tree:"
swift package show-dependencies 2>/dev/null || print_warning "Could not display dependency tree"

# Check for security vulnerabilities (if available)
print_status "Checking for known vulnerabilities..."
if command -v bundle-audit &> /dev/null && [ -f "Gemfile" ]; then
    bundle audit --update --quiet
    bundle audit
    print_success "Ruby dependency security check completed"
else
    print_warning "Bundle audit not available or no Gemfile found"
fi

# Build all targets in debug mode
print_status "Building package in debug mode..."
if swift build; then
    print_success "Debug build successful"
else
    print_error "Debug build failed"
    exit 1
fi

# Build all targets in release mode
print_status "Building package in release mode..."
if swift build --configuration release; then
    print_success "Release build successful"
else
    print_error "Release build failed"
    exit 1
fi

# Run tests if test targets exist
if swift package dump-package | grep -q '"type": "test"'; then
    print_status "Running package tests..."
    if swift test; then
        print_success "All tests passed"
    else
        print_error "Tests failed"
        exit 1
    fi
else
    print_warning "No test targets found"
fi

# Check for common issues
print_status "Checking for common package issues..."

# Check for mixed case in target names
if swift package dump-package | grep -q '"name".*[A-Z].*[a-z]'; then
    print_warning "Mixed case target names detected - consider using lowercase"
fi

# Check for overly broad version ranges
if grep -q '\.upToNextMajor\|branch:' Package.swift; then
    print_warning "Consider using more specific version constraints for production"
fi

# Check package size
PACKAGE_SIZE=$(du -sh . | cut -f1)
print_status "Package size: $PACKAGE_SIZE"

# Performance check
print_status "Checking build performance..."
START_TIME=$(date +%s)
swift build --configuration release > /dev/null 2>&1
END_TIME=$(date +%s)
BUILD_TIME=$((END_TIME - START_TIME))
print_success "Release build completed in ${BUILD_TIME} seconds"

if [ $BUILD_TIME -gt 60 ]; then
    print_warning "Build time is over 1 minute - consider optimizing dependencies"
fi

# License compatibility check
print_status "Checking license compatibility..."
if [ -f "LICENSE" ] || [ -f "LICENSE.md" ] || [ -f "LICENSE.txt" ]; then
    print_success "License file found"
else
    print_warning "No license file found - consider adding one"
fi

# Documentation check
print_status "Checking documentation..."
if [ -f "README.md" ]; then
    print_success "README.md found"
else
    print_warning "README.md not found - consider adding documentation"
fi

# Check for .swiftpm directory (Xcode project files)
if [ -d ".swiftpm" ]; then
    print_success "Xcode project configuration found"
else
    print_warning "No Xcode project configuration - run 'xed .' to generate"
fi

echo
print_success "🎉 Package validation completed successfully!"

# Summary
echo
echo "=== VALIDATION SUMMARY ==="
echo "✅ Package.swift syntax valid"
echo "✅ Dependencies resolved"
echo "✅ Debug build successful"
echo "✅ Release build successful"

if swift package dump-package | grep -q '"type": "test"'; then
    echo "✅ Tests passed"
else
    echo "⚠️  No tests found"
fi

echo "📊 Build time: ${BUILD_TIME} seconds"
echo "💾 Package size: $PACKAGE_SIZE"
echo
echo "For detailed dependency information, run:"
echo "  swift package show-dependencies"
echo "  swift package describe --type json"