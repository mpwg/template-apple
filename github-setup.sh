#!/bin/bash

# GitHub Secrets and Variables Setup Script
# Automatically imports variables from .env file to appropriate GitHub locations

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔐 GitHub Secrets & Variables Setup${NC}"
echo "===================================="
echo

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo -e "${RED}❌ .env file not found. Please run ./setup.sh first.${NC}"
    exit 1
fi

# Check if GitHub CLI is installed and authenticated
if ! command -v gh >/dev/null 2>&1; then
    echo -e "${RED}❌ GitHub CLI (gh) is not installed.${NC}"
    echo "Install it from: https://cli.github.com/"
    exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  Not authenticated with GitHub CLI.${NC}"
    echo "Run: gh auth login"
    exit 1
fi

# Get repository info
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
echo -e "${BLUE}📦 Repository: $REPO${NC}"
echo

# Load environment variables
set -a
source .env
set +a

# Define which variables should be secrets vs variables
# Secrets: sensitive data that should be encrypted
SECRETS=(
    "DEVELOPMENT_TEAM"
    "APP_STORE_CONNECT_KEY_ID"
    "APP_STORE_CONNECT_ISSUER_ID"
    "APPLE_ID"
    "MATCH_PASSWORD"
    "MATCH_GIT_URL"
)

# Variables: non-sensitive configuration data
VARIABLES=(
    "PROJECT_NAME"
    "DISPLAY_NAME"
    "PRODUCT_BUNDLE_IDENTIFIER"
    "ORGANIZATION_NAME"
    "ORGANIZATION_IDENTIFIER"
    "COPYRIGHT"
    "IOS_DEPLOYMENT_TARGET"
    "MACOS_DEPLOYMENT_TARGET"
    "SWIFT_VERSION"
    "GITHUB_REPOSITORY_OWNER"
    "GITHUB_REPOSITORY_NAME"
    "FASTLANE_APP_IDENTIFIER"
    "FASTLANE_SCHEME"
)

echo -e "${BLUE}🔒 Setting up GitHub Secrets...${NC}"
for secret in "${SECRETS[@]}"; do
    # Get the value from environment
    value=$(eval echo \$"$secret")

    if [ -n "$value" ] && [ "$value" != "YOUR_TEAM_ID" ] && [ "$value" != "YOUR_KEY_ID" ] && [ "$value" != "YOUR_ISSUER_ID" ]; then
        if echo "$value" | gh secret set "$secret" --app actions; then
            echo -e "${GREEN}✅ Set secret: $secret${NC}"
        else
            echo -e "${RED}❌ Failed to set secret: $secret${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Skipped $secret (not set or placeholder value)${NC}"
    fi
done

echo
echo -e "${BLUE}📝 Setting up GitHub Variables...${NC}"
for variable in "${VARIABLES[@]}"; do
    # Get the value from environment
    value=$(eval echo \$"$variable")

    if [ -n "$value" ] && [ "$value" != "MyApp" ] && [[ "$value" != *"yourcompany"* ]] && [[ "$value" != *"yourusername"* ]]; then
        if gh variable set "$variable" --body "$value"; then
            echo -e "${GREEN}✅ Set variable: $variable = $value${NC}"
        else
            echo -e "${RED}❌ Failed to set variable: $variable${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Skipped $variable (not customized from template)${NC}"
    fi
done

echo
echo -e "${BLUE}🔑 Additional Setup Required:${NC}"
echo "You need to manually add these secrets (sensitive data that can't be automated):"
echo
echo -e "${YELLOW}APP_STORE_CONNECT_PRIVATE_KEY${NC}"
echo "  Description: Your App Store Connect API private key (.p8 file content)"
echo "  How to get: Download from App Store Connect → Users and Access → Keys"
echo "  Command: cat your-key.p8 | gh secret set APP_STORE_CONNECT_PRIVATE_KEY --app actions"
echo

# Check if match repository exists
if [ -n "$MATCH_GIT_URL" ] && [[ "$MATCH_GIT_URL" != *"yourusername"* ]]; then
    echo -e "${BLUE}🎯 Fastlane Match Setup:${NC}"
    echo "Your match repository: $MATCH_GIT_URL"

    # Extract repository name from URL
    MATCH_REPO=$(echo "$MATCH_GIT_URL" | sed 's/.*github\.com[:/]\([^.]*\)\.git/\1/')

    echo "To create the match repository:"
    echo "  gh repo create $MATCH_REPO --private"
    echo
fi

echo -e "${BLUE}🔍 Verification:${NC}"
echo "To verify your setup:"
echo "  gh secret list --app actions"
echo "  gh variable list"
echo

echo -e "${GREEN}✅ GitHub setup complete!${NC}"
echo
echo -e "${BLUE}📖 Next steps:${NC}"
echo "1. Add the APP_STORE_CONNECT_PRIVATE_KEY secret manually (see above)"
echo "2. Create your Fastlane Match repository if needed"
echo "3. Initialize Fastlane Match: bundle exec fastlane match init"
echo "4. Test your GitHub Actions workflows"
echo
echo -e "${YELLOW}💡 Tip: You can re-run this script anytime to update your secrets/variables${NC}"