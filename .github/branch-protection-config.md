# GitHub Branch Protection Configuration

This document outlines the recommended branch protection rules and GitHub repository settings for optimal security and workflow automation.

## Table of Contents

- [Branch Protection Rules](#branch-protection-rules)
- [Repository Settings](#repository-settings)
- [Status Checks Configuration](#status-checks-configuration)
- [Team and User Permissions](#team-and-user-permissions)
- [Automated Setup](#automated-setup)
- [Troubleshooting](#troubleshooting)

## Branch Protection Rules

### Main Branch Protection

The `main` branch should have the strongest protection as it represents production-ready code.

**Recommended Settings:**
- ✅ Require a pull request before merging
- ✅ Require approvals (minimum 2 reviewers)
- ✅ Dismiss stale PR approvals when new commits are pushed
- ✅ Require review from code owners
- ✅ Require status checks to pass before merging
- ✅ Require branches to be up to date before merging
- ✅ Require conversation resolution before merging
- ✅ Restrict pushes that create files larger than 100MB
- ✅ Require signed commits
- ❌ Allow force pushes
- ❌ Allow deletions

**GitHub CLI Configuration:**
```bash
gh api repos/:owner/:repo/branches/main/protection \
  --method PUT \
  --field required_status_checks='{"strict":true,"contexts":["CI/CD Pipeline","Security Scan","SwiftLint","Unit Tests"]}' \
  --field enforce_admins=true \
  --field required_pull_request_reviews='{"dismiss_stale_reviews":true,"require_code_owner_reviews":true,"required_approving_review_count":2}' \
  --field restrictions='{"users":[],"teams":["maintainers"]}' \
  --field allow_squash_merge=true \
  --field allow_merge_commit=false \
  --field allow_rebase_merge=false
```

**Manual Setup via GitHub Web UI:**
1. Go to **Settings** → **Branches**
2. Click **Add rule** or edit existing rule for `main`
3. Configure as shown above

### Develop Branch Protection

The `develop` branch serves as an integration branch with moderate protection.

**Recommended Settings:**
- ✅ Require a pull request before merging
- ✅ Require approvals (minimum 1 reviewer)
- ❌ Dismiss stale PR approvals (for faster integration)
- ❌ Require review from code owners
- ✅ Require status checks to pass before merging
- ✅ Require branches to be up to date before merging
- ❌ Require conversation resolution (optional)
- ✅ Restrict pushes that create files larger than 100MB
- ❌ Require signed commits (optional)
- ❌ Allow force pushes (admins only)
- ❌ Allow deletions

**GitHub CLI Configuration:**
```bash
gh api repos/:owner/:repo/branches/develop/protection \
  --method PUT \
  --field required_status_checks='{"strict":true,"contexts":["Build and Test","SwiftLint"]}' \
  --field enforce_admins=false \
  --field required_pull_request_reviews='{"dismiss_stale_reviews":false,"require_code_owner_reviews":false,"required_approving_review_count":1}' \
  --field restrictions=null \
  --field allow_squash_merge=true \
  --field allow_merge_commit=true \
  --field allow_rebase_merge=true
```

### Release Branch Protection

Release branches need careful handling to ensure stability.

**Recommended Settings:**
- ✅ Require a pull request before merging
- ✅ Require approvals (minimum 2 reviewers for main, 1 for develop)
- ✅ Dismiss stale PR approvals when new commits are pushed
- ✅ Require review from code owners
- ✅ Require status checks to pass before merging
- ✅ Require branches to be up to date before merging
- ✅ Require conversation resolution before merging
- ❌ Allow force pushes (admins only)
- ❌ Allow deletions

**Pattern-based Protection:**
Use pattern `release/*` to protect all release branches automatically.

### Feature Branch Guidelines

Feature branches typically don't need protection rules, but should follow these guidelines:

**Development Rules:**
- Must branch from `develop`
- Must create PR to merge back to `develop`
- Should pass CI checks before merging
- Can be deleted after successful merge

**Naming Convention:**
- `feature/short-description`
- `feature/issue-123-description`
- `feature/team-name/description`

## Repository Settings

### General Settings

**Repository Visibility:**
- Use **Private** for proprietary projects
- Use **Public** only for open-source projects

**Features:**
- ✅ Issues
- ✅ Projects (if using GitHub Projects)
- ✅ Discussions (for team communication)
- ✅ Sponsorships (for open-source only)

**Pull Requests:**
- ✅ Allow squash merging
- ✅ Allow merge commits (for develop branch)
- ❌ Allow rebase merging (to maintain clear history)
- ✅ Always suggest updating pull request branches
- ✅ Allow auto-merge
- ✅ Automatically delete head branches

**Pushes:**
- ❌ Limit pushes to collaborators (use branch protection instead)

### Security Settings

**Dependency Security:**
- ✅ Dependency graph
- ✅ Dependabot alerts
- ✅ Dependabot security updates
- ✅ Dependabot version updates

**Code Security:**
- ✅ Code scanning (GitHub Advanced Security)
- ✅ Secret scanning
- ✅ Private vulnerability reporting

**Actions:**
- ✅ Allow GitHub Actions
- Select: **Allow select actions and reusable workflows**
- Configure: **Allow actions created by GitHub** and **verified creators**

### Collaboration Settings

**Access Management:**
- Base permissions: **Read** (for most team members)
- Use teams for organized access control
- Require 2FA for organization members

**Team Structure Example:**
```
Organization
├── Maintainers (Admin access)
├── Developers (Write access)
├── Reviewers (Triage access)
└── Viewers (Read access)
```

## Status Checks Configuration

### Required Status Checks

Define status checks that must pass before merging:

**For Main Branch:**
- `CI/CD Pipeline` - Full build and test suite
- `Security Scan` - Security vulnerability scanning
- `SwiftLint` - Code style and quality checks
- `Unit Tests` - All unit tests must pass
- `UI Tests` - Critical UI flows must pass
- `Performance Tests` - Performance regression checks

**For Develop Branch:**
- `Build and Test` - Basic build verification
- `SwiftLint` - Code style checks
- `Unit Tests` - Core functionality tests

**For Feature Branches:**
- `Build Verification` - Ensure code compiles
- `SwiftLint` - Basic style checks

### GitHub Actions Workflows

Configure workflows that provide these status checks:

**`.github/workflows/ci.yml`:**
```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  build-and-test:
    name: Build and Test
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - name: Build and Test
        run: |
          xcodebuild build test

  security-scan:
    name: Security Scan
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4
      - name: Run security scan
        uses: github/super-linter@v4
```

## Team and User Permissions

### Repository Roles

**Admin:**
- Full access to repository
- Can modify settings and protection rules
- Can merge to protected branches

**Maintain:**
- Can manage repository without sensitive actions
- Cannot modify protection rules
- Can merge approved PRs

**Write:**
- Can read and write code
- Can create branches and PRs
- Cannot merge to protected branches without approval

**Triage:**
- Can manage issues and PRs
- Can read code but not write

**Read:**
- Can view and clone repository
- Can create issues and discussions

### Team Assignment

**Maintainers Team:**
- Repository Admins and Senior Developers
- Can bypass some protection rules
- Responsible for releases and critical fixes

**Core Developers Team:**
- Full-time team members
- Write access to repository
- Can approve PRs for develop branch

**Contributors Team:**
- Part-time contributors
- Write access for their own branches
- Need approval for all merges

### External Collaborators

For external contributors:
- Read access initially
- Fork-and-PR workflow
- Require maintainer approval for all changes
- Extra security scanning for external PRs

## Automated Setup

### Repository Setup Script

Create a setup script to automate repository configuration:

**`scripts/setup-repository.sh`:**
```bash
#!/bin/bash

# Repository Setup Script
# Configures branch protection and repository settings

set -e

OWNER="your-org"
REPO="your-repo"

echo "🔧 Setting up repository: $OWNER/$REPO"

# Main branch protection
echo "📝 Configuring main branch protection..."
gh api repos/$OWNER/$REPO/branches/main/protection \
  --method PUT \
  --field required_status_checks='{"strict":true,"contexts":["CI/CD Pipeline","Security Scan","SwiftLint"]}' \
  --field enforce_admins=true \
  --field required_pull_request_reviews='{"dismiss_stale_reviews":true,"require_code_owner_reviews":true,"required_approving_review_count":2}' \
  --field restrictions='{"users":[],"teams":["maintainers"]}'

# Develop branch protection
echo "📝 Configuring develop branch protection..."
gh api repos/$OWNER/$REPO/branches/develop/protection \
  --method PUT \
  --field required_status_checks='{"strict":true,"contexts":["Build and Test","SwiftLint"]}' \
  --field enforce_admins=false \
  --field required_pull_request_reviews='{"required_approving_review_count":1}'

echo "✅ Repository setup completed!"
```

### GitHub Actions Setup

Create workflow files to provide required status checks:

**Basic structure:**
```
.github/
├── workflows/
│   ├── ci.yml          # Main CI/CD pipeline
│   ├── security.yml    # Security scanning
│   └── pr-validation.yml # PR validation checks
└── CODEOWNERS          # Code ownership rules
```

### CODEOWNERS File

Define code owners for automatic review assignments:

**`.github/CODEOWNERS`:**
```
# Global owners
* @maintainers-team

# iOS/Swift specific
*.swift @ios-team
*.xcodeproj @ios-team
*.xcworkspace @ios-team

# Fastlane configuration
fastlane/ @release-team
Fastfile @release-team

# CI/CD
.github/ @devops-team
*.yml @devops-team

# Documentation
*.md @documentation-team
docs/ @documentation-team
```

## Troubleshooting

### Common Issues

#### Status Check Not Required

**Problem:** PR can be merged even though status check failed

**Solution:**
1. Go to **Settings** → **Branches**
2. Edit branch protection rule
3. Ensure status check is listed in "Required status checks"
4. Check "Require branches to be up to date"

#### Cannot Bypass Protection as Admin

**Problem:** Admin cannot merge critical hotfix

**Solution:**
1. Temporarily disable "Restrict pushes to matching branches"
2. Or use "Dismiss stale reviews" and get fresh approval
3. Re-enable protection after merge

#### Status Check Never Completes

**Problem:** Required status check stuck in "Expected" state

**Solution:**
1. Check GitHub Actions workflow logs
2. Verify workflow is triggered by the correct events
3. Ensure workflow name matches required status check name
4. Re-run failed workflows if needed

#### Team Permissions Not Working

**Problem:** Team members cannot perform expected actions

**Solution:**
1. Verify team membership in organization settings
2. Check team permissions on repository
3. Ensure branch protection allows team access
4. Verify organization 2FA requirements are met

### Best Practices

1. **Start with Basic Protection**
   - Implement minimal viable protection first
   - Gradually add more restrictions as needed

2. **Test Protection Rules**
   - Use test repository to verify settings
   - Test with different user permission levels

3. **Monitor and Adjust**
   - Review protection effectiveness regularly
   - Adjust rules based on team feedback

4. **Document Changes**
   - Keep this document updated
   - Communicate changes to team

5. **Backup Configuration**
   - Export settings before major changes
   - Use Infrastructure as Code when possible

### Getting Help

**GitHub Documentation:**
- [Branch Protection Rules](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/defining-the-mergeability-of-pull-requests/about-protected-branches)
- [Repository Settings](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features)
- [GitHub CLI Reference](https://cli.github.com/manual/)

**Team Resources:**
- Ask in team chat for quick questions
- Create GitHub issue for process improvements
- Schedule team discussion for major changes

---

**Last Updated:** $(date)
**Configuration Version:** 1.0.0
**Next Review:** Quarterly

This configuration should be reviewed and updated regularly to ensure it meets the evolving needs of the development team and security requirements.