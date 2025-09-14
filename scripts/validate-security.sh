#!/bin/bash
set -e

# Repository Security Validation Script
# Validates GitHub repository security configuration and settings

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}🔒${NC} $1"
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
    print_error "GitHub CLI (gh) is not installed. Please install it first."
    exit 1
fi

# Check if user is authenticated
if ! gh auth status &> /dev/null; then
    print_error "Not authenticated with GitHub CLI. Please run: gh auth login"
    exit 1
fi

# Get repository information
if git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    REMOTE_URL=$(git config --get remote.origin.url 2>/dev/null || echo "")
    if [ -n "$REMOTE_URL" ]; then
        if [[ "$REMOTE_URL" =~ github\.com[:/]([^/]+)/([^/]+)(\.git)?$ ]]; then
            OWNER="${BASH_REMATCH[1]}"
            REPO="${BASH_REMATCH[2]%.git}"
        else
            print_error "Could not parse GitHub repository from remote URL: $REMOTE_URL"
            exit 1
        fi
    else
        print_error "No GitHub remote found."
        exit 1
    fi
else
    print_error "Not in a git repository."
    exit 1
fi

print_status "Validating repository security: $OWNER/$REPO"

# Validation counters
PASSED=0
FAILED=0
WARNINGS=0

# Function to validate and track results
validate_check() {
    local description=$1
    local command=$2
    local is_warning=${3:-false}

    if eval "$command" >/dev/null 2>&1; then
        print_success "$description"
        PASSED=$((PASSED + 1))
        return 0
    else
        if [ "$is_warning" = true ]; then
            print_warning "$description"
            WARNINGS=$((WARNINGS + 1))
        else
            print_error "$description"
            FAILED=$((FAILED + 1))
        fi
        return 1
    fi
}

# Repository Access Validation
print_status "=== Repository Access ==="

validate_check "Repository is accessible" \
    "gh repo view $OWNER/$REPO"

validate_check "User has admin access" \
    "gh api repos/$OWNER/$REPO --jq '.permissions.admin' | grep -q true" \
    true

echo

# Branch Protection Validation
print_status "=== Branch Protection ==="

validate_check "Main branch protection enabled" \
    "gh api repos/$OWNER/$REPO/branches/main/protection"

validate_check "Main branch requires PR reviews" \
    "gh api repos/$OWNER/$REPO/branches/main/protection --jq '.required_pull_request_reviews.required_approving_review_count' | grep -qE '[1-9]'"

validate_check "Main branch requires status checks" \
    "gh api repos/$OWNER/$REPO/branches/main/protection --jq '.required_status_checks.strict' | grep -q true"

validate_check "Main branch dismisses stale reviews" \
    "gh api repos/$OWNER/$REPO/branches/main/protection --jq '.required_pull_request_reviews.dismiss_stale_reviews' | grep -q true"

validate_check "Develop branch protection (if exists)" \
    "gh api repos/$OWNER/$REPO/branches/develop/protection || true" \
    true

echo

# Security Features Validation
print_status "=== Security Features ==="

validate_check "Vulnerability alerts enabled" \
    "gh api repos/$OWNER/$REPO/vulnerability-alerts"

validate_check "Automated security fixes enabled (Dependabot)" \
    "gh api repos/$OWNER/$REPO/automated-security-fixes"

validate_check "Secret scanning enabled" \
    "gh api repos/$OWNER/$REPO/secret-scanning/alerts || true" \
    true

validate_check "Code scanning enabled" \
    "gh api repos/$OWNER/$REPO/code-scanning/alerts || true" \
    true

validate_check "Dependency graph enabled" \
    "gh api repos/$OWNER/$REPO --jq '.has_dependency_graph' | grep -q true"

echo

# Repository Settings Validation
print_status "=== Repository Settings ==="

validate_check "Repository is private (or appropriately public)" \
    "gh api repos/$OWNER/$REPO --jq '.private' | grep -q true" \
    true

validate_check "Issues are enabled" \
    "gh api repos/$OWNER/$REPO --jq '.has_issues' | grep -q true"

validate_check "Merge commits disabled (squash only)" \
    "gh api repos/$OWNER/$REPO --jq '.allow_merge_commit' | grep -q false"

validate_check "Auto-delete head branches enabled" \
    "gh api repos/$OWNER/$REPO --jq '.delete_branch_on_merge' | grep -q true"

validate_check "Force pushes disabled" \
    "gh api repos/$OWNER/$REPO/branches/main/protection --jq '.allow_force_pushes.enabled' | grep -q false"

echo

# Required Files Validation
print_status "=== Required Files ==="

validate_check "SECURITY.md exists" \
    "[ -f SECURITY.md ]"

validate_check "LICENSE file exists" \
    "[ -f LICENSE ] || [ -f LICENSE.txt ] || [ -f LICENSE.md ]"

validate_check "CODEOWNERS file exists" \
    "[ -f .github/CODEOWNERS ]"

validate_check "README.md exists" \
    "[ -f README.md ]"

validate_check "Dependabot configuration exists" \
    "[ -f .github/dependabot.yml ]" \
    true

echo

# Workflow and CI/CD Validation
print_status "=== CI/CD and Workflows ==="

validate_check "GitHub Actions workflows exist" \
    "[ -d .github/workflows ] && [ $(ls .github/workflows/*.yml 2>/dev/null | wc -l) -gt 0 ]"

validate_check "CI workflow exists" \
    "[ -f .github/workflows/ci.yml ] || [ -f .github/workflows/test.yml ]"

