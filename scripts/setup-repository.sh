#!/bin/bash
set -e

# Repository Setup Script
# Configures GitHub branch protection rules and repository settings

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}🔧${NC} $1"
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

print_info() {
    echo -e "${PURPLE}ℹ️${NC} $1"
}

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    print_error "GitHub CLI (gh) is not installed. Please install it first:"
    echo "  - macOS: brew install gh"
    echo "  - Other: https://cli.github.com/"
    exit 1
fi

# Check if user is authenticated
if ! gh auth status &> /dev/null; then
    print_error "Not authenticated with GitHub CLI. Please run:"
    echo "  gh auth login"
    exit 1
fi

# Get repository information
if git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    REMOTE_URL=$(git config --get remote.origin.url 2>/dev/null || echo "")
    if [ -n "$REMOTE_URL" ]; then
        # Extract owner/repo from URL
        if [[ "$REMOTE_URL" =~ github\.com[:/]([^/]+)/([^/]+)(\.git)?$ ]]; then
            OWNER="${BASH_REMATCH[1]}"
            REPO="${BASH_REMATCH[2]%.git}"
        else
            print_error "Could not parse GitHub repository from remote URL: $REMOTE_URL"
            exit 1
        fi
    else
        print_error "No GitHub remote found. Make sure this is a GitHub repository."
        exit 1
    fi
else
    print_error "Not in a git repository. Please run this script from your repository root."
    exit 1
fi

print_status "Setting up repository: $OWNER/$REPO"

# Verify repository access
if ! gh repo view "$OWNER/$REPO" > /dev/null 2>&1; then
    print_error "Cannot access repository $OWNER/$REPO. Check your permissions."
    exit 1
fi

print_success "Repository access confirmed"

# Configuration options
SETUP_MAIN_PROTECTION=true
SETUP_DEVELOP_PROTECTION=true
SETUP_RELEASE_PROTECTION=true
CREATE_CODEOWNERS=true
CONFIGURE_REPO_SETTINGS=true

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --main-only)
            SETUP_DEVELOP_PROTECTION=false
            SETUP_RELEASE_PROTECTION=false
            shift
            ;;
        --no-codeowners)
            CREATE_CODEOWNERS=false
            shift
            ;;
        --no-repo-settings)
            CONFIGURE_REPO_SETTINGS=false
            shift
            ;;
        --dry-run)
            print_info "DRY RUN MODE - no changes will be made"
            DRY_RUN=true
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --main-only          Only configure main branch protection"
            echo "  --no-codeowners      Skip creating CODEOWNERS file"
            echo "  --no-repo-settings   Skip repository settings configuration"
            echo "  --dry-run            Show what would be done without making changes"
            echo "  --help               Show this help message"
            echo ""
            echo "This script configures GitHub branch protection rules and repository"
            echo "settings according to best practices for iOS/macOS development."
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

print_info "Configuration:"
echo "  Main branch protection: $([ "$SETUP_MAIN_PROTECTION" = true ] && echo "✅" || echo "❌")"
echo "  Develop branch protection: $([ "$SETUP_DEVELOP_PROTECTION" = true ] && echo "✅" || echo "❌")"
echo "  Release branch protection: $([ "$SETUP_RELEASE_PROTECTION" = true ] && echo "✅" || echo "❌")"
echo "  Create CODEOWNERS: $([ "$CREATE_CODEOWNERS" = true ] && echo "✅" || echo "❌")"
echo "  Repository settings: $([ "$CONFIGURE_REPO_SETTINGS" = true ] && echo "✅" || echo "❌")"
echo "  Dry run: $([ "${DRY_RUN:-false}" = true ] && echo "✅" || echo "❌")"
echo

# Function to execute commands with dry-run support
execute_command() {
    local description=$1
    local command=$2

    print_status "$description"

    if [ "${DRY_RUN:-false}" = true ]; then
        print_info "Would execute: $command"
        return 0
    fi

    if eval "$command"; then
        print_success "$description completed"
        return 0
    else
        print_error "$description failed"
        return 1
    fi
}

# Check if branches exist
print_status "Checking branch availability..."

MAIN_EXISTS=$(gh api repos/$OWNER/$REPO/branches/main --silent 2>/dev/null && echo "true" || echo "false")
DEVELOP_EXISTS=$(gh api repos/$OWNER/$REPO/branches/develop --silent 2>/dev/null && echo "true" || echo "false")

print_info "Branch status:"
echo "  main: $([ "$MAIN_EXISTS" = true ] && echo "✅ exists" || echo "❌ not found")"
echo "  develop: $([ "$DEVELOP_EXISTS" = true ] && echo "✅ exists" || echo "❌ not found")"

