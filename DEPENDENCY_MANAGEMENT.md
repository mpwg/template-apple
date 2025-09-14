# Dependency Management Guide

This guide explains how dependencies are managed in this iOS/macOS project, including automated updates through Dependabot, security practices, and manual maintenance procedures.

## Table of Contents

- [Overview](#overview)
- [Dependency Types](#dependency-types)
- [Automated Updates with Dependabot](#automated-updates-with-dependabot)
- [Manual Dependency Management](#manual-dependency-management)
- [Security Management](#security-management)
- [Update Process](#update-process)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)

## Overview

Our project uses multiple dependency management systems:
- **Swift Package Manager** for iOS/macOS dependencies
- **Bundler** for Ruby gems (Fastlane tooling)
- **GitHub Actions** for CI/CD workflow dependencies
- **CocoaPods** (if applicable)
- **Docker** for containerized tooling (if applicable)

### Automated vs Manual Updates

- **Automated (Dependabot)**: Patch and minor version updates
- **Manual Review Required**: Major version updates, breaking changes
- **Immediate**: Security updates (automatically prioritized)

## Dependency Types

### Swift Package Manager Dependencies

**Location**: `Package.swift` or Xcode project settings

**Categories**:
- **Core Libraries**: Networking, data storage, utilities
- **UI Components**: Custom UI libraries, layout helpers
- **Testing Frameworks**: Quick, Nimble, testing utilities
- **Development Tools**: SwiftLint, code generation tools

**Example Package.swift**:
```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MyApp",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.8.0"),
        .package(url: "https://github.com/Quick/Quick.git", from: "7.0.0"),
        .package(url: "https://github.com/Quick/Nimble.git", from: "12.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "MyApp",
            dependencies: ["Alamofire"]
        ),
        .testTarget(
            name: "MyAppTests",
            dependencies: ["MyApp", "Quick", "Nimble"]
        ),
    ]
)
```

### Ruby Gems (Fastlane Tooling)

**Location**: `Gemfile` and `Gemfile.lock`

**Key Dependencies**:
- **Fastlane**: Build automation and deployment
- **CocoaPods**: Dependency management (if used)
- **RuboCop**: Ruby code style checking
- **RSpec**: Testing framework for Ruby scripts

**Example Gemfile**:
```ruby
source "https://rubygems.org"

gem "fastlane", "~> 2.217"
gem "cocoapods", "~> 1.14"

group :development, :test do
  gem "rspec", "~> 3.12"
  gem "rubocop", "~> 1.57"
end

# Fastlane plugins
plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)
```

### GitHub Actions

**Location**: `.github/workflows/*.yml`

**Common Actions**:
- `actions/checkout`: Repository checkout
- `actions/setup-node`: Node.js setup
- `actions/cache`: Dependency caching
- `github/codeql-action`: Security analysis

### CocoaPods Dependencies (If Used)

**Location**: `Podfile` and `Podfile.lock`

**Note**: CocoaPods is not currently supported by Dependabot for automated updates. If you're using CocoaPods in your project, you'll need to manage updates manually or consider migrating to Swift Package Manager for better automation support.

**Manual Management Strategy**:
- Pin major versions to avoid breaking changes
- Regular manual updates for security patches
- Test thoroughly after updates
- Consider Swift Package Manager migration for better automation

## Automated Updates with Dependabot

### Configuration Overview

Dependabot is configured via `.github/dependabot.yml` to automatically:
- Check for dependency updates weekly
- Create pull requests for safe updates
- Group related updates together
- Prioritize security updates

### Update Schedule

| Ecosystem | Day | Time | Target Branch | Reviewers |
|-----------|-----|------|---------------|-----------|
| Swift Package Manager | Tuesday | 09:00 | `develop` | `maintainers-team` |
| Ruby Gems | Tuesday | 10:00 | `develop` | `devops-team` |
| GitHub Actions | Monday | 08:00 | `develop` | `devops-team` |
| Docker | Monday | 08:00 | `develop` | `infrastructure-team` |

**Note**: CocoaPods is not supported by Dependabot and requires manual dependency management.

### Automatic vs Manual Review

**Automatic Merge (with CI success)**:
- Patch updates (1.2.3 → 1.2.4)
- Security patches
- Minor updates for development dependencies

**Manual Review Required**:
- Major version updates (1.x.x → 2.x.x)
- Updates to critical production dependencies
- Breaking changes or API modifications

### Dependabot PR Labels

- `dependencies`: All dependency updates
- `automated`: Automatically created PRs
- `security`: Security-related updates
- `swift-package-manager`: SPM updates
- `ruby-gems`: Gem updates
- `github-actions`: Action updates

## Manual Dependency Management

### Adding New Dependencies

#### Swift Package Manager

**Via Xcode**:
1. Open project in Xcode
2. Go to **File** → **Add Package Dependencies**
3. Enter package URL and version requirements
4. Add to appropriate targets

**Via Package.swift**:
```swift
dependencies: [
    .package(url: "https://github.com/example/Package.git", from: "1.0.0")
]
```

#### Ruby Gems

**Add to Gemfile**:
```ruby
gem "new-gem", "~> 1.0"
```

**Install**:
```bash
bundle install
```

### Updating Dependencies

#### Swift Package Manager

```bash
# Update all packages
swift package update

# Update specific package
swift package update PackageName
```

#### Ruby Gems

```bash
# Update all gems
bundle update

# Update specific gem
bundle update gem-name

# Update Bundler itself
gem update bundler
```

#### CocoaPods

```bash
# Update all pods
pod update

# Update specific pod
pod update PodName

# Update CocoaPods itself
sudo gem install cocoapods
```

### Version Pinning Strategy

**Swift Package Manager**:
- Use `from: "1.0.0"` for stable APIs
- Use `exact: "1.2.3"` for critical dependencies
- Use `.upToNextMajor` for most dependencies

**Ruby Gems**:
- Use `~> 1.2.0` (pessimistic operator) for most gems
- Use `= 1.2.3` for exact versions when needed
- Keep Gemfile.lock in version control

## Security Management

### Security Update Process

1. **Immediate Notification**: GitHub sends security alerts
2. **Dependabot Response**: Automatically creates security update PRs
3. **Priority Review**: Security PRs get immediate attention
4. **Fast-Track Approval**: Streamlined review process for security fixes
5. **Rapid Deployment**: Deploy security fixes quickly

### Security Monitoring

**GitHub Features Enabled**:
- Dependency graph
- Dependabot alerts
- Dependabot security updates
- Secret scanning
- Code scanning

**Manual Security Checks**:
```bash
# Audit Ruby gems
bundle audit

# Check for outdated gems
bundle outdated

# Swift package security (using third-party tools)
swift package show-dependencies
```

### Vulnerability Response

**High Severity**:
1. Create hotfix branch immediately
2. Apply security update
3. Fast-track review and approval
4. Deploy to production ASAP
5. Update all environments

**Medium/Low Severity**:
1. Include in next regular update cycle
2. Standard review process
3. Deploy with next release

## Update Process

### Weekly Dependency Review

**Every Tuesday (Dependency Review Day)**:
1. Review Dependabot PRs from the week
2. Test critical dependency updates locally
3. Approve safe updates for auto-merge
4. Schedule manual testing for major updates
5. Update dependency documentation if needed

### Major Version Update Process

1. **Planning Phase**:
   - Review changelog and breaking changes
   - Assess impact on codebase
   - Plan testing strategy
   - Schedule update in sprint planning

2. **Development Phase**:
   - Create feature branch for update
   - Update dependency version
   - Fix breaking changes
   - Update related code
   - Add/update tests

3. **Testing Phase**:
   - Unit test validation
   - Integration test validation
   - UI test validation
   - Manual testing on devices
   - Performance testing

4. **Review Phase**:
   - Code review for all changes
   - Architecture review for major changes
   - Security review for external dependencies
   - Documentation updates

5. **Deployment Phase**:
   - Merge to develop branch
   - Deploy to staging environment
   - Monitor for issues
   - Deploy to production

### Rollback Procedure

If a dependency update causes issues:

1. **Immediate Response**:
   - Identify problematic dependency
   - Revert to previous version
   - Test stability

2. **Investigation**:
   - Analyze root cause
   - Check for configuration issues
   - Review update notes

3. **Resolution**:
   - Fix underlying issues
   - Test thoroughly
   - Re-apply update carefully

## Troubleshooting

### Common Issues

#### Dependency Conflicts

**Symptoms**:
- Build failures after updates
- Runtime crashes
- Unexpected behavior

**Solutions**:
```bash
# Clear Swift PM cache
rm -rf .build
swift package clean

# Reset CocoaPods
pod deintegrate
pod install

# Clear Ruby gem cache
bundle exec gem cleanup
```

#### Version Resolution Problems

**Swift Package Manager**:
```bash
# Check dependency graph
swift package show-dependencies

# Resolve specific version
swift package resolve
```

**CocoaPods**:
```bash
# Update repository
pod repo update

# Clean and reinstall
rm -rf Pods/
pod install
```

#### Dependabot PR Failures

**Common Causes**:
- CI/CD pipeline failures
- Merge conflicts
- Test failures
- Security policy violations

**Resolution Steps**:
1. Check CI/CD logs for errors
2. Resolve merge conflicts locally
3. Update tests if APIs changed
4. Request security team review if needed

### Getting Help

1. **Check Documentation**: Review dependency-specific docs
2. **Team Resources**: Ask in development chat
3. **GitHub Issues**: Create issue for persistent problems
4. **Vendor Support**: Contact dependency maintainers

## Best Practices

### General Guidelines

1. **Keep Dependencies Updated**: Regular updates prevent security issues
2. **Test Thoroughly**: Always test dependency updates
3. **Pin Critical Versions**: Pin versions for production-critical dependencies
4. **Monitor Security**: Stay alert for security vulnerabilities
5. **Document Changes**: Keep dependency changes documented

### Version Management

1. **Semantic Versioning**: Understand version number meanings
2. **Conservative Pinning**: Pin major versions for stability
3. **Regular Reviews**: Review dependencies quarterly
4. **Cleanup Unused**: Remove dependencies no longer needed

### Security Practices

1. **Immediate Updates**: Apply security updates immediately
2. **Audit Regularly**: Regular security audits of dependencies
3. **Source Verification**: Verify dependency sources and maintainers
4. **Access Control**: Limit who can add/update dependencies

### Team Coordination

1. **Communication**: Notify team of major dependency changes
2. **Review Process**: Require review for significant updates
3. **Testing**: Shared responsibility for testing updates
4. **Documentation**: Keep team informed of dependency decisions

## Automation Scripts

### Dependency Health Check

Create a script to check dependency health:

**`scripts/check-dependencies.sh`:**
```bash
#!/bin/bash

echo "🔍 Checking dependency health..."

# Swift Package Manager
echo "📦 Swift Package Manager dependencies:"
swift package show-dependencies

# Ruby Gems
echo "💎 Ruby Gem dependencies:"
bundle outdated

# Security audit
echo "🔒 Security audit:"
bundle audit

echo "✅ Dependency health check completed!"
```

### Update All Dependencies

**`scripts/update-all-dependencies.sh`:**
```bash
#!/bin/bash

echo "🚀 Updating all dependencies..."

# Swift packages
echo "📦 Updating Swift packages..."
swift package update

# Ruby gems
echo "💎 Updating Ruby gems..."
bundle update

# CocoaPods (if applicable)
if [ -f "Podfile" ]; then
    echo "🥥 Updating CocoaPods..."
    pod update
fi

echo "✅ All dependencies updated!"
```

---

**Last Updated**: $(date)
**Document Version**: 1.0.0
**Next Review**: Monthly

For questions or suggestions about dependency management, please create a GitHub issue or contact the development team.