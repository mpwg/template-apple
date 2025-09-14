# iOS/macOS App Template

A simple, clean template for building iOS, iPadOS, and macOS applications with Mac Catalyst support. This template includes GitHub Actions CI/CD, Fastlane automation, and Dependabot for dependency management.

## Features

- ✅ iOS/iPadOS app support
- ✅ macOS app support
- ✅ Mac Catalyst support (iOS app running on macOS)
- ✅ SwiftUI-based architecture
- ✅ GitHub Actions CI/CD pipeline
- ✅ Fastlane automation for builds and deployments
- ✅ Dependabot for automated dependency updates
- ✅ Xcode 15+ compatible
- ✅ Simple, readable code structure

## Quick Setup

### 1. Configure Your Project

Copy `.env.template` to `.env` and update with your project details:

```bash
cp .env.template .env
```

Then edit `.env`:

```bash
# Project Configuration
PROJECT_NAME=YourAppName
DISPLAY_NAME=Your App Name
PRODUCT_BUNDLE_IDENTIFIER=com.yourcompany.yourapp
ORGANIZATION_NAME=Your Company Name
ORGANIZATION_IDENTIFIER=com.yourcompany
COPYRIGHT=Copyright © 2024 Your Company Name. All rights reserved.

# Development Team (Apple Developer)
DEVELOPMENT_TEAM=ABCD123456

# App Store Connect API
APP_STORE_CONNECT_KEY_ID=ABC123DEF4
APP_STORE_CONNECT_ISSUER_ID=12345678-1234-1234-1234-123456789012

# Deployment Targets
IOS_DEPLOYMENT_TARGET=15.0
MACOS_DEPLOYMENT_TARGET=12.0
SWIFT_VERSION=5.0

# GitHub Repository
GITHUB_REPOSITORY_OWNER=yourusername
GITHUB_REPOSITORY_NAME=yourapp

# Fastlane Configuration
APPLE_ID=your-apple-id@example.com
FASTLANE_APP_IDENTIFIER=com.yourcompany.yourapp
FASTLANE_SCHEME=YourAppName

# Fastlane Match (Code Signing)
MATCH_GIT_URL=git@github.com:yourusername/yourapp-certificates.git
MATCH_PASSWORD=your_match_repository_passphrase
```

**Important**: Add `.env` to your `.gitignore` file to keep your secrets safe!

### 2. Rename Files and Folders

After updating the config, rename the following:
- `MyApp.xcodeproj` → `YourAppName.xcodeproj`
- `MyApp/` folder → `YourAppName/`
- Update project name in Xcode

### 3. Set up Fastlane Match for Code Signing

Create a private repository for your certificates:

```bash
# Create a new private repository (replace with your details)
gh repo create yourapp-certificates --private

# Initialize match (will create certificates repository)
fastlane match init
```

### 4. Configure GitHub Secrets and Variables

**Automated Setup (Recommended):**

After configuring your `.env` file, run the automated GitHub setup:

```bash
# Make sure you're authenticated with GitHub CLI
gh auth login

# Run the automated setup script
./github-setup.sh
```

This script will automatically:
- Import all non-sensitive variables as GitHub Variables
- Import sensitive data as GitHub Secrets
- Skip placeholder/template values
- Provide instructions for manual steps

**Manual Setup:**

Alternatively, set up manually in your GitHub repository (Settings → Secrets and Variables → Actions):

#### Required Secrets:
- `DEVELOPMENT_TEAM`: Your Apple Developer Team ID
- `APP_STORE_CONNECT_KEY_ID`: App Store Connect API Key ID
- `APP_STORE_CONNECT_ISSUER_ID`: App Store Connect Issuer ID
- `APP_STORE_CONNECT_PRIVATE_KEY`: App Store Connect API Private Key (the .p8 file content)
- `APPLE_ID`: Your Apple ID email
- `MATCH_PASSWORD`: Passphrase for your match certificates repository
- `MATCH_GIT_URL`: Git URL for your certificates repository