if [ "$MAIN_EXISTS" = false ]; then
    print_warning "Main branch not found - skipping main branch protection"
    SETUP_MAIN_PROTECTION=false
fi

if [ "$DEVELOP_EXISTS" = false ] && [ "$SETUP_DEVELOP_PROTECTION" = true ]; then
    print_warning "Develop branch not found - do you want to create it? (y/N)"
    read -n 1 -r REPLY
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        execute_command "Creating develop branch" \
            "gh api repos/$OWNER/$REPO/git/refs --method POST --field ref=refs/heads/develop --field sha=\$(gh api repos/$OWNER/$REPO/git/refs/heads/main --jq '.object.sha')"
        DEVELOP_EXISTS=true
    else
        print_info "Skipping develop branch protection"
        SETUP_DEVELOP_PROTECTION=false
    fi
fi

# Configure main branch protection
if [ "$SETUP_MAIN_PROTECTION" = true ]; then
    print_status "=== Configuring Main Branch Protection ==="

    MAIN_PROTECTION_CONFIG='{
        "required_status_checks": {
            "strict": true,
            "contexts": [
                "CI Tests",
                "Security Scans",
                "SwiftLint",
                "Package Validation"
            ]
        },
        "enforce_admins": true,
        "required_pull_request_reviews": {
            "dismiss_stale_reviews": true,
            "require_code_owner_reviews": true,
            "required_approving_review_count": 2,
            "require_last_push_approval": true
        },
        "restrictions": null,
        "required_conversation_resolution": true,
        "allow_force_pushes": false,
        "allow_deletions": false,
        "block_creations": false,
        "required_linear_history": false
    }'

    execute_command "Setting main branch protection rules" \
        "gh api repos/$OWNER/$REPO/branches/main/protection --method PUT --input - <<< '$MAIN_PROTECTION_CONFIG'"
fi

# Configure develop branch protection
if [ "$SETUP_DEVELOP_PROTECTION" = true ]; then
    print_status "=== Configuring Develop Branch Protection ==="

    DEVELOP_PROTECTION_CONFIG='{
        "required_status_checks": {
            "strict": true,
            "contexts": [
                "Build and Test",
                "SwiftLint",
                "Package Validation"
            ]
        },
        "enforce_admins": false,
        "required_pull_request_reviews": {
            "dismiss_stale_reviews": false,
            "require_code_owner_reviews": false,
            "required_approving_review_count": 1
        },
        "restrictions": null,
        "required_conversation_resolution": false,
        "allow_force_pushes": false,
        "allow_deletions": false
    }'

    execute_command "Setting develop branch protection rules" \
        "gh api repos/$OWNER/$REPO/branches/develop/protection --method PUT --input - <<< '$DEVELOP_PROTECTION_CONFIG'"
fi

# Configure release branch pattern protection
if [ "$SETUP_RELEASE_PROTECTION" = true ]; then
    print_status "=== Configuring Release Branch Protection ==="

    RELEASE_PROTECTION_CONFIG='{
        "required_status_checks": {
            "strict": true,
            "contexts": [
                "CI Tests",
                "Security Scans",
                "SwiftLint",
                "Package Validation",
                "Release Validation"
            ]
        },
        "enforce_admins": true,
        "required_pull_request_reviews": {
            "dismiss_stale_reviews": true,
            "require_code_owner_reviews": true,
            "required_approving_review_count": 2
        },
        "restrictions": {
            "users": [],
            "teams": ["maintainers"]
        },
        "required_conversation_resolution": true,
        "allow_force_pushes": false,
        "allow_deletions": false
    }'

    # Note: GitHub API doesn't support wildcard patterns directly
    # This would need to be set up manually in the UI or using a different approach
    print_info "Release branch pattern protection (release/*) must be configured manually:"
    print_info "1. Go to Settings → Branches in GitHub"
    print_info "2. Add rule with pattern 'release/*'"
    print_info "3. Use similar settings to main branch"
fi

# Create CODEOWNERS file
if [ "$CREATE_CODEOWNERS" = true ]; then
    print_status "=== Creating CODEOWNERS File ==="

    CODEOWNERS_CONTENT="# Code Owners Configuration
# This file defines individuals or teams responsible for code in this repository.
# Order is important; the last matching pattern takes precedence.

# Global owners - these users/teams are requested as reviewers for all changes
* @maintainers-team

# iOS/Swift specific files
*.swift @ios-team @swift-experts
*.xcodeproj @ios-team
*.xcworkspace @ios-team
*.plist @ios-team
*.storyboard @ios-team @ui-team
*.xib @ios-team @ui-team

# Package Manager files
Package.swift @swift-experts @maintainers-team
*.podspec @ios-team
Cartfile* @ios-team
*.xcconfig @ios-team

