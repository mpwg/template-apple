# iOS/macOS Template Repository

A comprehensive template repository for iOS and macOS development with modern best practices, automated workflows, and professional tooling.

## 🚀 Features

- **Modern iOS/macOS Development**: Target iOS 26+, macOS 26+ with Xcode 26
- **Automated CI/CD**: GitHub Actions workflow for building, testing, and deployment
- **Code Signing**: Fastlane Match for automated certificate and provisioning profile management
- **Dependency Management**: Dependabot for automated dependency updates
- **Professional Structure**: Well-organized project structure following best practices
- **Template Ready**: Configured as a GitHub template repository for easy project creation

## 📋 Prerequisites

- **Xcode 26** or later
- **iOS 26** or later (for iOS targets)
- **macOS 26** or later (for macOS targets)
- **Ruby** (for Fastlane)
- **Bundler** (for Ruby gem management)
- **Git** (for version control)
- **GitHub CLI** (optional, for enhanced GitHub integration)

## 🏁 Quick Start

### 1. Use This Template

Click the "Use this template" button at the top of this repository or visit:
```
https://github.com/your-org/template/generate
```

### 2. Clone Your New Repository

```bash
git clone https://github.com/your-org/your-new-project.git
cd your-new-project
```

### 3. Setup Environment

```bash
# Copy environment template
cp .env.template .env

# Edit .env with your actual values
nano .env

# Install dependencies
bundle install
```

### 4. Create Xcode Project

**Important**: This template does not include an Xcode project file. Create your Xcode project:

1. Open Xcode 26
2. Create a new project in the repository root
3. Choose your desired template (iOS App, macOS App, etc.)
4. Configure your project settings:
   - **Product Name**: Your app name
   - **Bundle Identifier**: com.yourorg.yourapp
   - **Language**: Swift
   - **Use Core Data**: As needed
   - **Include Tests**: Recommended

### 5. Configure Code Signing

```bash
# Initialize Fastlane Match
bundle exec fastlane match init

# Generate certificates and profiles
bundle exec fastlane match development
bundle exec fastlane match appstore
```

## 🛠 Setup Instructions

### Environment Configuration

1. **Copy Environment Template**:
   ```bash
   cp .env.template .env
   ```

2. **Configure Apple Developer Account**:
   ```env
   APPLE_ID=your-apple-id@example.com
   DEVELOPMENT_TEAM=YOUR_DEVELOPMENT_TEAM_ID
   APPSTORE_TEAM_ID=YOUR_APPSTORE_TEAM_ID
   ```

3. **Setup App Store Connect API** (Recommended):
   ```env
   APP_STORE_CONNECT_API_KEY_KEY_ID=your_api_key_id
   APP_STORE_CONNECT_API_KEY_ISSUER_ID=your_issuer_id
   APP_STORE_CONNECT_API_KEY_CONTENT="-----BEGIN PRIVATE KEY-----\nYOUR_KEY\n-----END PRIVATE KEY-----"
   ```

4. **Configure Code Signing**:
   ```env
   MATCH_PASSWORD=your_match_repository_password
   MATCH_GIT_URL=https://github.com/your-org/certificates-repo.git
   MATCH_GIT_BASIC_AUTHORIZATION=your_git_basic_auth_token
   ```

5. **Setup GitHub Secrets**:
   ```bash
   # Push all environment variables to GitHub secrets
   gh secret set -f .env
   ```

### Fastlane Setup

1. **Install Fastlane**:
   ```bash
   bundle install
   ```

2. **Initialize Match** (if not done during quick start):
   ```bash
   bundle exec fastlane match init
   ```

3. **Generate Certificates**:
   ```bash
   bundle exec fastlane match development
   bundle exec fastlane match appstore
   ```

## 📁 Project Structure

```
├── .github/
│   ├── workflows/          # GitHub Actions workflows
│   └── ISSUE_TEMPLATE/     # Issue templates
├── fastlane/              # Fastlane configuration
├── .env.template          # Environment variables template
├── .gitignore            # Git ignore rules
├── Gemfile               # Ruby dependencies
├── README.md             # This file
├── LICENSE.md            # MIT License
└── [Your Xcode Project]  # Create your Xcode project here
```

## 🔄 Branch Strategy

This template follows the **GitHub Flow** branching strategy:

- **`main`**: Production-ready code, protected branch
- **Feature branches**: `feature/description` or `feat/description`
- **Bug fixes**: `fix/description` or `bugfix/description`
- **Releases**: Tagged from `main` branch

### Workflow:
1. Create feature branch from `main`
2. Develop and test changes
3. Create Pull Request to `main`
4. Code review and approval
5. Merge to `main`
6. Tag releases as needed

## 🤖 GitHub Actions

The template includes automated workflows for:

- **Build & Test**: Runs on every PR and push to main
- **Release**: Automated App Store deployment
- **Dependencies**: Dependabot for automated updates

## 🔐 Code Signing

Code signing is handled through **Fastlane Match**:

- Certificates stored in private Git repository
- Automatic provisioning profile management
- Supports development and distribution profiles
- Encrypted storage with team sharing

## ⚙ Configuration Checklist

After creating your project from this template:

- [ ] Update `README.md` with your project details
- [ ] Configure `.env` file with your credentials
- [ ] Create Xcode project in repository root
- [ ] Setup Fastlane Match repository
- [ ] Configure GitHub repository secrets
- [ ] Update `Gemfile` if needed
- [ ] Customize GitHub Actions workflows
- [ ] Add your app's specific dependencies
- [ ] Update bundle identifier and app name
- [ ] Configure App Store Connect

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines

- Follow Swift style guidelines
- Write unit tests for new features
- Update documentation for any API changes
- Ensure CI passes before requesting review

## 🆘 Troubleshooting

### Common Issues

**Xcode Build Issues**:
- Verify iOS/macOS deployment targets match prerequisites
- Check bundle identifier configuration
- Ensure certificates are valid and not expired

**Fastlane Match Issues**:
- Verify Match repository access and credentials
- Check `MATCH_PASSWORD` is correct
- Ensure development team ID matches certificates

**GitHub Actions Failures**:
- Verify all required secrets are configured
- Check Xcode version in workflow matches local version
- Ensure repository has correct permissions

**Environment Setup**:
- Verify `.env` file is properly configured
- Check Apple ID has required permissions
- Ensure API keys are valid and not expired

### Getting Help

- **Issues**: Create an issue in this repository
- **Discussions**: Use GitHub Discussions for questions
- **Documentation**: Check Apple Developer documentation
- **Community**: iOS/macOS development communities

## 📄 License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.

## 🏷 Topics

`ios` `macos` `template` `fastlane` `github-actions` `xcode` `swift` `mobile` `automation` `ci-cd`

---

**Happy Coding! 🎉**

Made with ❤️ for the iOS/macOS development community.