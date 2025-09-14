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
    echo -e "${BLUE}📦${NC} $1"
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
    echo -e "${BLUE}ℹ️${NC} $1"
}

# Check if Package.swift exists
if [ ! -f "Package.swift" ]; then
    print_error "Package.swift not found in current directory"
    exit 1
fi

print_status "Starting Swift Package Manager dependency update..."
echo

# Backup Package.resolved before updating
if [ -f "Package.resolved" ]; then
    print_status "Backing up Package.resolved..."
    cp Package.resolved Package.resolved.backup
    print_success "Backup created: Package.resolved.backup"
else
    print_warning "No Package.resolved found - this will be a fresh resolution"
fi

# Show current dependencies
print_status "Current dependency tree:"
if swift package show-dependencies 2>/dev/null; then
    echo
else
    print_warning "Could not display current dependencies"
fi

# Store current resolved versions for comparison
TEMP_BEFORE="/tmp/deps_before_$$.json"
TEMP_AFTER="/tmp/deps_after_$$.json"

if [ -f "Package.resolved" ]; then
    cp Package.resolved "$TEMP_BEFORE"
fi

# Update all dependencies
print_status "Updating all dependencies..."
if swift package update; then
    print_success "Dependencies updated successfully"
else
    print_error "Dependency update failed"

    # Restore backup if update failed
    if [ -f "Package.resolved.backup" ]; then
        print_status "Restoring Package.resolved from backup..."
        mv Package.resolved.backup Package.resolved
        print_success "Package.resolved restored"
    fi

    exit 1
fi

# Show updated dependency tree
print_status "Updated dependency tree:"
if swift package show-dependencies 2>/dev/null; then
    echo
else
    print_warning "Could not display updated dependencies"
fi

# Compare versions if we had a previous Package.resolved
if [ -f "Package.resolved" ] && [ -f "$TEMP_BEFORE" ]; then
    print_status "Analyzing dependency changes..."

    # Extract package names and versions for comparison
    python3 -c "
import json
import sys

def extract_deps(file_path):
    try:
        with open(file_path, 'r') as f:
            data = json.load(f)
        deps = {}
        if 'pins' in data:
            for pin in data['pins']:
                name = pin.get('identity', pin.get('package', 'unknown'))
                state = pin.get('state', {})
                version = state.get('version', state.get('revision', 'unknown'))
                deps[name] = version
        return deps
    except:
        return {}

before = extract_deps('$TEMP_BEFORE')
after = extract_deps('Package.resolved')

print('=== DEPENDENCY CHANGES ===')
if not before and not after:
    print('No dependency information available')
elif not before:
    print('First time dependency resolution:')
    for name, version in sorted(after.items()):
        print(f'  + {name}: {version}')
else:
    updated = []
    added = []
    removed = []

    for name, version in after.items():
        if name not in before:
            added.append((name, version))
        elif before[name] != version:
            updated.append((name, before[name], version))

    for name in before:
        if name not in after:
            removed.append((name, before[name]))

    if updated:
        print('Updated packages:')
        for name, old_ver, new_ver in sorted(updated):
            print(f'  ↑ {name}: {old_ver} → {new_ver}')

    if added:
        print('Added packages:')
        for name, version in sorted(added):
            print(f'  + {name}: {version}')

    if removed:
        print('Removed packages:')
        for name, version in sorted(removed):
            print(f'  - {name}: {version}')

    if not updated and not added and not removed:
        print('No dependency changes detected')
" 2>/dev/null || print_warning "Could not analyze dependency changes (Python 3 required)"

    echo
fi

# Validate the updated dependencies
print_status "Validating updated dependencies..."

# Check Package.swift syntax
if swift package dump-package > /dev/null 2>&1; then
    print_success "Package.swift syntax is still valid"
else
    print_error "Package.swift syntax validation failed after update"
    exit 1
fi

# Build with updated dependencies
print_status "Building with updated dependencies..."
if swift build; then
    print_success "Build successful with updated dependencies"
else
    print_error "Build failed with updated dependencies"

    # Offer to restore backup
    if [ -f "Package.resolved.backup" ]; then
        echo
        print_warning "Build failed with updated dependencies."
        read -p "Restore previous Package.resolved? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            mv Package.resolved.backup Package.resolved
            print_success "Package.resolved restored"
            print_info "You may need to resolve conflicts manually"
        fi
    fi

    exit 1
fi

# Run tests with updated dependencies
if swift package dump-package | grep -q '"type": "test"'; then
    print_status "Running tests with updated dependencies..."
    if swift test; then
        print_success "All tests pass with updated dependencies"
    else
        print_warning "Some tests failed with updated dependencies"
        print_info "Review test failures and update test code if needed"
    fi
else
    print_warning "No test targets found - consider adding tests"
fi

# Security check for updated dependencies
print_status "Checking updated dependencies for security issues..."
if command -v bundle-audit &> /dev/null && [ -f "Gemfile" ]; then
    if bundle audit --update --quiet; then
        if bundle audit; then
            print_success "No security vulnerabilities detected in Ruby dependencies"
        else
            print_warning "Security vulnerabilities detected in Ruby dependencies"
            print_info "Run 'bundle audit' for details"
        fi
    fi
else
    print_info "Bundle audit not available - manual security review recommended"
fi

# Performance check
print_status "Checking build performance with updated dependencies..."
START_TIME=$(date +%s)
swift build --configuration release > /dev/null 2>&1
END_TIME=$(date +%s)
BUILD_TIME=$((END_TIME - START_TIME))
print_success "Release build completed in ${BUILD_TIME} seconds"

if [ $BUILD_TIME -gt 60 ]; then
    print_warning "Build time increased - consider reviewing new dependencies"
fi

# Clean up temporary files
rm -f "$TEMP_BEFORE" "$TEMP_AFTER"

# Clean up backup (keep for safety in case of issues)
if [ -f "Package.resolved.backup" ]; then
    print_info "Keeping Package.resolved.backup for safety"
    print_info "Remove it manually after confirming everything works correctly"
fi

echo
print_success "🎉 Dependency update completed successfully!"

# Summary and next steps
echo
echo "=== UPDATE SUMMARY ==="
echo "✅ Dependencies updated and resolved"
echo "✅ Package.swift syntax validated"
echo "✅ Build successful with updated dependencies"

if swift package dump-package | grep -q '"type": "test"'; then
    echo "✅ Tests completed"
else
    echo "⚠️  No tests to run"
fi

echo "🕐 Build time: ${BUILD_TIME} seconds"
echo

echo "=== NEXT STEPS ==="
echo "1. Test your application thoroughly with updated dependencies"
echo "2. Commit Package.resolved to version control:"
echo "   git add Package.resolved"
echo "   git commit -m \"Update package dependencies\""
echo "3. Consider updating your CI/CD cache if build times have changed"
echo "4. Remove Package.resolved.backup once you're confident in the update"
echo

echo "=== USEFUL COMMANDS ==="
echo "View dependency details:"
echo "  swift package show-dependencies"
echo "  swift package describe --type json"
echo
echo "Revert to previous versions if needed:"
echo "  mv Package.resolved.backup Package.resolved"
echo "  swift package resolve"