# Fastlane configuration
fastlane/ @release-team @maintainers-team
Fastfile @release-team @maintainers-team
Appfile @release-team @maintainers-team
Matchfile @release-team

# CI/CD and automation
.github/ @devops-team @maintainers-team
*.yml @devops-team
*.yaml @devops-team
Dockerfile* @devops-team
scripts/ @devops-team @maintainers-team

# Documentation
*.md @documentation-team
docs/ @documentation-team
README* @documentation-team @maintainers-team

# Configuration and environment
.env* @devops-team @maintainers-team
*.json @maintainers-team
*.plist @ios-team

# Testing
*Test* @ios-team @qa-team
*Tests/ @ios-team @qa-team
UITests/ @ios-team @qa-team @ui-team

# Security sensitive files
SECURITY.md @security-team @maintainers-team
*.p12 @security-team @release-team
*.mobileprovision @security-team @release-team

# Legal and licensing
LICENSE* @legal-team @maintainers-team
NOTICE* @legal-team
COPYRIGHT* @legal-team"

    if [ "${DRY_RUN:-false}" = true ]; then
        print_info "Would create .github/CODEOWNERS file"
        print_info "Content preview:"
        echo "$CODEOWNERS_CONTENT" | head -10
        echo "... (truncated)"
    else
        mkdir -p .github
        echo "$CODEOWNERS_CONTENT" > .github/CODEOWNERS
        print_success "Created .github/CODEOWNERS file"
    fi
fi

# Configure repository settings
if [ "$CONFIGURE_REPO_SETTINGS" = true ]; then
    print_status "=== Configuring Repository Settings ==="

    # Configure merge settings
    REPO_SETTINGS='{
        "allow_squash_merge": true,
        "allow_merge_commit": false,
        "allow_rebase_merge": false,
        "allow_auto_merge": true,
        "delete_branch_on_merge": true,
        "allow_update_branch": true,
        "squash_merge_commit_title": "PR_TITLE",
        "squash_merge_commit_message": "PR_BODY"
    }'

    execute_command "Updating repository merge settings" \
        "gh api repos/$OWNER/$REPO --method PATCH --input - <<< '$REPO_SETTINGS'"

    # Configure security settings
    print_status "Enabling security features..."

    execute_command "Enabling vulnerability alerts" \
        "gh api repos/$OWNER/$REPO/vulnerability-alerts --method PUT"

    execute_command "Enabling automated security fixes" \
        "gh api repos/$OWNER/$REPO/automated-security-fixes --method PUT"

    # Note: Some settings may require GitHub Advanced Security
    print_info "Additional security features (may require GitHub Advanced Security):"
    print_info "- Secret scanning: Enable in Settings → Security & analysis"
    print_info "- Code scanning: Enable in Settings → Security & analysis"
    print_info "- Dependency review: Enable in Settings → Security & analysis"
fi

# Summary and next steps
print_status "=== Setup Complete ==="

echo "📊 Configuration Summary:"
echo "  Repository: $OWNER/$REPO"
echo "  Main branch protection: $([ "$SETUP_MAIN_PROTECTION" = true ] && echo "✅" || echo "❌")"
echo "  Develop branch protection: $([ "$SETUP_DEVELOP_PROTECTION" = true ] && echo "✅" || echo "❌")"
echo "  CODEOWNERS file: $([ "$CREATE_CODEOWNERS" = true ] && echo "✅" || echo "❌")"
echo "  Repository settings: $([ "$CONFIGURE_REPO_SETTINGS" = true ] && echo "✅" || echo "❌")"

echo
print_info "Next Steps:"
echo "1. Review branch protection rules in GitHub Settings → Branches"
echo "2. Verify team permissions and access levels"
echo "3. Update .github/CODEOWNERS with your actual team names"
echo "4. Configure required status checks to match your CI workflows"
echo "5. Test the protection rules with a test PR"

echo
print_info "Manual Configuration Required:"
echo "• Release branch pattern protection (release/*) in GitHub UI"
echo "• Team creation and member assignment"
echo "• Advanced security features (if available)"
echo "• Webhook and integration settings"

echo
print_warning "Important Notes:"
echo "• Some features require GitHub Advanced Security license"
echo "• Teams referenced in CODEOWNERS must exist in your organization"
echo "• Status checks must match the names used in your GitHub Actions workflows"
echo "• Test the configuration thoroughly before relying on it"

if [ "${DRY_RUN:-false}" = true ]; then
    echo
    print_info "This was a dry run. Re-run without --dry-run to apply changes."
else
    echo
    print_success "🎉 Repository setup completed successfully!"

    # Offer to open GitHub settings
    echo
    read -p "Open GitHub repository settings in browser? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        gh repo view --web "$OWNER/$REPO" --branch main
    fi
fi

exit 0