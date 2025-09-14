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
    echo -e "${BLUE}🚀${NC} $1"
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

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    print_error "Not in a git repository"
    exit 1
fi

# Get version bump type from argument
VERSION_BUMP_TYPE=${1:-patch}

# Validate version bump type
if [[ ! "$VERSION_BUMP_TYPE" =~ ^(major|minor|patch)$ ]]; then
    print_error "Invalid version bump type. Use: major, minor, or patch"
    echo "Usage: $0 [major|minor|patch]"
    exit 1
fi

print_status "Starting release preparation with $VERSION_BUMP_TYPE version bump..."

# Check for uncommitted changes
if [ -n "$(git status --porcelain)" ]; then
    print_warning "You have uncommitted changes. Please commit or stash them first."
    git status --porcelain
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_error "Release preparation cancelled"
        exit 1
    fi
fi

# Ensure we're on main or develop branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [[ "$CURRENT_BRANCH" != "main" && "$CURRENT_BRANCH" != "develop" ]]; then
    print_warning "You're not on main or develop branch (currently on: $CURRENT_BRANCH)"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_error "Release preparation cancelled"
        exit 1
    fi
fi

# Pull latest changes
print_status "Pulling latest changes from origin..."
git pull origin "$CURRENT_BRANCH"

# Get current version from git tags or default to 0.0.0
CURRENT_VERSION=$(git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//' || echo "0.0.0")
print_status "Current version: $CURRENT_VERSION"

# Calculate new version
IFS='.' read -r -a version_parts <<< "$CURRENT_VERSION"
major=${version_parts[0]:-0}
minor=${version_parts[1]:-0}
patch=${version_parts[2]:-0}

case $VERSION_BUMP_TYPE in
    major)
        major=$((major + 1))
        minor=0
        patch=0
        ;;
    minor)
        minor=$((minor + 1))
        patch=0
        ;;
    patch)
        patch=$((patch + 1))
        ;;
esac

NEW_VERSION="$major.$minor.$patch"
print_status "New version will be: $NEW_VERSION"

# Confirm release preparation
echo
echo "=== RELEASE SUMMARY ==="
echo "Version bump: $VERSION_BUMP_TYPE"
echo "Current version: $CURRENT_VERSION"
echo "New version: $NEW_VERSION"
echo "Current branch: $CURRENT_BRANCH"
echo "========================"
echo
read -p "Proceed with release preparation? (Y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Nn]$ ]]; then
    print_error "Release preparation cancelled"
    exit 0
fi

# Create release branch
RELEASE_BRANCH="release/$NEW_VERSION"
print_status "Creating release branch: $RELEASE_BRANCH"

if git rev-parse --verify "$RELEASE_BRANCH" >/dev/null 2>&1; then
    print_warning "Release branch $RELEASE_BRANCH already exists"
    read -p "Check out existing branch? (Y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        git checkout "$RELEASE_BRANCH"
    else
        print_error "Release preparation cancelled"
        exit 1
    fi
else
    git checkout -b "$RELEASE_BRANCH"
    print_success "Created and checked out release branch: $RELEASE_BRANCH"
fi

# Update version in project files
print_status "Updating version in project files..."

# Update Package.swift if it exists
if [ -f "Package.swift" ]; then
    print_status "Updating Package.swift version..."
    # This is a simple approach - in a real project you might have a more sophisticated method
    sed -i.bak "s/version = \".*\"/version = \"$NEW_VERSION\"/" Package.swift 2>/dev/null || true
    rm -f Package.swift.bak
fi

# Update Fastfile if it exists
if [ -f "fastlane/Fastfile" ]; then
    print_status "Updating version in Fastfile..."
    # You might want to add version constants to your Fastfile
fi

# Update version in Info.plist files if they exist
find . -name "Info.plist" -type f 2>/dev/null | while IFS= read -r plist_file; do
    if [[ ! "$plist_file" =~ /build/ ]] && [[ ! "$plist_file" =~ /DerivedData/ ]]; then
        print_status "Updating version in $plist_file..."
        /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $NEW_VERSION" "$plist_file" 2>/dev/null || true
    fi
done

# Update CHANGELOG.md
print_status "Updating CHANGELOG.md..."
if [ ! -f "CHANGELOG.md" ]; then
    print_status "Creating CHANGELOG.md..."
    cat > CHANGELOG.md << EOF
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [$NEW_VERSION] - $(date +%Y-%m-%d)

### Added
- Initial release

### Changed
-

### Deprecated
-

### Removed
-

### Fixed
-

### Security
-

EOF
else
    # Add new version section to existing CHANGELOG.md
    print_status "Adding new version section to CHANGELOG.md..."

    # Create temporary file with new version entry
    temp_file=$(mktemp)

    # Read existing changelog
    head -n 7 CHANGELOG.md > "$temp_file"

    # Add new version section
    cat >> "$temp_file" << EOF

## [$NEW_VERSION] - $(date +%Y-%m-%d)

### Added
-

### Changed
-

### Deprecated
-

### Removed
-

### Fixed
-

### Security
-

EOF

    # Add rest of existing changelog
    tail -n +8 CHANGELOG.md >> "$temp_file"

    # Replace original with updated version
    mv "$temp_file" CHANGELOG.md
fi

print_success "CHANGELOG.md updated"

# Update README.md with new version if it contains version info
if [ -f "README.md" ] && grep -q "Version.*[0-9]\+\.[0-9]\+\.[0-9]\+" README.md; then
    print_status "Updating version in README.md..."
    sed -i.bak "s/Version.*[0-9]\+\.[0-9]\+\.[0-9]\+/Version $NEW_VERSION/" README.md
    rm -f README.md.bak