#### Variables (non-sensitive configuration):
- `PROJECT_NAME`: Your app name
- `PRODUCT_BUNDLE_IDENTIFIER`: Your bundle ID
- `IOS_DEPLOYMENT_TARGET`: Minimum iOS version
- `MACOS_DEPLOYMENT_TARGET`: Minimum macOS version
- `SWIFT_VERSION`: Swift language version
- `COPYRIGHT`: Copyright notice
- `ORGANIZATION_NAME`: Your organization name
- `FASTLANE_APP_IDENTIFIER`: App identifier for Fastlane
- `FASTLANE_SCHEME`: Xcode scheme name

### 5. Install Dependencies

```bash
# Install Ruby dependencies
bundle install

# Install Fastlane (if not using bundle)
gem install fastlane

# Initialize Fastlane (optional, already configured)
fastlane init
```

## Usage

### Development

```bash
# Sync certificates and profiles
fastlane ios certificates
fastlane mac certificates

# Build iOS app
fastlane ios build

# Build macOS app
fastlane mac build

# Run tests
fastlane ios test
fastlane mac test
```

### Deployment

```bash
# Deploy to TestFlight
fastlane ios beta
fastlane mac beta

# Deploy to App Store
fastlane ios release
fastlane mac release
```

### GitHub Actions

The template includes two workflows:

- **CI Pipeline** (`ci.yml`): Runs on every push/PR, builds all platforms and runs tests
- **Release Pipeline** (`release.yml`): Runs on version tags, builds and deploys to App Store

To trigger a release:
```bash
git tag v1.0.0
git push origin v1.0.0
```

## Project Structure

```
├── MyApp.xcodeproj/          # Xcode project
├── MyApp/
│   ├── Shared/               # Shared code (iOS/macOS)
│   │   ├── App.swift         # Main app entry point
│   │   ├── ContentView.swift # Main view
│   │   └── Assets.xcassets/  # Images and assets
│   ├── iOS/                  # iOS-specific code
│   └── macOS/                # macOS-specific code
│       └── MyApp.entitlements # macOS app entitlements
├── fastlane/
│   ├── Fastfile              # Fastlane automation
│   ├── Appfile               # App configuration
│   └── Matchfile             # Fastlane Match configuration
├── .github/
│   ├── workflows/
│   │   ├── ci.yml            # CI pipeline
│   │   └── release.yml       # Release pipeline
│   └── dependabot.yml        # Dependency updates
├── .env.template             # Template for environment variables
├── .env                      # Your environment variables (create from template)
├── setup.sh                  # Project setup automation
├── github-setup.sh           # GitHub secrets/variables automation
├── verify.sh                 # Template verification script
├── Gemfile                   # Ruby dependencies
├── .swiftlint.yml           # SwiftLint configuration
├── .gitignore               # Git ignore rules
└── LICENSE                   # MIT License
```

## Customization

### Adding Dependencies

For Swift Package Manager dependencies:
1. Open Xcode
2. Go to File → Add Package Dependencies
3. Add your package URL

For CocoaPods dependencies:
1. Create a `Podfile` in the root directory
2. Add your pods
3. Run `bundle exec pod install`

### Platform-Specific Code

- **Shared code**: Place in `MyApp/Shared/`
- **iOS-only code**: Place in `MyApp/iOS/`
- **macOS-only code**: Place in `MyApp/macOS/`

Use `#if os(iOS)` or `#if os(macOS)` for conditional compilation within shared files.

### Mac Catalyst Customization

The project is configured to support Mac Catalyst. To customize the Mac Catalyst experience:

1. Use `#if targetEnvironment(macCatalyst)` for Mac Catalyst-specific code
2. Configure Mac Catalyst settings in Xcode under target settings

## Troubleshooting

### Common Issues

1. **Build fails with signing errors**: Make sure `DEVELOPMENT_TEAM` is set correctly
2. **Fastlane authentication fails**: Verify App Store Connect API credentials
3. **GitHub Actions fail**: Check that all required secrets are set

### Getting Help

- Check the [GitHub Issues](https://github.com/yourusername/yourapp/issues) for common problems
- Review Apple's documentation for iOS/macOS development
- Consult Fastlane documentation for deployment issues

## License

This template is available under the MIT License. Replace this section with your app's license.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

---

**Note**: This template is designed to be simple and straightforward. For more complex needs, consider adding additional tools like SwiftLint, SwiftFormat, or custom build scripts.