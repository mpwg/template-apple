# Xcode Project Setup Guide

This comprehensive guide will walk you through setting up a new Xcode project using this template repository, integrating with Fastlane, CI/CD, and all the configured tooling.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Start (15-Minute Setup)](#quick-start-15-minute-setup)
- [Detailed Setup Guide](#detailed-setup-guide)
- [Project Configuration](#project-configuration)
- [Multi-Platform Setup](#multi-platform-setup)
- [Integration with Template Tools](#integration-with-template-tools)
- [Testing and Validation](#testing-and-validation)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)

## Prerequisites

### System Requirements

- **macOS 14.0+** (Sonoma or later)
- **Xcode 15.4+** with command line tools
- **Swift 5.9+**
- **Git 2.30+**
- **Ruby 3.2+** with Bundler

### Development Tools

```bash
# Install required tools via Homebrew
brew install git
brew install ruby
brew install swiftlint
brew install swiftformat

# Install GitHub CLI
brew install gh

# Install Fastlane
gem install fastlane
```

### Verify Prerequisites

```bash
# Run the verification script
./scripts/setup-secrets.sh --validate

# Or check manually
xcode-select --version
swift --version
git --version
ruby --version
bundle --version
gh --version
```

## Quick Start (15-Minute Setup)

For experienced developers who want to get started quickly:

### 1. Clone Template and Create Project

```bash
# Clone this template repository
git clone <this-repository-url> YourAppName
cd YourAppName

# Remove template git history
rm -rf .git
git init
git add .
git commit -m "chore: initial commit from template"

# Create new GitHub repository and push
gh repo create YourAppName --private --source=. --remote=origin --push
```

### 2. Run Setup Script

```bash
# Run the automated setup script
./scripts/setup-xcode-project.sh --app-name "YourAppName" --bundle-id "com.yourcompany.yourapp"
```

### 3. Create Xcode Project

1. Open Xcode
2. **File** → **New** → **Project**
3. Choose **iOS App** (or **macOS App**)
4. Configure:
   - **Product Name**: YourAppName
   - **Bundle Identifier**: com.yourcompany.yourapp
   - **Language**: Swift
   - **Use Core Data**: (as needed)
   - **Include Tests**: Yes
5. Save in the repository root directory

### 4. Configure Environment

```bash
# Setup environment variables
cp .env.template .env
# Edit .env with your actual values

# Upload secrets to GitHub
gh secret set -f .env

# Setup git hooks
./scripts/setup-git-hooks.sh
```

### 5. Validate Setup

```bash
# Run validation script
./scripts/validate-setup.sh

# Build project to verify everything works
xcodebuild -project YourAppName.xcodeproj -scheme YourAppName build
```

**You're done!** 🎉 Your project is now ready for development.

## Detailed Setup Guide

### Step 1: Template Repository Setup

#### Clone and Initialize

```bash
# Clone the template repository
git clone <template-repository-url> YourAppName
cd YourAppName

# Initialize as new project
rm -rf .git
git init
```

#### Update Template Files

```bash
# Run placeholder replacement script
./scripts/replace-placeholders.sh \
  --app-name "YourAppName" \
  --bundle-id "com.yourcompany.yourapp" \
  --company-name "Your Company" \
  --author-name "Your Name"
```

This script will update:
- README.md placeholders
- Fastlane configuration
- GitHub Actions workflows
- Environment templates

### Step 2: Xcode Project Creation

#### Create New iOS Project

1. **Launch Xcode**
2. **File** → **New** → **Project**
3. **iOS** tab → **App**
4. **Next**

#### Configure Project Details

**Product Name**: YourAppName
**Team**: Select your development team
**Organization Identifier**: com.yourcompany
**Bundle Identifier**: com.yourcompany.yourapp
**Language**: Swift
**Interface**: SwiftUI or UIKit (your choice)
**Use Core Data**: Check if you need data persistence
**Include Tests**: Check both Unit Tests and UI Tests

#### Choose Location

- Navigate to your cloned template directory
- **Create** the project **inside** the template directory
- The structure should be:
  ```
  YourAppName/
  ├── YourAppName/          # Xcode project files
  ├── YourAppName.xcodeproj/
  ├── .env.template
  ├── .swiftlint.yml
  ├── fastlane/
  └── ...other template files
  ```

### Step 3: Project Configuration

#### Build Settings Configuration

1. **Select project** in Navigator
2. **Select your target**
3. **Build Settings** tab

**Deployment Target**:
- iOS: 15.0 (or your minimum supported version)
- macOS: 12.0 (if supporting macOS)

**Swift Language Version**:
- Swift 5

**Code Signing**:
- Signing Certificate: Apple Development (Debug)
- Signing Certificate: Apple Distribution (Release)
- Provisioning Profile: Automatic (initially)

#### Build Configurations

Create additional configurations for different environments:

1. **Select project** → **Info** tab
2. **Configurations** section
3. **Duplicate** "Release" configuration
4. **Rename** to "Staging"

Configure each environment:

**Debug Configuration**:
```
OTHER_SWIFT_FLAGS = -DDEBUG
SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG
```

**Staging Configuration**:
```
OTHER_SWIFT_FLAGS = -DSTAGING
SWIFT_ACTIVE_COMPILATION_CONDITIONS = STAGING
```

**Release Configuration**:
```
OTHER_SWIFT_FLAGS = -DRELEASE
SWIFT_ACTIVE_COMPILATION_CONDITIONS = RELEASE
```

#### Create Schemes

1. **Product** → **Scheme** → **Manage Schemes**
2. **Duplicate** existing scheme
3. **Rename** schemes:
   - YourAppName-Debug
   - YourAppName-Staging
   - YourAppName-Release

Configure each scheme:
- **Run** → **Info** → **Build Configuration**
- **Archive** → **Build Configuration**

### Step 4: Add Build Phases

#### SwiftLint Build Phase

1. **Select target** → **Build Phases**
2. **+** → **New Run Script Phase**
3. **Name**: SwiftLint
4. **Script**:
   ```bash
   if [[ "$(uname -m)" == arm64 ]]; then
       export PATH="/opt/homebrew/bin:$PATH"
   fi

   if which swiftlint > /dev/null; then
       swiftlint lint --config "${SRCROOT}/.swiftlint.yml"
   else
       echo "warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint"
   fi
   ```
5. **Move** SwiftLint phase **before** "Compile Sources"

#### SwiftFormat Build Phase (Optional)

1. **+** → **New Run Script Phase**
2. **Name**: SwiftFormat
3. **Script**:
   ```bash
   if [[ "$(uname -m)" == arm64 ]]; then
       export PATH="/opt/homebrew/bin:$PATH"
   fi

   if which swiftformat > /dev/null; then
       swiftformat --config "${SRCROOT}/.swiftformat" "${SRCROOT}"
   fi
   ```

### Step 5: Configure Capabilities

#### App Capabilities

1. **Select target** → **Signing & Capabilities**
2. **+ Capability** (add as needed):
   - Push Notifications
   - Background Modes
   - App Groups
   - Keychain Sharing
   - Associated Domains

#### Entitlements File

Xcode will create entitlements file automatically when capabilities are added.

### Step 6: Multi-Platform Setup (Optional)

#### Add macOS Target

1. **Select project** → **+** (add target)
2. **macOS** → **App**
3. **Product Name**: YourAppName macOS
4. **Bundle Identifier**: com.yourcompany.yourapp.macos

#### Create Shared Framework

1. **+** → **Framework**
2. **Product Name**: YourAppCore
3. **Platform**: iOS (create additional for macOS)
4. **Move shared code** to framework

#### Configure Mac Catalyst (Alternative)

1. **Select iOS target**
2. **Deployment Info**
3. **Check** "Mac Catalyst"
4. **Configure** Mac-specific settings

### Step 7: Environment Integration

#### Environment Variables

```bash
# Copy environment template
cp .env.template .env

# Edit with your values
vim .env
```

**Required Variables**:
```bash
# App Configuration
APP_NAME=YourAppName
BUNDLE_IDENTIFIER=com.yourcompany.yourapp
APPLE_ID=your-apple-id@example.com
DEVELOPMENT_TEAM=YOUR_TEAM_ID

# Fastlane Match
MATCH_PASSWORD=your_secure_password
MATCH_GIT_URL=https://github.com/yourorg/certificates.git
MATCH_GIT_BASIC_AUTHORIZATION=your_token

# GitHub Secrets
gh secret set -f .env
```

#### Update Fastlane Configuration

Edit `fastlane/Appfile`:
```ruby
app_identifier(ENV["BUNDLE_IDENTIFIER"])
apple_id(ENV["APPLE_ID"])
team_id(ENV["DEVELOPMENT_TEAM"])

# For Mac Catalyst or macOS
# app_identifier("com.yourcompany.yourapp.macos")
```

Edit `fastlane/Fastfile` app identifiers and schemes.

### Step 8: Testing Configuration

#### Unit Tests Setup

1. **Select test target**
2. **Build Settings**
3. **Test Host**: $(BUILT_PRODUCTS_DIR)/YourAppName.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/YourAppName

#### UI Tests Setup

1. **Select UI test target**
2. **Build Settings**
3. **Target Application**: YourAppName

#### Add Test Dependencies (Optional)

If using Swift Package Manager for testing:
1. **File** → **Add Package Dependencies**
2. Add common testing frameworks:
   - Quick: `https://github.com/Quick/Quick.git`
   - Nimble: `https://github.com/Quick/Nimble.git`

### Step 9: Swift Package Dependencies

#### Add Common Dependencies

1. **File** → **Add Package Dependencies**
2. **Add popular packages**:
   - Alamofire: `https://github.com/Alamofire/Alamofire.git`
   - SDWebImage: `https://github.com/SDWebImage/SDWebImage.git`
   - SnapKit: `https://github.com/SnapKit/SnapKit.git`

#### Configure Package.swift (if creating package)

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "YourAppName",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(name: "YourAppCore", targets: ["YourAppCore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.8.0"),
    ],
    targets: [
        .target(name: "YourAppCore", dependencies: ["Alamofire"]),
        .testTarget(name: "YourAppCoreTests", dependencies: ["YourAppCore"]),
    ]
)
```

## Multi-Platform Setup

### iOS + macOS Universal App

#### Shared Code Architecture

```
YourApp/
├── Shared/
│   ├── Models/
│   ├── Services/
│   ├── ViewModels/
│   └── Extensions/
├── iOS/
│   ├── Views/
│   ├── Controllers/
│   └── Resources/
├── macOS/
│   ├── Views/
│   ├── Controllers/
│   └── Resources/
└── Tests/
```

#### Conditional Compilation

```swift
#if os(iOS)
import UIKit
typealias PlatformView = UIView
#elseif os(macOS)
import AppKit
typealias PlatformView = NSView
#endif

#if canImport(UIKit)
// iOS-specific code
#elseif canImport(AppKit)
// macOS-specific code
#endif
```

#### Target Configuration

**iOS Target**:
- Deployment Target: iOS 15.0
- Supported Devices: iPhone, iPad
- Orientation: Portrait, Landscape

**macOS Target**:
- Deployment Target: macOS 12.0
- Category: Productivity (or appropriate category)

### Mac Catalyst Configuration

#### Enable Mac Catalyst

1. **Select iOS target**
2. **Deployment Info**
3. **iPad Deployment Target**: 15.0+
4. **Check** "Mac Catalyst"
5. **Mac Catalyst Deployment Target**: 12.0+

#### Mac-Specific Settings

```swift
#if targetEnvironment(macCatalyst)
// Mac Catalyst specific code
if let windowScene = view.window?.windowScene {
    windowScene.sizeRestrictions?.minimumSize = CGSize(width: 800, height: 600)
    windowScene.sizeRestrictions?.maximumSize = CGSize(width: 1200, height: 900)
}
#endif
```

## Integration with Template Tools

### GitHub Actions

The template includes GitHub Actions workflows that will automatically work with your Xcode project:

**`.github/workflows/ios.yml`** - Builds and tests iOS app
**`.github/workflows/macos.yml`** - Builds and tests macOS app (if applicable)

**Update workflow files** with your project name:
```yaml
name: iOS Build and Test

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  build:
    runs-on: macos-latest

    steps:
    - uses: actions/checkout@v4

    - name: Build
      run: |
        xcodebuild build \
          -project YourAppName.xcodeproj \
          -scheme YourAppName \
          -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Fastlane Integration

**Update lanes** in `fastlane/Fastfile`:

```ruby
# Build lane
lane :build do
  build_app(
    project: "YourAppName.xcodeproj",
    scheme: "YourAppName",
    output_directory: "./build"
  )
end

# Test lane
lane :test do
  run_tests(
    project: "YourAppName.xcodeproj",
    scheme: "YourAppName",
    devices: ["iPhone 15", "iPad Air (5th generation)"]
  )
end

# Release lane
lane :release do
  match(type: "appstore")
  build_app(
    project: "YourAppName.xcodeproj",
    scheme: "YourAppName"
  )
  upload_to_app_store
end
```

### Code Signing with Match

**Initialize Match** (first time only):
```bash
bundle exec fastlane match init
```

**Generate certificates**:
```bash
# Development certificates
bundle exec fastlane match development

# App Store certificates
bundle exec fastlane match appstore
```

**Configure Xcode**:
1. **Select target** → **Signing & Capabilities**
2. **Automatically manage signing**: Unchecked
3. **Provisioning Profile**:
   - Debug: match Development com.yourcompany.yourapp
   - Release: match AppStore com.yourcompany.yourapp

## Testing and Validation

### Build Verification

```bash
# Build all schemes
xcodebuild build -project YourAppName.xcodeproj -scheme YourAppName
xcodebuild build -project YourAppName.xcodeproj -scheme "YourAppName-Staging"

# Run tests
xcodebuild test \
  -project YourAppName.xcodeproj \
  -scheme YourAppName \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Fastlane Verification

```bash
# Test Fastlane setup
bundle exec fastlane test

# Test build
bundle exec fastlane build

# Verify Match setup
bundle exec fastlane match development --readonly
```

### CI/CD Verification

```bash
# Commit and push to trigger workflows
git add .
git commit -m "feat: initial Xcode project setup"
git push origin main
```

Check GitHub Actions tab for build results.

### Setup Validation Checklist

Run the automated validation:
```bash
./scripts/validate-setup.sh
```

**Manual Checklist**:
- [ ] Xcode project builds successfully
- [ ] All targets build without warnings
- [ ] Unit tests run and pass
- [ ] SwiftLint runs without errors
- [ ] Fastlane commands work
- [ ] GitHub Actions workflows pass
- [ ] Environment variables are configured
- [ ] Code signing works for all configurations

## Troubleshooting

### Common Issues

#### Build Errors

**Issue**: "No such module" errors
**Solution**:
1. Check Swift Package dependencies are properly added
2. Verify target dependencies in Build Phases
3. Clean build folder: Product → Clean Build Folder

**Issue**: SwiftLint warnings/errors
**Solution**:
```bash
# Auto-fix common issues
swiftlint lint --fix

# Check specific files
swiftlint lint path/to/file.swift
```

#### Code Signing Issues

**Issue**: "No matching provisioning profiles found"
**Solution**:
1. Run `bundle exec fastlane match development`
2. Verify team ID in project settings matches environment
3. Check bundle identifier matches exactly

**Issue**: "Team not found"
**Solution**:
1. Verify `DEVELOPMENT_TEAM` in .env file
2. Check Apple Developer Portal membership
3. Update Xcode account settings

#### Fastlane Issues

**Issue**: "Could not find project"
**Solution**:
1. Verify project name in Fastfile matches exactly
2. Check working directory
3. Ensure .xcodeproj exists

**Issue**: Match repository access denied
**Solution**:
1. Verify `MATCH_GIT_URL` is correct
2. Check `MATCH_GIT_BASIC_AUTHORIZATION` token permissions
3. Ensure repository exists and is private

#### GitHub Actions Issues

**Issue**: Workflow fails with "Command not found"
**Solution**:
1. Update workflow to install missing dependencies
2. Check macOS runner compatibility
3. Verify secret variables are set

### Getting Help

1. **Check Logs**: Always check Xcode build logs and Fastlane output
2. **GitHub Issues**: Create issue in this repository for template-related problems
3. **Documentation**: Refer to official documentation:
   - [Xcode Documentation](https://developer.apple.com/documentation/xcode)
   - [Fastlane Documentation](https://docs.fastlane.tools/)
   - [GitHub Actions Documentation](https://docs.github.com/en/actions)

## Best Practices

### Project Organization

**Recommended Folder Structure**:
```
YourApp/
├── YourApp/
│   ├── Application/
│   │   ├── AppDelegate.swift
│   │   └── SceneDelegate.swift
│   ├── Features/
│   │   ├── Authentication/
│   │   ├── UserProfile/
│   │   └── Settings/
│   ├── Core/
│   │   ├── Networking/
│   │   ├── Storage/
│   │   └── Extensions/
│   ├── Resources/
│   │   ├── Assets.xcassets
│   │   ├── Localizable.strings
│   │   └── Info.plist
│   └── Supporting Files/
├── YourAppTests/
└── YourAppUITests/
```

### Development Workflow

1. **Feature Branches**: Always work in feature branches
2. **Small Commits**: Make atomic commits with clear messages
3. **Code Review**: Require PR reviews for main branch
4. **Testing**: Write tests for new features
5. **Documentation**: Update documentation with changes

### Performance Optimization

**Build Settings**:
- Enable **Whole Module Optimization** for Release
- Set **Swift Compilation Mode** to **Whole Module** for Release
- Enable **Dead Code Stripping**
- Set **Strip Debug Symbols During Copy** for Release

**Code Practices**:
- Use lazy properties for expensive initialization
- Profile regularly with Instruments
- Optimize images and assets
- Use efficient data structures

### Security Considerations

1. **Never commit secrets** to version control
2. **Use Keychain** for sensitive data storage
3. **Enable App Transport Security**
4. **Validate all user inputs**
5. **Use code obfuscation** for sensitive algorithms

---

## Next Steps

After completing the setup:

1. **Customize the template** for your specific needs
2. **Add your app's features** and functionality
3. **Configure app metadata** for App Store
4. **Set up analytics and crash reporting**
5. **Plan your first release** using the deployment pipeline

**Happy coding!** 🚀

---

**Last Updated**: $(date)
**Setup Guide Version**: 1.0.0
**Compatible with**: Xcode 15.4+, iOS 15.0+, macOS 12.0+