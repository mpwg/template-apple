- This is a Template Repository
- Allways follow the current best practices
- It is used for Development with Xcode 26, targeting iOS, iPadOS, macOS (via MacCatalyst)
- it uses a github pipeline
- It uses Fastlane
- It has this env. variables accessable: # Fastlane Environment Variables Template
# Copy this file to .env and fill in your actual values
# Then run: gh secret set -f .env to push to GitHub repository secrets

# =============================================================================
# APPLE DEVELOPER ACCOUNT
# =============================================================================
APPLE_ID=your-apple-id@example.com
DEVELOPMENT_TEAM=YOUR_DEVELOPMENT_TEAM_ID
APPSTORE_TEAM_ID=YOUR_APPSTORE_TEAM_ID

# =============================================================================
# APP STORE CONNECT API AUTHENTICATION (Recommended)
# =============================================================================
# Option 1: API Key (Recommended - more secure than session cookie)
APP_STORE_CONNECT_API_KEY_KEY_ID=your_api_key_id
APP_STORE_CONNECT_API_KEY_ISSUER_ID=your_issuer_id
APP_STORE_CONNECT_API_KEY_CONTENT="-----BEGIN PRIVATE KEY-----\nYOUR_PRIVATE_KEY_CONTENT_HERE\n-----END PRIVATE KEY-----"

# Option 2: Session Cookie (Alternative - expires regularly)
# FASTLANE_SESSION=your_fastlane_session_cookie

# =============================================================================
# CODE SIGNING (Fastlane Match)
# =============================================================================
MATCH_PASSWORD=your_match_repository_password
MATCH_GIT_URL=https://github.com/your-org/certificates-repo.git
MATCH_GIT_BASIC_AUTHORIZATION=your_git_basic_auth_token

# =============================================================================
# CI/CD ENVIRONMENT
# =============================================================================
# Required for GitHub Actions keychain setup
KEYCHAIN_PASSWORD=your_ci_keychain_password

# =============================================================================
# FASTLANE CONFIGURATION
# =============================================================================
# Reduce prompts and noise
FASTLANE_SKIP_UPDATE_CHECK=1
FASTLANE_HIDE_GITHUB_ISSUES=1
FASTLANE_HIDE_CHANGELOG=1
- It has a documented branch strategy based on modern best practices
- It has a template for the .env file
- It has a Readme detailing on how to use the Template Repository and what needs to be changed in order to use it
- It has a .gitignore File that fits the content
- It has a dependabot action for all relevant parts
- it has the MIT License