# Git Branch Strategy and Workflow Guide

This document outlines the Git branching strategy and development workflow for iOS/macOS projects using modern best practices optimized for CI/CD and App Store deployment cycles.

## Table of Contents

- [Overview](#overview)
- [Branch Types](#branch-types)
- [Branching Model Diagram](#branching-model-diagram)
- [Development Workflow](#development-workflow)
- [Common Scenarios](#common-scenarios)
- [Commit Conventions](#commit-conventions)
- [Pull Request Process](#pull-request-process)
- [Release Management](#release-management)
- [Branch Protection Rules](#branch-protection-rules)
- [CI/CD Integration](#cicd-integration)
- [Quick Reference](#quick-reference)
- [Troubleshooting](#troubleshooting)

## Overview

We use a **Git Flow hybrid approach** that combines the structure of Git Flow with the simplicity of GitHub Flow, optimized for iOS/macOS development cycles and App Store requirements.

### Key Principles

- **Main branch** is always production-ready
- **Feature branches** for all new development
- **Release branches** for App Store submissions
- **Hotfix branches** for critical production fixes
- **Linear history** through squash merging
- **Automated testing** and deployment through CI/CD

## Branch Types

### `main` Branch
- **Purpose**: Production-ready code deployed to App Store
- **Protection**: Highly protected, no direct pushes
- **Merges from**: `release/*`, `hotfix/*` branches only
- **Triggers**: Production deployment, App Store release
- **Naming**: Always `main`

### `develop` Branch
- **Purpose**: Integration branch for ongoing development
- **Protection**: Moderate protection, allows direct pushes for integration
- **Merges from**: `feature/*` branches
- **Merges to**: `release/*` branches
- **Triggers**: Staging environment deployment
- **Naming**: Always `develop`

### `feature/*` Branches
- **Purpose**: New feature development and enhancements
- **Protection**: Basic protection, requires PR to merge
- **Branches from**: `develop`
- **Merges to**: `develop`
- **Triggers**: Feature testing workflows
- **Naming**: `feature/description` (e.g., `feature/user-authentication`)

### `release/*` Branches
- **Purpose**: Release preparation and App Store submission
- **Protection**: Moderate protection
- **Branches from**: `develop`
- **Merges to**: `main` and `develop`
- **Triggers**: Release candidate builds, TestFlight deployment
- **Naming**: `release/version` (e.g., `release/1.2.0`)

### `hotfix/*` Branches
- **Purpose**: Critical fixes for production issues
- **Protection**: Fast-track approval process
- **Branches from**: `main`
- **Merges to**: `main` and `develop`
- **Triggers**: Emergency builds, immediate deployment
- **Naming**: `hotfix/description` (e.g., `hotfix/crash-on-launch`)

### `support/*` Branches (Optional)
- **Purpose**: Maintenance of older versions
- **Protection**: Basic protection
- **Branches from**: Specific version tag on `main`
- **Merges to**: Tagged for patch releases
- **Triggers**: Legacy version maintenance builds
- **Naming**: `support/version` (e.g., `support/1.x`)

## Branching Model Diagram

```
main        ●────●────●────●────●────●
            │    │    │    │    │    │
            │    │ ┌──▼──┐ │    │ ┌──▼──┐
release/*   │    │ │ 1.1 │ │    │ │ 1.2 │
            │    │ └──┬──┘ │    │ └──┬──┘
            │    │    │    │    │    │
develop     ●────●────●────●────●────●
            │         │         │
            │    ┌────▼────┐ ┌──▼──┐
feature/*   │    │ auth    │ │ pay │
            │    └─────────┘ └─────┘
            │
hotfix/*    └──● (emergency)
```

## Development Workflow

### Starting New Feature Development

1. **Create feature branch from develop:**
   ```bash
   git checkout develop
   git pull origin develop
   git checkout -b feature/your-feature-name
   ```

2. **Develop and commit changes:**
   ```bash
   # Make your changes
   git add .
   git commit -m "feat: add user authentication system"
   ```

3. **Push and create pull request:**
   ```bash
   git push -u origin feature/your-feature-name
   gh pr create --title "Add user authentication" --body "Description..."
   ```

4. **Merge after approval:**
   - Squash merge into `develop`
   - Delete feature branch after merge

### Preparing a Release

1. **Create release branch from develop:**
   ```bash
   git checkout develop
   git pull origin develop
   git checkout -b release/1.2.0
   ```

2. **Prepare release (version bumps, changelog, etc.):**
   ```bash
   # Update version numbers
   # Update changelog
   # Final testing and bug fixes
   git commit -m "chore: prepare release 1.2.0"
   ```

3. **Create PR to main:**
   ```bash
   git push -u origin release/1.2.0
   gh pr create --base main --title "Release 1.2.0" --body "..."
   ```

4. **After merge to main:**
   - Tag the release: `git tag v1.2.0`
   - Merge back to develop: Create PR `release/1.2.0` → `develop`

### Emergency Hotfix

1. **Create hotfix branch from main:**
   ```bash
   git checkout main
   git pull origin main
   git checkout -b hotfix/critical-crash-fix
   ```

2. **Fix the issue:**
   ```bash
   # Fix the critical issue
   git commit -m "fix: resolve crash on app launch"
   ```

3. **Create PRs to both main and develop:**
   ```bash
   git push -u origin hotfix/critical-crash-fix
   gh pr create --base main --title "Hotfix: Critical crash" --body "..."
   gh pr create --base develop --title "Hotfix: Critical crash" --body "..."
   ```

## Common Scenarios

### Feature Development
```bash
# Start new feature
git checkout develop
git pull origin develop
git checkout -b feature/payment-integration

# Work on feature
git add .
git commit -m "feat: implement payment gateway"
git push -u origin feature/payment-integration

# Create pull request
gh pr create --title "Add payment integration" --body "Implements Apple Pay and credit card payments"
```

### Bug Fix
```bash
# Fix bug in develop
git checkout develop
git pull origin develop
git checkout -b feature/fix-memory-leak

# Fix the bug
git add .
git commit -m "fix: resolve memory leak in image cache"
git push -u origin feature/fix-memory-leak

# Create pull request
gh pr create --title "Fix memory leak" --body "Resolves issue #123"
```

### Release Preparation
```bash
# Create release branch
git checkout develop
git pull origin develop
git checkout -b release/2.0.0

# Prepare release
fastlane bump_version version:2.0.0
git add .
git commit -m "chore: bump version to 2.0.0"

# Push and create PR to main
git push -u origin release/2.0.0
gh pr create --base main --title "Release 2.0.0"
```

## Commit Conventions

We follow [Conventional Commits](https://www.conventionalcommits.org/) specification:

### Format
```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### Types
- **feat**: New feature
- **fix**: Bug fix
- **docs**: Documentation changes
- **style**: Formatting, missing semicolons, etc.
- **refactor**: Code refactoring
- **perf**: Performance improvements
- **test**: Adding or updating tests
- **chore**: Maintenance tasks, dependency updates
- **build**: Build system changes
- **ci**: CI/CD changes

### Examples
```bash
feat: add biometric authentication
fix: resolve crash when loading user profile
docs: update API documentation
style: format code with SwiftLint
refactor: extract networking layer
perf: optimize image loading performance
test: add unit tests for payment processor
chore: update dependencies
build: configure Fastlane for TestFlight
ci: add automated security scanning
```

### Scope Examples (Optional)
```bash
feat(auth): implement OAuth2 login
fix(ui): resolve layout issue on iPad
docs(api): add authentication examples
```

## Pull Request Process

### Creating Pull Requests

1. **Use descriptive titles and descriptions**
2. **Link to related issues**: `Closes #123`
3. **Add screenshots/videos** for UI changes
4. **Update documentation** if needed
5. **Ensure tests pass** before requesting review

### Pull Request Template
```markdown
## Description
Brief description of changes made.

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update
- [ ] Performance improvement
- [ ] Refactoring

## Testing
- [ ] Unit tests added/updated
- [ ] UI tests added/updated
- [ ] Manual testing completed
- [ ] Tested on physical device
- [ ] Tested on different iOS versions

## Screenshots/Videos
(If applicable)

## Checklist
- [ ] Code follows project conventions
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] No console warnings or errors
- [ ] Fastlane builds successfully

## Related Issues
Closes #(issue_number)
```

### Review Guidelines

**For Reviewers:**
- Check code quality and conventions
- Verify functionality and edge cases
- Test on physical devices when possible
- Provide constructive feedback
- Approve when satisfied with changes

**For Authors:**
- Respond to all review comments
- Make requested changes promptly
- Re-request review after updates
- Thank reviewers for their time

## Release Management

### Version Numbering
We use [Semantic Versioning](https://semver.org/): `MAJOR.MINOR.PATCH`

- **MAJOR**: Breaking changes, major UI overhauls
- **MINOR**: New features, significant enhancements
- **PATCH**: Bug fixes, small improvements

### Release Process

1. **Feature Freeze**: Stop merging new features to `develop`
2. **Create Release Branch**: `release/X.Y.Z` from `develop`
3. **Release Testing**: QA testing, bug fixes in release branch
4. **Version Finalization**: Update version numbers, changelog
5. **Merge to Main**: Create PR to `main` for production
6. **Tag Release**: Create Git tag and GitHub release
7. **Deploy**: Fastlane deployment to App Store
8. **Backport**: Merge release branch back to `develop`

### Release Checklist
- [ ] All features tested and approved
- [ ] Version numbers updated in project
- [ ] Changelog updated with release notes
- [ ] Release notes prepared for App Store
- [ ] TestFlight build tested by team
- [ ] App Store metadata updated
- [ ] Release branch merged to main
- [ ] Git tag created: `v1.2.0`
- [ ] GitHub release published
- [ ] Changes merged back to develop

## Branch Protection Rules

### Main Branch
```json
{
  "required_status_checks": {
    "strict": true,
    "contexts": ["CI/CD Pipeline", "Security Scan", "Code Quality"]
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
  "allow_squash_merge": true,
  "allow_merge_commit": false,
  "allow_rebase_merge": false
}
```

### Develop Branch
```json
{
  "required_status_checks": {
    "strict": true,
    "contexts": ["Build and Test", "SwiftLint"]
  },
  "enforce_admins": false,
  "required_pull_request_reviews": {
    "dismiss_stale_reviews": false,
    "require_code_owner_reviews": false,
    "required_approving_review_count": 1
  },
  "allow_squash_merge": true,
  "allow_merge_commit": true,
  "allow_rebase_merge": true
}
```

### Feature Branches
- No protection rules (developers can push directly)
- Must create PR to merge to `develop`
- Require passing CI checks

## CI/CD Integration

### Workflow Triggers

**On Push to Main:**
- Full test suite
- Security scanning
- Production build
- App Store deployment (manual approval)

**On Push to Develop:**
- Build and test
- Deploy to staging
- Update TestFlight build

**On Pull Request:**
- Build validation
- Unit and UI tests
- SwiftLint checks
- Security vulnerability scan

**On Release Tag:**
- Create GitHub release
- Deploy to App Store
- Update changelog

### Required Status Checks

**All Branches:**
- ✅ Build Success
- ✅ Unit Tests Pass
- ✅ SwiftLint Clean

**Main Branch Additional:**
- ✅ Security Scan Clean
- ✅ UI Tests Pass
- ✅ Performance Tests Pass
- ✅ Manual QA Approval

## Quick Reference

### Common Commands

**Start new feature:**
```bash
git checkout develop && git pull && git checkout -b feature/my-feature
```

**Update feature branch:**
```bash
git checkout feature/my-feature && git merge develop
```

**Create release:**
```bash
git checkout develop && git pull && git checkout -b release/1.0.0
```

**Emergency hotfix:**
```bash
git checkout main && git pull && git checkout -b hotfix/urgent-fix
```

**Clean up merged branches:**
```bash
git branch --merged | grep -v "main\|develop" | xargs -n 1 git branch -d
```

### Branch Naming Conventions

- `feature/short-description`
- `feature/issue-123-description`
- `release/1.2.0`
- `hotfix/critical-fix`
- `hotfix/issue-456-crash`
- `support/1.x`

### Commit Message Examples

```bash
feat: add Dark Mode support
feat(ui): implement custom navigation bar
fix: resolve memory leak in CoreData stack
fix(auth): handle expired token gracefully
docs: update installation instructions
style: apply SwiftLint formatting
refactor: extract networking into separate module
perf: optimize image caching mechanism
test: add unit tests for user authentication
chore: update CocoaPods dependencies
build: configure Fastlane for automated builds
ci: add GitHub Actions for automated testing
```

## Troubleshooting

### Common Issues

#### Merge Conflicts
```bash
# Update your branch with latest changes
git checkout feature/my-feature
git fetch origin
git merge origin/develop

# Resolve conflicts in Xcode or text editor
# After resolving:
git add .
git commit -m "resolve: merge conflicts with develop"
```

#### Accidentally Committed to Wrong Branch
```bash
# If you haven't pushed yet
git reset --soft HEAD~1  # Uncommit but keep changes
git stash                # Stash changes
git checkout correct-branch
git stash pop           # Apply changes to correct branch
```

#### Need to Update Pull Request
```bash
# Make additional changes
git add .
git commit -m "address: review feedback"
git push origin feature/my-feature
# PR automatically updates
```

#### Branch Diverged from Origin
```bash
# Force update local branch to match origin
git fetch origin
git reset --hard origin/feature/my-feature
```

### Getting Help

1. **Check this documentation** for workflow guidance
2. **Ask in team chat** for quick questions
3. **Create GitHub issue** for process improvements
4. **Review Git documentation** for advanced scenarios

### Emergency Procedures

#### Critical Production Bug
1. Immediately create `hotfix/*` branch from `main`
2. Fix the critical issue
3. Create PR with "HOTFIX" label for fast-track review
4. Deploy as soon as PR is approved
5. Follow up with incident post-mortem

#### Broken Main Branch
1. Identify the problematic commit
2. Create revert PR immediately
3. Deploy reverted version
4. Fix issues in separate feature branch
5. Re-deploy when fix is verified

---

## Contributing to This Document

This branch strategy documentation should evolve with the team and project needs. To suggest improvements:

1. Create feature branch: `feature/update-branch-strategy`
2. Make your changes to this document
3. Create pull request with clear rationale
4. Discuss with team before merging

For questions or clarifications, please create an issue or reach out to the development team.

---

**Last Updated**: $(date)
**Document Version**: 1.0.0
**Review Schedule**: Quarterly