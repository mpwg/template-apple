# Contributing Guidelines

Welcome to our iOS/macOS project! This document provides guidelines for contributing to the project and ensures a smooth collaboration process for all team members.

## Table of Contents

- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Branch Strategy](#branch-strategy)
- [Code Standards](#code-standards)
- [Pull Request Process](#pull-request-process)
- [Testing Requirements](#testing-requirements)
- [Code Review Guidelines](#code-review-guidelines)
- [Release Process](#release-process)
- [Issue Management](#issue-management)

## Getting Started

### Prerequisites

Before contributing, ensure you have:
- Xcode 15.4+ installed
- Apple Developer account with team access
- GitHub CLI (`gh`) installed
- Ruby 3.2+ and Bundler installed
- Git configured with your name and email

### First-Time Setup

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd <project-name>
   ```

2. **Set up environment:**
   ```bash
   cp .env.template .env
   # Edit .env with your configuration
   ```

3. **Install dependencies:**
   ```bash
   bundle install
   gem install fastlane
   ```

4. **Verify setup:**
   ```bash
   bundle exec fastlane --version
   ./scripts/setup-secrets.sh --validate
   ```

## Development Setup

### Environment Configuration

Follow the [Environment Setup Guide](ENVIRONMENT_SETUP.md) for detailed instructions on:
- Configuring environment variables
- Setting up Apple Developer credentials
- Configuring Fastlane Match
- GitHub secrets management

### Project Structure

```
├── .env.template           # Environment template
├── BRANCH_STRATEGY.md      # Git workflow documentation
├── CONTRIBUTING.md         # This file
├── ENVIRONMENT_SETUP.md    # Environment setup guide
├── fastlane/              # Fastlane configuration
├── scripts/               # Helper scripts
├── .github/               # GitHub Actions workflows
└── README.md              # Project overview
```

## Branch Strategy

We follow a **Git Flow hybrid approach**. Please read the complete [Branch Strategy Guide](BRANCH_STRATEGY.md) for detailed information.

### Quick Reference

**Branch Types:**
- `main` - Production-ready code
- `develop` - Integration branch
- `feature/*` - Feature development
- `release/*` - Release preparation
- `hotfix/*` - Critical fixes

**Starting New Work:**
```bash
# Feature development
git checkout develop
git pull origin develop
git checkout -b feature/your-feature-name

# Bug fixes
git checkout develop
git pull origin develop
git checkout -b feature/fix-issue-description

# Emergency hotfix
git checkout main
git pull origin main
git checkout -b hotfix/critical-fix
```

## Code Standards

### Swift Code Style

We use **SwiftLint** to enforce consistent code style. Configuration is in `.swiftlint.yml`.

**Key Standards:**
- Use spaces, not tabs (4 spaces per indent level)
- Maximum line length: 120 characters
- Use descriptive variable and function names
- Follow Apple's Swift API Design Guidelines
- Prefer `let` over `var` when possible
- Use meaningful comments for complex logic

### Commit Message Format

Follow [Conventional Commits](https://www.conventionalcommits.org/) specification:

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code formatting
- `refactor`: Code restructuring
- `perf`: Performance improvements
- `test`: Testing changes
- `chore`: Maintenance tasks
- `build`: Build system changes
- `ci`: CI/CD changes

**Examples:**
```bash
feat: add biometric authentication support
fix: resolve memory leak in image cache
docs: update API documentation
style: apply SwiftLint formatting rules
refactor: extract networking into separate module
test: add unit tests for payment processing
chore: update CocoaPods dependencies
ci: add automated security scanning
```

### Code Organization

**File Structure:**
- Group related files in folders
- Use meaningful file names
- Separate UI, business logic, and data layers
- Keep files focused on single responsibility

**Swift Code Organization:**
```swift
// MARK: - Imports
import UIKit
import Foundation

// MARK: - Class Definition
class MyViewController: UIViewController {

    // MARK: - Properties
    private let myProperty: String

    // MARK: - Initialization
    init(property: String) {
        self.myProperty = property
        super.init(nibName: nil, bundle: nil)
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    // MARK: - Setup
    private func setupUI() {
        // UI setup code
    }

    // MARK: - Actions
    @IBAction private func buttonTapped(_ sender: UIButton) {
        // Action handling
    }
}

// MARK: - Extensions
extension MyViewController: UITableViewDataSource {
    // Protocol conformance
}
```

### Documentation

**Code Comments:**
- Use `///` for public API documentation
- Explain complex algorithms or business logic
- Avoid obvious comments
- Keep comments up-to-date with code changes

**API Documentation:**
```swift
/// Authenticates user with biometric authentication
/// - Parameters:
///   - reason: The reason displayed to the user
///   - completion: Called with authentication result
/// - Returns: True if authentication is available, false otherwise
func authenticateUser(reason: String, completion: @escaping (Bool) -> Void) -> Bool {
    // Implementation
}
```

## Pull Request Process

### Before Creating a Pull Request

1. **Ensure your branch is up-to-date:**
   ```bash
   git checkout feature/my-feature
   git merge develop  # or rebase if preferred
   ```

2. **Run local checks:**
   ```bash
   # SwiftLint
   swiftlint

   # Build project
   xcodebuild -workspace MyApp.xcworkspace -scheme MyApp -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 15' build

   # Run tests
   xcodebuild test -workspace MyApp.xcworkspace -scheme MyApp -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 15'
   ```

3. **Self-review your changes:**
   - Check for debugging code or console logs
   - Verify all files are properly saved
   - Review commit messages for clarity

### Creating the Pull Request

1. **Push your branch:**
   ```bash
   git push -u origin feature/my-feature
   ```

2. **Create PR using GitHub CLI:**
   ```bash
   gh pr create --title "Add biometric authentication" --body-file pr-template.md
   ```

3. **Use the PR template:**
   ```markdown
   ## Description
   Brief description of what this PR accomplishes.

   ## Type of Change
   - [ ] Bug fix (non-breaking change which fixes an issue)
   - [ ] New feature (non-breaking change which adds functionality)
   - [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
   - [ ] Documentation update

   ## Testing
   - [ ] Unit tests pass
   - [ ] UI tests pass (if applicable)
   - [ ] Manual testing completed
   - [ ] Tested on physical device
   - [ ] No console warnings or errors

   ## Screenshots/Videos
   (Include screenshots for UI changes)

   ## Checklist
   - [ ] My code follows the style guidelines
   - [ ] I have performed a self-review
   - [ ] I have commented my code, particularly hard-to-understand areas
   - [ ] My changes generate no new warnings
   - [ ] I have updated documentation if needed

   ## Related Issues
   Closes #123
   ```

### Pull Request Requirements

**All Pull Requests Must:**
- Have a clear, descriptive title
- Include detailed description of changes
- Pass all CI/CD checks
- Have at least one approving review
- Be up-to-date with target branch
- Follow commit message conventions

**Large Pull Requests Should:**
- Be broken into smaller, focused PRs when possible
- Include additional context and testing details
- Have multiple reviewers
- Include performance impact analysis if applicable

## Testing Requirements

### Unit Tests
- Write unit tests for all new business logic
- Maintain or improve code coverage
- Use descriptive test names that explain what is being tested
- Follow Given-When-Then pattern for test structure

```swift
func test_authenticateUser_whenBiometricsAvailable_returnsTrue() {
    // Given
    let authService = BiometricAuthService()
    biometricService.mockIsAvailable = true

    // When
    let result = authService.isAuthenticationAvailable()

    // Then
    XCTAssertTrue(result)
}
```

### UI Tests
- Write UI tests for critical user flows
- Test on different device sizes and orientations
- Include accessibility testing
- Use page objects pattern for maintainable tests

### Manual Testing
- Test on physical devices when possible
- Verify functionality across different iOS versions
- Check performance and memory usage
- Test edge cases and error scenarios

## Code Review Guidelines

### For Authors

**Before Requesting Review:**
- Self-review all changes
- Ensure PR description is complete
- Verify all tests pass
- Check that CI/CD builds successfully

**During Review:**
- Respond to all comments promptly
- Ask clarifying questions if feedback is unclear
- Make requested changes or explain why you disagree
- Re-request review after making changes

### For Reviewers

**What to Look For:**
- Code correctness and functionality
- Adherence to coding standards
- Potential security issues
- Performance considerations
- Test coverage and quality
- Documentation updates

**How to Review:**
- Be constructive and specific in feedback
- Suggest improvements rather than just pointing out problems
- Consider the overall architecture and design
- Test the changes locally for complex features
- Approve when satisfied with the changes

**Review Checklist:**
- [ ] Code follows project conventions
- [ ] Logic is correct and handles edge cases
- [ ] No security vulnerabilities introduced
- [ ] Performance impact is acceptable
- [ ] Tests adequately cover new functionality
- [ ] Documentation is updated if needed
- [ ] No debugging code or console logs left behind

## Release Process

### Release Planning
1. **Feature Freeze**: Stop merging new features to `develop`
2. **Create Release Branch**: `release/X.Y.Z` from `develop`
3. **Testing Phase**: QA testing and bug fixes
4. **Version Finalization**: Update version numbers and changelog

### Release Execution
1. **Merge to Main**: Create PR from release branch to `main`
2. **Tag Release**: Create Git tag after merge
3. **Deploy**: Use Fastlane to deploy to App Store
4. **Backport**: Merge release branch to `develop`

### Post-Release
1. **Monitor**: Watch for crash reports or issues
2. **Document**: Update release notes and changelog
3. **Plan Next**: Begin planning next release cycle

## Issue Management

### Creating Issues

**Use Issue Templates:**
- Bug reports
- Feature requests
- Documentation updates
- Performance improvements

**Include Required Information:**
- Clear, descriptive title
- Detailed description
- Steps to reproduce (for bugs)
- Expected vs. actual behavior
- Screenshots or videos
- Device/iOS version information
- Labels for categorization

### Issue Labels

**Type Labels:**
- `bug` - Something isn't working
- `enhancement` - New feature or improvement
- `documentation` - Documentation updates
- `question` - Questions about the project

**Priority Labels:**
- `priority:high` - Needs immediate attention
- `priority:medium` - Should be addressed soon
- `priority:low` - Nice to have

**Status Labels:**
- `status:in-progress` - Currently being worked on
- `status:blocked` - Waiting for external dependency
- `status:needs-review` - Needs design or technical review

### Working on Issues

1. **Assign yourself** to the issue before starting work
2. **Create feature branch** referencing the issue number
3. **Update issue** with progress and blockers
4. **Link pull request** to issue using "Closes #123"

## Getting Help

### Resources

1. **Documentation**:
   - [Branch Strategy Guide](BRANCH_STRATEGY.md)
   - [Environment Setup](ENVIRONMENT_SETUP.md)
   - [README](README.md)

2. **Tools**:
   - [Fastlane Documentation](https://docs.fastlane.tools/)
   - [SwiftLint Rules](https://realm.github.io/SwiftLint/)
   - [Conventional Commits](https://www.conventionalcommits.org/)

3. **Community**:
   - Team chat/Slack for quick questions
   - GitHub Discussions for longer conversations
   - Issues for bugs and feature requests

### Common Questions

**Q: How do I update my fork?**
```bash
git checkout develop
git fetch upstream
git merge upstream/develop
git push origin develop
```

**Q: My PR has merge conflicts. How do I fix them?**
```bash
git checkout feature/my-feature
git merge develop
# Resolve conflicts in Xcode
git add .
git commit -m "resolve: merge conflicts with develop"
git push origin feature/my-feature
```

**Q: Can I work on multiple features at once?**
Yes, but create separate branches for each feature to keep changes isolated.

**Q: When should I create a draft PR?**
Create draft PRs for:
- Work in progress that needs early feedback
- Large features being developed over time
- Experimental changes that need discussion

## Recognition

We appreciate all contributions to the project! Contributors are recognized through:
- GitHub contributor statistics
- Release notes acknowledgments
- Team recognition in meetings
- Special thanks in README

Thank you for contributing to our project! 🎉

---

**Need Help?** If you have questions about contributing, please:
1. Check this documentation first
2. Search existing issues and discussions
3. Ask in team chat for quick questions
4. Create a GitHub issue for specific problems

**Feedback on Guidelines?** These guidelines should evolve with the project. Submit PRs to improve this documentation or create issues with suggestions.