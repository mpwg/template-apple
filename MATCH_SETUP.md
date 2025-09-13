# Fastlane Match Setup Guide

This comprehensive guide will walk you through setting up Fastlane Match for secure, centralized code signing certificate and provisioning profile management.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Initial Setup](#initial-setup)
- [Team Member Setup](#team-member-setup)
- [CI/CD Integration](#ci-cd-integration)
- [Certificate Management](#certificate-management)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)

## Overview

Fastlane Match creates and maintains your iOS/macOS certificates and provisioning profiles for you. It stores them in a Git repository, encrypted with a passphrase, ensuring all team members have access to the same certificates.

### Benefits of Match

- **Centralized Management**: One source of truth for all certificates
- **Team Collaboration**: All team members use the same certificates
- **Automated Setup**: New team members can get set up quickly
- **Version Control**: Track changes to certificates and profiles
- **Security**: Certificates are encrypted and stored securely

## Prerequisites

### Required Tools

- **Xcode 15.4+** with Command Line Tools
- **Ruby 3.2+** with Bundler
- **Fastlane 2.217+**
- **Git 2.30+**
- **Apple Developer Account** with appropriate permissions

### Apple Developer Account Requirements

Your Apple ID must have the following permissions:

1. **Admin** or **App Manager** role in App Store Connect
2. **Admin** or **Developer** role in Apple Developer Program
3. **Certificates, Identifiers & Profiles** access
4. Access to the Team ID you'll be signing with

### Environment Setup

Ensure your environment is configured:

```bash
# Verify installations
xcode-select --version
ruby --version
bundle --version
fastlane --version
git --version

# Install dependencies
bundle install
```

## Initial Setup

### Step 1: Create Certificates Repository

1. **Create a new private Git repository** for storing certificates:
   - GitHub: `https://github.com/your-org/ios-certificates`
   - GitLab: `https://gitlab.com/your-org/ios-certificates`
   - Bitbucket: `https://bitbucket.org/your-org/ios-certificates`

2. **Initialize as empty repository** (no README, .gitignore, license)

3. **Keep the repository URL** - you'll need it for configuration

### Step 2: Generate Personal Access Token

For private repositories, create a Personal Access Token:

#### GitHub:
1. Go to **Settings** → **Developer settings** → **Personal access tokens** → **Tokens (classic)**
2. Click **Generate new token (classic)**
3. Select scopes: `repo` (full repository access)
4. Generate and **securely save** the token

#### GitLab:
1. Go to **User Settings** → **Access Tokens**
2. Create token with `api`, `read_repository`, `write_repository` scopes

#### Bitbucket:
1. Go to **Settings** → **App passwords**
2. Create password with `Repositories: Read, Write` permissions

### Step 3: Configure Environment Variables

Edit your `.env` file with the required values:

```bash
# Copy template if not done already
cp .env.template .env

# Edit with your actual values
vim .env
```

**Required Variables:**

```bash
# Apple Developer Account
APPLE_ID=your-apple-id@example.com
DEVELOPMENT_TEAM=YOUR_DEVELOPMENT_TEAM_ID
APPSTORE_TEAM_ID=YOUR_APPSTORE_TEAM_ID

# App Bundle Identifiers
IOS_BUNDLE_ID=com.yourcompany.yourapp
MACOS_BUNDLE_ID=com.yourcompany.yourapp.macos

# Match Configuration
MATCH_GIT_URL=https://github.com/your-org/ios-certificates.git
MATCH_PASSWORD=your_very_secure_password_here
MATCH_GIT_BASIC_AUTHORIZATION=your_personal_access_token

# Keychain Configuration (for CI/CD)
KEYCHAIN_PASSWORD=your_ci_keychain_password
MATCH_KEYCHAIN_NAME=fastlane_tmp_keychain
```

**Important Security Notes:**

- **MATCH_PASSWORD**: Use a strong, unique password (32+ characters)
- **Never commit** the `.env` file to version control
- **Store secrets securely** using a password manager
- **Share MATCH_PASSWORD** with team members through secure channels only

### Step 4: Initialize Match

Run the initialization command:

```bash
bundle exec fastlane match init
```

This will:
- Create the basic Match configuration
- Set up the certificates repository
- Prepare for certificate generation

### Step 5: Generate Certificates

Generate certificates for development and distribution:

```bash
# Generate development certificates
bundle exec fastlane match development

# Generate App Store distribution certificates
bundle exec fastlane match appstore

# Generate Ad Hoc certificates (if needed)
bundle exec fastlane match adhoc
```

**What happens during certificate generation:**
1. Match checks Apple Developer Portal for existing certificates
2. Creates new certificates if needed
3. Downloads and encrypts certificates
4. Commits encrypted certificates to your Git repository
5. Installs certificates in your local keychain

### Step 6: Verify Setup

Test that certificates are working:

```bash
# List certificates in keychain
security find-identity -v -p codesigning

# Test build with certificates
xcodebuild build \
  -project YourApp.xcodeproj \
  -scheme YourApp \
  -configuration Debug
```

## Team Member Setup

### For New Team Members

1. **Share credentials securely:**
   - MATCH_PASSWORD (through secure channel)
   - Access to certificates repository
   - Apple Developer Team access

2. **Set up environment:**
   ```bash
   # Clone the main repository
   git clone https://github.com/your-org/your-app.git
   cd your-app

   # Set up environment variables
   cp .env.template .env
   # Edit .env with shared credentials

   # Install dependencies
   bundle install
   ```

3. **Install certificates (readonly):**
   ```bash
   # Install development certificates
   bundle exec fastlane match development --readonly

   # Install App Store certificates
   bundle exec fastlane match appstore --readonly
   ```

4. **Verify setup:**
   ```bash
   # Check certificates are installed
   security find-identity -v -p codesigning

   # Test build
   xcodebuild build -project YourApp.xcodeproj -scheme YourApp
   ```

### Team Member Onboarding Script

Create `scripts/onboard-developer.sh`:

```bash
#!/bin/bash

echo "🚀 Developer Onboarding Script"
echo "==============================="

# Check prerequisites
if ! command -v bundle &> /dev/null; then
    echo "❌ Bundler not found. Install with: gem install bundler"
    exit 1
fi

if ! command -v fastlane &> /dev/null; then
    echo "❌ Fastlane not found. Install with: gem install fastlane"
    exit 1
fi

# Install dependencies
echo "📦 Installing dependencies..."
bundle install

# Validate environment
echo "🔍 Validating environment..."
if [ ! -f ".env" ]; then
    echo "❌ .env file not found. Please copy from .env.template and configure."
    exit 1
fi

# Install certificates
echo "📜 Installing development certificates..."
bundle exec fastlane match development --readonly

echo "📜 Installing App Store certificates..."
bundle exec fastlane match appstore --readonly

# Verify setup
echo "✅ Verifying certificate installation..."
security find-identity -v -p codesigning

echo ""
echo "🎉 Setup completed successfully!"
echo "You can now build and sign iOS/macOS applications."
```

## CI/CD Integration

### GitHub Actions Setup

The certificates are automatically configured in the CI/CD workflow. Ensure your GitHub repository secrets are set:

```bash
# Upload all secrets from .env file
gh secret set -f .env

# Or set individually
gh secret set MATCH_PASSWORD --body "your_password"
gh secret set MATCH_GIT_URL --body "https://github.com/org/certs.git"
gh secret set MATCH_GIT_BASIC_AUTHORIZATION --body "your_token"
```

### CI/CD Best Practices

1. **Use readonly mode** in CI:
   ```yaml
   - name: Install certificates
     run: bundle exec fastlane match appstore --readonly
   ```

2. **Set up temporary keychain**:
   ```yaml
   - name: Create keychain
     run: |
       security create-keychain -p "$KEYCHAIN_PASSWORD" build.keychain
       security default-keychain -s build.keychain
       security unlock-keychain -p "$KEYCHAIN_PASSWORD" build.keychain
   ```

3. **Clean up after build**:
   ```yaml
   - name: Clean up keychain
     if: always()
     run: security delete-keychain build.keychain
   ```

## Certificate Management

### Certificate Types and Usage

| Type | Usage | Command | When to Use |
|------|-------|---------|-------------|
| **Development** | Local development, debugging | `fastlane match development` | Daily development work |
| **App Store** | App Store releases | `fastlane match appstore` | Production releases |
| **Ad Hoc** | Distribution to specific devices | `fastlane match adhoc` | Beta testing, QA |
| **Enterprise** | Enterprise distribution | `fastlane match enterprise` | Internal company apps |

### Renewing Certificates

Match automatically handles certificate renewal, but you can force renewal:

```bash
# Force renewal of development certificates
bundle exec fastlane match development --force

# Force renewal for new devices (provisioning profiles)
bundle exec fastlane match development --force_for_new_devices

# Renew all certificate types
bundle exec fastlane match development --force
bundle exec fastlane match appstore --force
```

### Certificate Validation Script

Create `scripts/validate-certificates.sh`:

```bash
#!/bin/bash

echo "🔍 Certificate Validation Report"
echo "================================="

# Check certificate expiry
echo ""
echo "📜 Certificate Expiry Status:"
security find-identity -v -p codesigning | while read line; do
    if [[ $line == *")"* ]]; then
        cert_name=$(echo "$line" | sed 's/.*) "//' | sed 's/".*//')
        echo "Certificate: $cert_name"

        # Get certificate details
        cert_sha=$(echo "$line" | awk '{print $2}')
        expiry=$(security find-certificate -c "$cert_name" -p | openssl x509 -noout -enddate | cut -d= -f2)
        echo "  Expires: $expiry"
        echo ""
    fi
done

echo "🔍 Provisioning Profile Status:"
find ~/Library/MobileDevice/Provisioning\ Profiles -name "*.mobileprovision" -exec echo {} \; -exec security cms -D -i {} \; | grep -A1 "Name\|ExpirationDate" || echo "No provisioning profiles found"

echo ""
echo "✅ Validation completed!"
```

### Automated Certificate Monitoring

Set up monitoring for certificate expiry:

```bash
# Add to crontab for weekly checks
0 9 * * 1 /path/to/your/project/scripts/validate-certificates.sh
```

## Troubleshooting

### Common Issues and Solutions

#### 1. "No matching certificates found"

**Symptoms:**
- Build fails with code signing errors
- Xcode can't find certificates

**Solutions:**
```bash
# Re-install certificates
bundle exec fastlane match development --force

# Check keychain
security list-keychains
security find-identity -v -p codesigning

# Verify Match configuration
bundle exec fastlane match development --readonly --verbose
```

#### 2. "Repository access denied"

**Symptoms:**
- Can't clone certificates repository
- Authentication failures

**Solutions:**
```bash
# Verify repository access
git clone $MATCH_GIT_URL test-repo
rm -rf test-repo

# Check Personal Access Token permissions
# Regenerate token if needed

# Test with curl (GitHub)
curl -H "Authorization: token $MATCH_GIT_BASIC_AUTHORIZATION" https://api.github.com/user
```

#### 3. "Certificate already exists"

**Symptoms:**
- Match can't create new certificates
- Duplicate certificate errors

**Solutions:**
```bash
# List existing certificates in Apple Developer Portal
bundle exec fastlane match development --readonly --verbose

# Force certificate renewal
bundle exec fastlane match development --force

# Or revoke and recreate
# (Use with caution - affects all team members)
```

#### 4. "Provisioning profile doesn't match"

**Symptoms:**
- App won't install on device
- Code signing identity mismatch

**Solutions:**
```bash
# Force provisioning profile update
bundle exec fastlane match development --force_for_new_devices

# Check bundle identifier matches
echo "Bundle ID in .env: $IOS_BUNDLE_ID"
# Compare with Xcode project settings

# Regenerate profiles
bundle exec fastlane match development --force
```

#### 5. "Keychain access denied"

**Symptoms:**
- Can't access certificates in keychain
- Permission denied errors

**Solutions:**
```bash
# Unlock keychain
security unlock-keychain -p "$KEYCHAIN_PASSWORD" login.keychain

# Fix keychain permissions
security set-keychain-settings -t 3600 -l login.keychain

# Re-install certificates
bundle exec fastlane match development --readonly
```

### Debugging Commands

```bash
# Verbose Match output
bundle exec fastlane match development --readonly --verbose

# Check environment variables
env | grep MATCH
env | grep APPLE
env | grep DEVELOPMENT

# List keychains
security list-keychains

# Export certificate (for debugging)
security find-identity -v -p codesigning
security export-certificate -i "certificate_name"

# Check git repository access
git ls-remote $MATCH_GIT_URL
```

## Best Practices

### Security Best Practices

1. **Strong Passwords**
   - Use 32+ character passwords for MATCH_PASSWORD
   - Include uppercase, lowercase, numbers, and symbols
   - Store in secure password manager

2. **Access Control**
   - Keep certificates repository private
   - Limit repository access to team members only
   - Use Personal Access Tokens with minimal required permissions
   - Regularly audit repository access

3. **Credential Management**
   - Never commit `.env` file to version control
   - Use environment variables in CI/CD
   - Rotate Personal Access Tokens regularly
   - Share MATCH_PASSWORD through secure channels only

4. **Certificate Security**
   - Enable two-factor authentication on Apple ID
   - Use dedicated Apple ID for CI/CD if possible
   - Monitor certificate usage and expiry
   - Revoke compromised certificates immediately

### Team Collaboration

1. **Onboarding**
   - Provide clear setup instructions
   - Use onboarding scripts for consistency
   - Verify new team member setup
   - Document any custom configurations

2. **Communication**
   - Notify team before certificate renewal
   - Share certificate repository changes
   - Maintain team access to credentials
   - Document troubleshooting solutions

3. **Maintenance**
   - Regular certificate expiry monitoring
   - Automated renewal where possible
   - Keep Match configuration updated
   - Review and update documentation

### Performance Optimization

1. **Repository Management**
   - Use shallow clones in CI: `shallow_clone: true`
   - Clean up old certificate versions periodically
   - Optimize git repository size
   - Use specific branches for different environments

2. **Build Performance**
   - Cache certificates in CI/CD
   - Use readonly mode when possible
   - Skip confirmation prompts: `skip_confirmation: true`
   - Parallel certificate installation

### Monitoring and Alerting

1. **Certificate Expiry**
   - Set up alerts 30 days before expiry
   - Monitor provisioning profile expiry
   - Track certificate usage
   - Automated renewal reminders

2. **Repository Health**
   - Monitor repository access and changes
   - Track Match operation success/failure
   - Log certificate installation issues
   - Alert on authentication failures

---

## Additional Resources

- [Fastlane Match Documentation](https://docs.fastlane.tools/actions/match/)
- [Apple Code Signing Guide](https://developer.apple.com/support/code-signing/)
- [iOS Code Signing Troubleshooting](https://developer.apple.com/support/code-signing/)
- [Fastlane Best Practices](https://docs.fastlane.tools/best-practices/continuous-integration/)

## Support

For help with Match setup:

1. **Check this documentation** first
2. **Search existing issues** in the project repository
3. **Ask in team chat** for quick questions
4. **Create GitHub issue** for complex problems
5. **Consult Fastlane documentation** for advanced scenarios

---

**Last Updated**: $(date)
**Match Setup Version**: 1.0.0
**Compatible with**: Fastlane 2.217+, Xcode 15.4+