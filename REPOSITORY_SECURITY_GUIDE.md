# GitHub Repository Settings and Security Configuration Guide

## Table of Contents

- [Overview](#overview)
- [Repository General Settings](#repository-general-settings)
- [Security Configuration](#security-configuration)
- [Access Control and Permissions](#access-control-and-permissions)
- [Integration Settings](#integration-settings)
- [Compliance and Governance](#compliance-and-governance)
- [Monitoring and Maintenance](#monitoring-and-maintenance)
- [Automated Setup](#automated-setup)
- [Best Practices](#best-practices)

## Overview

This guide provides comprehensive instructions for configuring GitHub repository settings and security features to establish a secure, well-managed development environment for iOS and macOS projects.

### Security Layers

Our security approach implements multiple layers:

```
┌─────────────────────────────────────────┐
│           User Authentication           │
│        (2FA, SSO, Access Tokens)       │
├─────────────────────────────────────────┤
│         Repository Permissions         │
│      (Teams, Roles, Collaborators)     │
├─────────────────────────────────────────┤
│         Branch Protection Rules        │
│    (Reviews, Status Checks, Policies)  │
├─────────────────────────────────────────┤
│           Code Security Scanning       │
│  (Secret Scanning, Code Analysis, CVE) │
├─────────────────────────────────────────┤
│         Dependency Management          │
│   (Vulnerability Alerts, Auto-Updates) │
├─────────────────────────────────────────┤
│         Audit and Monitoring           │
│    (Logs, Alerts, Compliance Reports)  │
└─────────────────────────────────────────┘
```

## Repository General Settings

### Basic Repository Configuration

#### Repository Visibility and Access

**For Private Repositories (Recommended for Enterprise):**
```bash
# Set repository visibility
gh repo edit --visibility private

# Configure base permissions
gh api repos/:owner/:repo --method PATCH \
  --field default_branch=main \
  --field description="iOS/macOS Template Repository" \
  --field homepage="https://your-company.com" \
  --field topics='["ios","macos","swift","template","mobile"]'
```

**Repository Features Configuration:**
- ✅ **Issues**: Enable for bug tracking and feature requests
- ✅ **Projects**: Enable for project management (if using GitHub Projects)
- ✅ **Discussions**: Enable for team communication and Q&A
- ❌ **Wiki**: Disable (use docs/ directory instead for better version control)
- ✅ **Sponsorships**: Enable for open-source projects only

#### Merge and Branch Policies

```bash
# Configure merge settings
gh api repos/:owner/:repo --method PATCH \
  --field allow_squash_merge=true \
  --field allow_merge_commit=false \
  --field allow_rebase_merge=false \
  --field allow_auto_merge=true \
  --field delete_branch_on_merge=true \
  --field allow_update_branch=true \
  --field squash_merge_commit_title="PR_TITLE" \
  --field squash_merge_commit_message="PR_BODY"
```

**Merge Strategy Rationale:**
- **Squash Merge Only**: Maintains clean commit history
- **Auto-delete Branches**: Reduces repository clutter
- **Auto-update Branches**: Keeps PRs current with base branch

### Repository Metadata and Organization

#### Topics and Labels
```bash
# Set repository topics
gh repo edit --add-topic ios
gh repo edit --add-topic macos
gh repo edit --add-topic swift
gh repo edit --add-topic template
gh repo edit --add-topic mobile-development
gh repo edit --add-topic xcode
gh repo edit --add-topic fastlane
```

#### Custom Labels for Issues and PRs
```bash
# Create custom labels
gh label create "🐛 bug" --description "Something isn't working" --color "d73a4a"
gh label create "✨ enhancement" --description "New feature or request" --color "a2eeef"
gh label create "🔒 security" --description "Security-related issue" --color "b60205"
gh label create "📱 ios" --description "iOS-specific issue" --color "1d76db"
gh label create "💻 macos" --description "macOS-specific issue" --color "0052cc"
gh label create "🚀 release" --description "Release-related issue" --color "0e8a16"
gh label create "📚 documentation" --description "Documentation update" --color "0075ca"
gh label create "🧪 testing" --description "Testing-related issue" --color "fbca04"
gh label create "🔧 ci/cd" --description "CI/CD pipeline issue" --color "d4c5f9"
gh label create "❓ question" --description "Further information is requested" --color "d876e3"
```

## Security Configuration

### GitHub Security Features

#### Enable Core Security Features
```bash
# Enable vulnerability alerts
gh api repos/:owner/:repo/vulnerability-alerts --method PUT

# Enable automated security fixes (Dependabot)
gh api repos/:owner/:repo/automated-security-fixes --method PUT

# Configure Dependabot version updates
cat > .github/dependabot.yml << 'EOF'
version: 2
updates:
  # Swift Package Manager
  - package-ecosystem: "swift"
    directory: "/"
    schedule:
      interval: "weekly"
      day: "monday"
      time: "09:00"
    open-pull-requests-limit: 10
    reviewers:
      - "@maintainers-team"
    assignees:
      - "@ios-team"
    commit-message:
      prefix: "deps"
      include: "scope"

  # GitHub Actions
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
      day: "monday"
      time: "09:00"
    open-pull-requests-limit: 5
    reviewers:
      - "@devops-team"

  # Ruby (for Fastlane)
  - package-ecosystem: "bundler"
    directory: "/"
    schedule:
      interval: "weekly"
    reviewers:
      - "@release-team"
EOF
```

#### Advanced Security Features (Requires GitHub Advanced Security)

**Secret Scanning:**
```bash
# Enable secret scanning (requires Advanced Security license)
gh api repos/:owner/:repo/secret-scanning/alerts --method GET

# Configure secret scanning push protection
gh api repos/:owner/:repo/secret-scanning/push-protection --method PUT
```

**Code Scanning with CodeQL:**
```yaml
# .github/workflows/codeql.yml
name: CodeQL Analysis

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]
  schedule:
    - cron: '0 2 * * 1'  # Weekly on Monday at 2 AM

jobs:
  analyze:
    name: Analyze
    runs-on: ubuntu-latest
    permissions:
      actions: read
      contents: read
      security-events: write

    strategy:
      fail-fast: false
      matrix:
        language: ['swift', 'javascript']  # Add languages as needed

    steps:
    - name: Checkout repository
      uses: actions/checkout@v4

    - name: Initialize CodeQL
      uses: github/codeql-action/init@v2
      with:
        languages: ${{ matrix.language }}

    - name: Autobuild
      uses: github/codeql-action/autobuild@v2

    - name: Perform CodeQL Analysis
      uses: github/codeql-action/analyze@v2
```

### Security Policies and Documentation

#### Create Security Policy
```markdown
# .github/SECURITY.md
# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 2.x.x   | ✅                |
| 1.9.x   | ✅ (Security fixes only) |
| < 1.9   | ❌                |

## Reporting a Vulnerability

**⚠️ Please do not report security vulnerabilities through public GitHub issues.**

### Preferred Reporting Methods

1. **GitHub Security Advisories** (Recommended)
   - Go to the Security tab
   - Click "Report a vulnerability"
   - Fill out the vulnerability report form

2. **Email**
   - Send details to: security@yourcompany.com
   - Use PGP encryption if possible

### Response Timeline

- **Acknowledgment**: Within 24-48 hours
- **Initial Assessment**: Within 5 business days
- **Resolution**: Varies by severity (24 hours - 4 weeks)

## Security Best Practices

- Keep your dependencies up to date
- Use strong authentication (2FA)
- Follow secure coding practices
- Report suspicious activity
```

## Access Control and Permissions

### Team Structure and Permissions

#### Recommended Team Structure
```
Organization Teams:
├── @maintainers-team (Admin)
│   ├── Repository owners
│   ├── Senior developers
│   └── Technical leads
├── @ios-team (Write)
│   ├── iOS developers
│   ├── Mobile specialists
│   └── UI/UX developers
├── @devops-team (Write)
│   ├── DevOps engineers
│   ├── CI/CD specialists
│   └── Infrastructure team
├── @qa-team (Write)
│   ├── Quality assurance engineers
│   ├── Test automation specialists
│   └── Manual testers
├── @documentation-team (Write)
│   ├── Technical writers
│   ├── Developer advocates
│   └── Product managers
└── @external-contributors (Read)
    ├── Open-source contributors
    ├── Contractors
    └── Interns
```

#### Permission Configuration
```bash
# Configure team permissions
gh api repos/:owner/:repo/teams/maintainers-team/permission \
  --method PUT --field permission=admin

gh api repos/:owner/:repo/teams/ios-team/permission \
  --method PUT --field permission=push

gh api repos/:owner/:repo/teams/devops-team/permission \
  --method PUT --field permission=push

gh api repos/:owner/:repo/teams/qa-team/permission \
  --method PUT --field permission=push

gh api repos/:owner/:repo/teams/documentation-team/permission \
  --method PUT --field permission=push

gh api repos/:owner/:repo/teams/external-contributors/permission \
  --method PUT --field permission=pull
```

### Individual Collaborator Management

#### Adding Collaborators
```bash
# Add individual collaborator
gh repo add-collaborator username --permission write

# List collaborators
gh api repos/:owner/:repo/collaborators

# Remove collaborator
gh repo remove-collaborator username
```

#### External Contributor Workflow
1. **Fork-and-PR Model**: External contributors must fork and submit PRs
2. **Required Reviews**: All external PRs require maintainer approval
3. **Security Scanning**: Extra security checks for external contributions
4. **Limited Access**: No direct push access to main repository

## Integration Settings

### GitHub Actions Security

#### Actions Permissions
```bash
# Configure Actions permissions
gh api repos/:owner/:repo --method PATCH \
  --field allow_forked_pull_requests_to_run_workflows=false \
  --field allow_actions_to_approve_pull_requests=false
```

#### Workflow Security Configuration
```yaml
# .github/workflows/security-policy.yml
name: Security Policy Enforcement

on:
  pull_request:
    types: [opened, synchronize]

jobs:
  security-check:
    if: github.actor != 'dependabot[bot]'
    runs-on: ubuntu-latest
    steps:
    - name: Check PR author
      run: |
        if [[ "${{ github.event.pull_request.head.repo.full_name }}" != "${{ github.repository }}" ]]; then
          echo "External PR detected - requires manual review"
          exit 1
        fi

  dependabot-auto-merge:
    if: github.actor == 'dependabot[bot]'
    runs-on: ubuntu-latest
    steps:
    - name: Auto-approve Dependabot PRs
      run: gh pr review --approve "$PR_URL"
      env:
        PR_URL: ${{ github.event.pull_request.html_url }}
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### Webhook and App Security

#### Webhook Configuration
```bash
# List webhooks
gh api repos/:owner/:repo/hooks

# Configure webhook with secret
gh api repos/:owner/:repo/hooks --method POST \
  --field name=web \
  --field active=true \
  --field config='{"url":"https://your-server.com/webhook","content_type":"json","secret":"your-webhook-secret"}' \
  --field events='["push","pull_request","release"]'
```

#### GitHub App Security
- Use GitHub Apps instead of personal access tokens when possible
- Limit app permissions to minimum required scope
- Regularly audit app installations and permissions
- Use short-lived tokens where possible

## Compliance and Governance

### Audit Logging and Monitoring

#### Enable Audit Features
```bash
# View organization audit log (requires org admin)
gh api orgs/:org/audit-log

# Repository-specific events
gh api repos/:owner/:repo/events
```

#### Compliance Documentation
```markdown
# COMPLIANCE.md
# Compliance and Governance

## Security Standards
- SOC 2 Type II compliance
- GDPR compliance for EU users
- Regular security audits and penetration testing

## Data Protection
- Encryption in transit and at rest
- Regular data backups
- Data retention policies
- User privacy protection

## Development Standards
- Code review requirements
- Security testing integration
- Dependency vulnerability management
- Regular security training
```

### Legal and Licensing

#### License Management
```markdown
# LICENSE
MIT License

Copyright (c) 2024 Your Company Name

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## Monitoring and Maintenance

### Regular Security Reviews

#### Monthly Security Checklist
- [ ] Review and rotate access tokens
- [ ] Audit team permissions and memberships
- [ ] Check for unused collaborators
- [ ] Review security alerts and vulnerabilities
- [ ] Update security policies if needed
- [ ] Review branch protection rules
- [ ] Audit webhook and app permissions

#### Quarterly Security Assessment
- [ ] Comprehensive permission audit
- [ ] Security policy review and updates
- [ ] Team structure evaluation
- [ ] Compliance documentation updates
- [ ] Security training needs assessment
- [ ] Incident response plan testing

### Automated Monitoring

#### Security Metrics Dashboard
```yaml
# .github/workflows/security-metrics.yml
name: Security Metrics

on:
  schedule:
    - cron: '0 9 * * 1'  # Weekly on Monday

jobs:
  security-report:
    runs-on: ubuntu-latest
    steps:
    - name: Generate Security Report
      run: |
        echo "# Weekly Security Report" > security-report.md
        echo "Generated: $(date)" >> security-report.md

        # Vulnerability alerts
        gh api repos/:owner/:repo/vulnerability-alerts --jq '.[] | length' >> security-report.md

        # Dependabot alerts
        gh api repos/:owner/:repo/dependabot/alerts --jq '.[] | length' >> security-report.md

        # Secret scanning alerts
        gh api repos/:owner/:repo/secret-scanning/alerts --jq '.[] | length' >> security-report.md

    - name: Create Issue
      run: |
        gh issue create \
          --title "Weekly Security Report - $(date +%Y-%m-%d)" \
          --body-file security-report.md \
          --assignee @maintainers-team
```

### Incident Response

#### Security Incident Workflow
1. **Detection**: Automated alerts or manual reporting
2. **Assessment**: Evaluate severity and scope
3. **Response**: Immediate containment actions
4. **Recovery**: Fix and deploy solutions
5. **Review**: Post-incident analysis and improvements

#### Emergency Procedures
```bash
# Emergency repository lockdown
gh api repos/:owner/:repo --method PATCH \
  --field archived=true \
  --field disabled=true

# Revoke all access tokens (organization level)
gh auth refresh --scopes admin:org

# Emergency branch protection
gh api repos/:owner/:repo/branches/main/protection \
  --method PUT \
  --field restrictions='{"users":[],"teams":[]}'
```

## Automated Setup

### Repository Configuration Script

The `scripts/setup-repository.sh` script automates most of these configurations:

```bash
# Run with dry-run first
./scripts/setup-repository.sh --dry-run

# Apply configuration
./scripts/setup-repository.sh

# Main branch only (for existing repositories)
./scripts/setup-repository.sh --main-only
```

### Configuration Validation

#### Validation Script
```bash
#!/bin/bash
# scripts/validate-security.sh

echo "🔒 Validating repository security configuration..."

# Check branch protection
if gh api repos/:owner/:repo/branches/main/protection >/dev/null 2>&1; then
    echo "✅ Main branch protection enabled"
else
    echo "❌ Main branch protection missing"
fi

# Check security features
if gh api repos/:owner/:repo/vulnerability-alerts >/dev/null 2>&1; then
    echo "✅ Vulnerability alerts enabled"
else
    echo "❌ Vulnerability alerts disabled"
fi

# Check required files
for file in SECURITY.md .github/CODEOWNERS LICENSE; do
    if [ -f "$file" ]; then
        echo "✅ $file exists"
    else
        echo "❌ $file missing"
    fi
done

echo "🔒 Security validation completed"
```

## Best Practices

### Security-First Development

1. **Principle of Least Privilege**
   - Grant minimum necessary permissions
   - Regular permission audits
   - Time-limited access when possible

2. **Defense in Depth**
   - Multiple security layers
   - Redundant protection mechanisms
   - Fail-safe defaults

3. **Regular Updates and Patches**
   - Automated dependency updates
   - Regular security reviews
   - Prompt vulnerability response

### Team Security Practices

#### Developer Security Guidelines
- Enable 2FA on all accounts
- Use signed commits for critical changes
- Follow secure coding practices
- Report security issues promptly
- Keep development environment secure

#### Code Review Security
- Security-focused code reviews
- Automated security scanning
- Secret detection before commits
- Regular security training

### Continuous Improvement

#### Security Metrics to Track
- Time to fix vulnerabilities
- Number of security incidents
- Code review coverage
- Security training completion
- Compliance audit results

#### Regular Security Activities
- **Weekly**: Review security alerts
- **Monthly**: Permission audits
- **Quarterly**: Comprehensive security review
- **Annually**: Third-party security audit

---

## Quick Setup Checklist

### Initial Setup (One-time)
- [ ] Run `./scripts/setup-repository.sh`
- [ ] Configure team permissions
- [ ] Enable security features
- [ ] Create security policies
- [ ] Set up monitoring

### Regular Maintenance (Ongoing)
- [ ] Review security alerts weekly
- [ ] Update access permissions monthly
- [ ] Conduct quarterly security audits
- [ ] Refresh security training annually

### Emergency Procedures
- [ ] Document incident response process
- [ ] Test emergency lockdown procedures
- [ ] Maintain emergency contact list
- [ ] Regular incident response drills

This comprehensive security configuration ensures your iOS/macOS development repository meets enterprise security standards while maintaining developer productivity and workflow efficiency.