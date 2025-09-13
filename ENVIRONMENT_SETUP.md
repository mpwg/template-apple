# Environment Setup Guide

This guide will help you set up your local development environment and configure CI/CD secrets for iOS/macOS app development with Fastlane and GitHub Actions.

## Table of Contents

- [Quick Start](#quick-start)
- [Local Development Setup](#local-development-setup)
- [Apple Developer Account Setup](#apple-developer-account-setup)
- [App Store Connect API Setup](#app-store-connect-api-setup)
- [Fastlane Match Setup](#fastlane-match-setup)
- [GitHub Secrets Configuration](#github-secrets-configuration)
- [Validation and Testing](#validation-and-testing)
- [Troubleshooting](#troubleshooting)
- [Security Best Practices](#security-best-practices)

## Quick Start

1. **Copy the environment template:**
   ```bash
   cp .env.template .env
   ```

2. **Fill in your actual values in `.env`**
3. **Upload secrets to GitHub:**
   ```bash
   gh secret set -f .env
   ```

## Local Development Setup

### Prerequisites

- Xcode 15.4+ installed
- Apple Developer Account with appropriate permissions
- GitHub CLI (`gh`) installed
- Ruby 3.2+ and Bundler installed

### Step 1: Environment File Setup

1. Copy the template file:
   ```bash
   cp .env.template .env
   ```

2. Open `.env` in your preferred editor and replace all placeholder values with your actual configuration.

3. **Important:** Never commit the `.env` file to version control. It should already be in `.gitignore`.

### Step 2: Install Dependencies

```bash
# Install Ruby dependencies
bundle config path vendor/bundle
bundle install

# Verify Fastlane installation
bundle exec fastlane --version
```

### Step 3: Verify Configuration

```bash
# Test Fastlane configuration
bundle exec fastlane list

# Test environment variables
bundle exec fastlane env
```

## Apple Developer Account Setup

### Required Information

1. **Apple ID**: Your Apple Developer account email
2. **Development Team ID**:
   - Go to [Apple Developer Portal](https://developer.apple.com)
   - Navigate to Account > Membership
   - Note your Team ID (10-character alphanumeric)
3. **App Store Connect Team ID**:
   - Go to [App Store Connect](https://appstoreconnect.apple.com)
   - Navigate to Users and Access
   - Note your Team ID (may differ from Development Team ID)

### Account Permissions

Ensure your Apple ID has the following permissions:
- **Developer Portal**: Admin or App Manager role
- **App Store Connect**: Admin, App Manager, or Developer role
- **Certificates**: Ability to create and manage certificates

## App Store Connect API Setup

Using App Store Connect API keys is the recommended authentication method as it's more secure and doesn't expire like session cookies.

### Step 1: Generate API Key

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Navigate to **Users and Access** > **Keys** tab
3. Click **Generate API Key** or the **+** button
4. Enter a name for your key (e.g., "CI/CD Pipeline")
5. Select access level:
   - **Developer**: For most CI/CD operations
   - **App Manager**: If you need broader access
6. Click **Generate**
7. **Important**: Download the private key file (.p8) immediately - you won't be able to download it again

### Step 2: Configure Environment Variables

From the generated key, you'll need:

```bash
# The Key ID (visible in App Store Connect)
APP_STORE_CONNECT_API_KEY_KEY_ID=ABC12DEF34

# The Issuer ID (shown at the top of the Keys page)
APP_STORE_CONNECT_API_KEY_ISSUER_ID=12345678-1234-1234-1234-123456789012

# The content of the downloaded .p8 file
APP_STORE_CONNECT_API_KEY_CONTENT="-----BEGIN PRIVATE KEY-----\nMIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQg...\n-----END PRIVATE KEY-----"
```

### Converting P8 File Content

To convert your .p8 file to the required format:

```bash
# Replace newlines with \n
cat YourKey.p8 | sed ':a;N;$!ba;s/\n/\\n/g'

# Or use this one-liner to copy to clipboard (macOS)
cat YourKey.p8 | sed ':a;N;$!ba;s/\n/\\n/g' | pbcopy
```

## Fastlane Match Setup

Fastlane Match stores your certificates and provisioning profiles in a Git repository, encrypted with a passphrase.

### Step 1: Create Certificates Repository

1. Create a **private** Git repository (GitHub, GitLab, etc.)
2. Name it something like `ios-certificates` or `certificates`
3. Initialize it as an empty repository (no README, .gitignore, etc.)

### Step 2: Generate Personal Access Token

#### For GitHub:
1. Go to **Settings** > **Developer settings** > **Personal access tokens** > **Tokens (classic)**
2. Click **Generate new token (classic)**
3. Select scopes: `repo` (full repository access)
4. Generate and copy the token

#### For GitLab:
1. Go to **User Settings** > **Access Tokens**
2. Create token with `api` and `read_repository`, `write_repository` scopes

### Step 3: Initialize Match

```bash
# Initialize match (run this once)
bundle exec fastlane match init

# Follow the prompts:
# - Choose git storage
# - Enter your repository URL
# - The passphrase will be set later
```

### Step 4: Configure Environment Variables

```bash
# Strong password for encrypting certificates
MATCH_PASSWORD=your_very_secure_password_here

# Your certificates repository URL
MATCH_GIT_URL=https://github.com/your-org/ios-certificates.git

# Your Git access token
MATCH_GIT_BASIC_AUTHORIZATION=ghp_xxxxxxxxxxxxxxxxxxxx
```

### Step 5: Generate Certificates

```bash
# Generate development certificates
bundle exec fastlane match development

# Generate App Store certificates
bundle exec fastlane match appstore

# Generate Ad Hoc certificates (optional)
bundle exec fastlane match adhoc
```

## GitHub Secrets Configuration

### Required Secrets

Your GitHub repository needs the following secrets for CI/CD workflows:

#### Apple Developer Account
- `APPLE_ID`
- `DEVELOPMENT_TEAM`
- `APPSTORE_TEAM_ID`

#### App Store Connect API
- `APP_STORE_CONNECT_API_KEY_KEY_ID`
- `APP_STORE_CONNECT_API_KEY_ISSUER_ID`
- `APP_STORE_CONNECT_API_KEY_CONTENT`

#### Fastlane Match
- `MATCH_PASSWORD`
- `MATCH_GIT_URL`
- `MATCH_GIT_BASIC_AUTHORIZATION`

#### CI/CD Configuration
- `KEYCHAIN_PASSWORD`

### Bulk Upload Secrets

After configuring your `.env` file:

```bash
# Upload all secrets at once
gh secret set -f .env

# Or upload individually
gh secret set APPLE_ID --body "your-email@example.com"
gh secret set DEVELOPMENT_TEAM --body "ABC1234567"
```

### Verify Secrets

```bash
# List all repository secrets
gh secret list

# Check if a specific secret exists
gh secret list | grep APPLE_ID
```

## Validation and Testing

### Local Validation

1. **Test environment loading:**
   ```bash
   source .env
   echo $APPLE_ID
   ```

2. **Test Fastlane configuration:**
   ```bash
   bundle exec fastlane list
   bundle exec fastlane env
   ```

3. **Test Match access:**
   ```bash
   bundle exec fastlane match development --readonly
   ```

### CI/CD Validation

1. **Create a test branch:**
   ```bash
   git checkout -b test/environment-setup
   git commit --allow-empty -m "Test: environment setup"
   git push -u origin test/environment-setup
   ```

2. **Create a test PR** to trigger the validation workflow

3. **Monitor GitHub Actions** for any authentication or configuration issues

### Validation Script

Create a simple validation script:

```bash
#!/bin/bash
# scripts/validate-environment.sh

echo "🔍 Validating environment configuration..."

# Check required environment variables
required_vars=(
    "APPLE_ID"
    "DEVELOPMENT_TEAM"
    "APP_STORE_CONNECT_API_KEY_KEY_ID"
    "MATCH_PASSWORD"
)

for var in "${required_vars[@]}"; do
    if [[ -z "${!var}" ]]; then
        echo "❌ Missing required variable: $var"
        exit 1
    else
        echo "✅ $var is set"
    fi
done

echo "🎉 Environment validation completed successfully!"
```

## Troubleshooting

### Common Issues

#### 1. Authentication Failures

**Symptoms:**
- "Invalid credentials" errors
- "Authentication failed" messages

**Solutions:**
- Verify Apple ID and password
- Check if two-factor authentication is enabled
- Regenerate App Store Connect API key
- Verify API key has correct permissions

#### 2. Certificate Issues

**Symptoms:**
- "No matching provisioning profiles found"
- "Certificate not found in keychain"

**Solutions:**
- Run `bundle exec fastlane match development --force`
- Verify Match repository access
- Check certificate expiration dates
- Ensure correct bundle identifier

#### 3. Match Repository Access

**Symptoms:**
- "Permission denied" when accessing Git repository
- "Repository not found" errors

**Solutions:**
- Verify Git repository URL
- Check Personal Access Token permissions
- Ensure repository is private
- Test Git access manually: `git clone [MATCH_GIT_URL]`

#### 4. GitHub Actions Failures

**Symptoms:**
- Secrets not found in workflows
- Environment variables not set

**Solutions:**
- Verify secrets are uploaded: `gh secret list`
- Check secret names match workflow files
- Re-upload secrets if needed: `gh secret set -f .env`

### Debug Commands

```bash
# Check Fastlane environment
bundle exec fastlane env

# Test Match access
bundle exec fastlane match development --readonly --verbose

# Validate certificates in keychain
security find-identity -v -p codesigning

# Test GitHub CLI authentication
gh auth status

# List repository secrets
gh secret list
```

### Getting Help

1. **Check Fastlane logs** in `fastlane/logs/`
2. **Review GitHub Actions logs** in the Actions tab
3. **Consult documentation:**
   - [Fastlane Documentation](https://docs.fastlane.tools/)
   - [GitHub Actions Documentation](https://docs.github.com/en/actions)
   - [Apple Developer Documentation](https://developer.apple.com/documentation/)

## Security Best Practices

### 1. Credential Management

- **Never commit secrets** to version control
- **Use strong, unique passwords** for all services
- **Rotate API keys and certificates** regularly (every 6-12 months)
- **Use App Store Connect API keys** instead of session cookies
- **Limit scope** of Personal Access Tokens

### 2. Repository Security

- **Keep certificate repositories private**
- **Use separate repositories** for different projects/teams
- **Audit repository access** regularly
- **Enable branch protection** on certificate repositories

### 3. CI/CD Security

- **Use GitHub repository secrets** instead of hardcoded values
- **Limit workflow permissions** to minimum required
- **Monitor workflow runs** for suspicious activity
- **Use dependabot** for dependency updates

### 4. Access Control

- **Follow principle of least privilege**
- **Use service accounts** for CI/CD instead of personal accounts
- **Enable two-factor authentication** on all accounts
- **Regularly review** team access and permissions

### 5. Monitoring and Auditing

- **Monitor certificate expiration** dates
- **Set up alerts** for failed workflows
- **Review access logs** periodically
- **Document** all configuration changes

### 6. Environment Separation

- **Use different certificates** for development, staging, and production
- **Separate App Store Connect** keys by environment
- **Implement proper** environment-specific configurations
- **Test thoroughly** before promoting to production

---

## Next Steps

After completing the environment setup:

1. **Test local development workflow**
2. **Verify CI/CD pipeline functionality**
3. **Document any project-specific configurations**
4. **Train team members** on the setup process
5. **Establish** regular maintenance schedule for certificates and keys

For additional help or questions, refer to the project documentation or create an issue in the repository.