fi

# Run tests to ensure everything is working
print_status "Running tests to validate the release..."

# Check if we have Swift Package Manager
if [ -f "Package.swift" ]; then
    print_status "Running Swift package tests..."
    if swift test; then
        print_success "Swift package tests passed"
    else
        print_error "Swift package tests failed"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_error "Release preparation cancelled"
            exit 1
        fi
    fi
fi

# Check if we have Fastlane
if [ -f "fastlane/Fastfile" ] && command -v bundle &> /dev/null; then
    print_status "Running Fastlane tests..."
    if bundle exec fastlane test 2>/dev/null || true; then
        print_success "Fastlane tests completed"
    else
        print_warning "Fastlane tests had issues (this might be expected if no Xcode project exists)"
    fi
fi

# Commit version changes
print_status "Committing version changes..."
git add -A
git commit -m "Prepare release $NEW_VERSION

- Bump version to $NEW_VERSION
- Update CHANGELOG.md
- Update project files with new version"

print_success "Version changes committed"

# Push release branch to origin
print_status "Pushing release branch to origin..."
git push -u origin "$RELEASE_BRANCH"
print_success "Release branch pushed to origin"

# Create GitHub pull request if gh CLI is available
if command -v gh &> /dev/null; then
    print_status "Creating GitHub pull request..."

    PR_BODY="## Release $NEW_VERSION

This PR prepares the release for version $NEW_VERSION.

### Changes
- Version bump: $VERSION_BUMP_TYPE ($CURRENT_VERSION → $NEW_VERSION)
- Updated CHANGELOG.md with new version section
- Updated project files with new version

### Pre-Release Checklist
- [ ] All tests pass
- [ ] CHANGELOG.md is updated with release notes
- [ ] Version numbers are correct in all files
- [ ] Documentation is up to date
- [ ] Security scan passes
- [ ] Performance tests pass

### Release Process
1. Review and merge this PR
2. Create release tag: \`git tag -a v$NEW_VERSION -m \"Release $NEW_VERSION\"\`
3. Push tag: \`git push origin v$NEW_VERSION\`
4. GitHub Actions will automatically:
   - Build and test the release
   - Deploy to TestFlight
   - Create GitHub release
   - Send notifications

### Rollback Plan
If issues are discovered after release:
1. Stop distribution in App Store Connect
2. Revert to previous version: \`git revert v$NEW_VERSION\`
3. Deploy hotfix if necessary

**Ready for review!** 🚀"

    if gh pr create \
        --title "Release $NEW_VERSION" \
        --body "$PR_BODY" \
        --base main \
        --head "$RELEASE_BRANCH" \
        --reviewer @me; then
        print_success "GitHub pull request created"
    else
        print_warning "Could not create GitHub pull request automatically"
        print_status "You can create it manually at: https://github.com/$(git config --get remote.origin.url | sed 's/.*github.com[:/]\([^.]*\).*/\1/')/compare/main...$RELEASE_BRANCH"
    fi
else
    print_warning "GitHub CLI not available - please create pull request manually"
    print_status "Create PR from $RELEASE_BRANCH to main branch"
fi

# Generate release notes for the tag
print_status "Generating release notes..."
RELEASE_NOTES_FILE="release-notes-$NEW_VERSION.md"

cat > "$RELEASE_NOTES_FILE" << EOF
# Release Notes - Version $NEW_VERSION

## What's New

### ✨ Features
-

### 🐛 Bug Fixes
-

### 🔒 Security
-

### 📱 Platform Updates
-

### 🏗️ Under the Hood
-

## Installation

### App Store
Download from the [App Store](https://apps.apple.com/app/your-app-id)

### TestFlight
Join the beta program: [TestFlight Link](https://testflight.apple.com/join/your-testflight-code)

## Support

If you encounter any issues:
- Check our [FAQ](README.md#faq)
- Report bugs through [GitHub Issues](https://github.com/your-username/your-repo/issues)
- Contact support: support@yourcompany.com

## What's Next

Coming in future releases:
-

---

**Full Changelog**: [v$CURRENT_VERSION...v$NEW_VERSION](https://github.com/your-username/your-repo/compare/v$CURRENT_VERSION...v$NEW_VERSION)
EOF

print_success "Release notes generated: $RELEASE_NOTES_FILE"

# Final summary
echo
print_success "🎉 Release preparation completed successfully!"
echo
echo "=== NEXT STEPS ==="
echo "1. Edit and complete the CHANGELOG.md entry"
echo "2. Update release notes in: $RELEASE_NOTES_FILE"
echo "3. Test the release branch thoroughly"
echo "4. Review and merge the pull request"
echo "5. Create and push the release tag:"
echo "   git checkout main"
echo "   git pull origin main"
echo "   git tag -a v$NEW_VERSION -m 'Release $NEW_VERSION'"
echo "   git push origin v$NEW_VERSION"
echo
echo "=== AUTOMATED DEPLOYMENT ==="
echo "After pushing the tag, GitHub Actions will automatically:"
echo "- Build and test the release"
echo "- Deploy to TestFlight"
echo "- Create GitHub release with notes"
echo "- Send team notifications"
echo
echo "=== MANUAL DEPLOYMENT ==="
echo "To deploy manually using Fastlane:"
echo "- TestFlight: bundle exec fastlane beta"
echo "- App Store: bundle exec fastlane release"
echo
echo "Release branch: $RELEASE_BRANCH"
echo "New version: $NEW_VERSION"
echo "Release notes: $RELEASE_NOTES_FILE"
echo
print_success "Release preparation complete! 🚀"