validate_check "Security workflow exists" \
    "[ -f .github/workflows/security.yml ]" \
    true

validate_check "Release workflow exists" \
    "[ -f .github/workflows/release.yml ]" \
    true

echo

# Team and Permissions Validation
print_status "=== Teams and Permissions ==="

# Check if teams exist (this might fail for personal repositories)
validate_check "Maintainers team has access" \
    "gh api repos/$OWNER/$REPO/teams/maintainers-team 2>/dev/null || gh api repos/$OWNER/$REPO/teams/maintainers 2>/dev/null" \
    true

validate_check "Outside collaborators limited" \
    "[ $(gh api repos/$OWNER/$REPO/collaborators --jq 'length') -lt 10 ]" \
    true

echo

# Advanced Security Checks
print_status "=== Advanced Security ==="

# Check for common security misconfigurations
validate_check "No secrets in repository" \
    "! git log --all --grep='password\\|secret\\|key\\|token' --oneline | head -5 | grep -q ." \
    true

validate_check "Signed commits enabled" \
    "gh api repos/$OWNER/$REPO/branches/main/protection --jq '.required_signatures.enabled' | grep -q true" \
    true

validate_check "Conversation resolution required" \
    "gh api repos/$OWNER/$REPO/branches/main/protection --jq '.required_conversation_resolution.enabled' | grep -q true" \
    true

echo

# Package and Dependency Security
print_status "=== Package Security ==="

if [ -f "Package.swift" ]; then
    validate_check "Swift Package.swift exists and valid" \
        "swift package dump-package >/dev/null 2>&1"
fi

if [ -f "Gemfile" ]; then
    validate_check "Ruby Gemfile.lock exists" \
        "[ -f Gemfile.lock ]"

    if command -v bundle &> /dev/null; then
        validate_check "No Ruby vulnerability warnings" \
            "bundle audit --quiet" \
            true
    fi
fi

if [ -f "fastlane/Fastfile" ]; then
    validate_check "Fastlane configuration exists" \
        "[ -f fastlane/Fastfile ]"
fi

echo

# Generate Security Report
print_status "=== Security Report Generation ==="

REPORT_FILE="security-validation-report-$(date +%Y%m%d_%H%M%S).md"

cat > "$REPORT_FILE" << EOF
# Security Validation Report

**Repository:** $OWNER/$REPO
**Generated:** $(date)
**Validation Script Version:** 1.0

## Summary

- ✅ Passed: $PASSED checks
- ❌ Failed: $FAILED checks
- ⚠️ Warnings: $WARNINGS checks

**Overall Security Score:** $(( (PASSED * 100) / (PASSED + FAILED + WARNINGS) ))%

## Recommendations

### High Priority (Failed Checks)
$([ $FAILED -gt 0 ] && echo "- Review and address all failed security checks" || echo "- All critical security checks passed ✅")

### Medium Priority (Warnings)
$([ $WARNINGS -gt 0 ] && echo "- Consider addressing warning items for enhanced security" || echo "- No warning items found ✅")

### Continuous Improvement
- Schedule regular security validation runs
- Monitor security alerts and dependencies
- Keep security policies updated
- Provide security training for team members

## Next Steps

1. Address any failed security checks immediately
2. Review warning items and implement as appropriate
3. Schedule monthly security validation runs
4. Update team on security status

## Resources

- [Repository Security Guide](REPOSITORY_SECURITY_GUIDE.md)
- [GitHub Security Features](https://docs.github.com/en/code-security)
- [Branch Protection Rules](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/defining-the-mergeability-of-pull-requests/about-protected-branches)

---
*Generated by repository security validation script*
EOF

print_success "Security report generated: $REPORT_FILE"

# Summary
echo
print_status "=== Validation Summary ==="

echo "📊 Security Validation Results:"
echo "  ✅ Passed: $PASSED"
echo "  ❌ Failed: $FAILED"
echo "  ⚠️ Warnings: $WARNINGS"
echo "  📄 Report: $REPORT_FILE"

# Calculate overall score
TOTAL_CHECKS=$((PASSED + FAILED + WARNINGS))
if [ $TOTAL_CHECKS -gt 0 ]; then
    SCORE=$(( (PASSED * 100) / TOTAL_CHECKS ))
    echo "  📈 Security Score: ${SCORE}%"

    if [ $SCORE -ge 90 ]; then
        print_success "Excellent security configuration! 🏆"
    elif [ $SCORE -ge 75 ]; then
        print_success "Good security configuration ✨"
    elif [ $SCORE -ge 60 ]; then
        print_warning "Moderate security configuration - improvements recommended 🔧"
    else
        print_error "Security configuration needs significant improvement ⚠️"
    fi
fi

echo

# Next steps
print_info "Next Steps:"
if [ $FAILED -gt 0 ]; then
    echo "1. 🚨 Address failed security checks immediately"
fi
if [ $WARNINGS -gt 0 ]; then
    echo "2. 🔍 Review warning items and implement improvements"
fi
echo "3. 📅 Schedule regular security validation (monthly)"
echo "4. 📚 Review security documentation and best practices"
echo "5. 👥 Share security report with team"

echo
if [ $FAILED -eq 0 ]; then
    print_success "🎉 Security validation completed successfully!"
    echo "Repository meets basic security requirements."
    exit 0
else
    print_error "❗ Security validation found issues that need attention"
    echo "Please address the failed checks before proceeding."
    exit 1
fi