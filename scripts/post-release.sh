#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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
    echo -e "${BLUE}ℹ️${NC} $1"
}

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    print_error "Not in a git repository"
    exit 1
fi

print_status "Starting post-release tasks..."

# Get current branch and latest tag
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
LATEST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")

if [ -z "$LATEST_TAG" ]; then
    print_error "No release tag found. Did the release process complete?"
    exit 1
fi

RELEASE_VERSION=$(echo "$LATEST_TAG" | sed 's/^v//')
print_status "Processing post-release tasks for version $RELEASE_VERSION (tag: $LATEST_TAG)"

# Check if release was successful by looking for the tag
if ! git rev-parse "$LATEST_TAG" >/dev/null 2>&1; then
    print_error "Release tag $LATEST_TAG not found. Release may not have completed successfully."
    exit 1
fi

print_success "Release tag $LATEST_TAG found"

# Ensure we're on the main branch for post-release tasks
if [ "$CURRENT_BRANCH" != "main" ]; then
    print_status "Switching to main branch..."
    git checkout main
    git pull origin main
    print_success "Switched to main branch"
fi

# Check if release branch exists and clean it up
RELEASE_BRANCH="release/$RELEASE_VERSION"
if git rev-parse --verify "$RELEASE_BRANCH" >/dev/null 2>&1; then
    print_status "Cleaning up release branch: $RELEASE_BRANCH"

    # Delete local release branch
    git branch -D "$RELEASE_BRANCH" 2>/dev/null || true

    # Delete remote release branch
    git push origin --delete "$RELEASE_BRANCH" 2>/dev/null || true

    print_success "Release branch $RELEASE_BRANCH cleaned up"
else
    print_info "Release branch $RELEASE_BRANCH not found (may have been cleaned up already)"
fi

# Update develop branch with main branch changes
if git rev-parse --verify develop >/dev/null 2>&1; then
    print_status "Updating develop branch with main branch changes..."

    # Switch to develop branch
    git checkout develop
    git pull origin develop

    # Merge main into develop
    if git merge main --no-ff -m "Merge main into develop after release $RELEASE_VERSION"; then
        print_success "Merged main into develop"

        # Push updated develop branch
        git push origin develop
        print_success "Pushed updated develop branch"
    else
        print_warning "Merge conflicts detected when merging main into develop"
        print_info "Please resolve conflicts manually and run:"
        print_info "  git add ."
        print_info "  git commit -m 'Resolve merge conflicts after release $RELEASE_VERSION'"
        print_info "  git push origin develop"
    fi

    # Switch back to main
    git checkout main
else
    print_info "Develop branch not found - skipping develop branch update"
fi

# Generate release report
print_status "Generating release report..."
RELEASE_REPORT_FILE="release-report-$RELEASE_VERSION.md"

cat > "$RELEASE_REPORT_FILE" << EOF
# Release Report - Version $RELEASE_VERSION

**Release Date:** $(date)
**Release Tag:** $LATEST_TAG
**Branch:** main

## Release Summary

### Version Information
- Previous Version: $(git describe --tags --abbrev=0 "$LATEST_TAG^" 2>/dev/null || echo "N/A")
- Current Version: $RELEASE_VERSION
- Release Tag: $LATEST_TAG

### Git Information
- Release Commit: $(git rev-parse $LATEST_TAG)
- Total Commits: $(git rev-list --count $LATEST_TAG)
- Contributors: $(git shortlog -sn $LATEST_TAG | wc -l | xargs)

## Changes Since Last Release

### Commits
$(git log --oneline $(git describe --tags --abbrev=0 "$LATEST_TAG^" 2>/dev/null || echo "HEAD~10")...$LATEST_TAG 2>/dev/null || echo "Recent commits:")

### Files Changed
$(git diff --name-only $(git describe --tags --abbrev=0 "$LATEST_TAG^" 2>/dev/null || echo "HEAD~10")...$LATEST_TAG 2>/dev/null | head -20 || echo "File changes not available")

## Deployment Status

### Automated Deployments
- [ ] GitHub Release Created
- [ ] TestFlight Upload (iOS)
- [ ] TestFlight Upload (macOS)
- [ ] App Store Submission
- [ ] Documentation Updated

### Manual Verification Required
- [ ] TestFlight builds are processing correctly
- [ ] App Store Connect metadata is accurate
- [ ] Release notes are published
- [ ] Team notifications sent
- [ ] Customer communication sent (if applicable)

## Quality Metrics

### Build Information
- Build Status: $(gh run list --workflow=release.yml --limit=1 --json conclusion --jq '.[0].conclusion' 2>/dev/null || echo "Unknown")
- Test Results: $(gh run list --workflow=ci.yml --limit=1 --json conclusion --jq '.[0].conclusion' 2>/dev/null || echo "Unknown")

### Code Quality
- Total Lines of Code: $(find . -name "*.swift" -not -path "./build/*" -not -path "./.build/*" | xargs wc -l | tail -1 | awk '{print $1}' || echo "N/A")
- Swift Files: $(find . -name "*.swift" -not -path "./build/*" -not -path "./.build/*" | wc -l | xargs || echo "N/A")

## Post-Release Tasks

### Completed ✅
- [x] Release tag created and pushed
- [x] Main branch updated
- [x] Release branch cleaned up
- [x] Develop branch updated (if exists)

### Pending Actions 📋
- [ ] Monitor crash reports and user feedback
- [ ] Update documentation and tutorials
- [ ] Announce release on social media
- [ ] Update website with new features
- [ ] Plan next release cycle

## Issues and Resolutions

### Known Issues
- None reported at release time

### Rollback Plan
If critical issues are discovered:
1. Remove app from sale in App Store Connect
2. Create hotfix branch: \`git checkout -b hotfix/$RELEASE_VERSION.1 $LATEST_TAG\`
3. Apply critical fixes
4. Deploy hotfix following emergency release process

## Next Release

### Planned Features
- Review backlog for next release
- Schedule feature planning meeting
- Update roadmap based on release feedback

### Timeline
- Next release target: [Date to be determined]
- Feature freeze: [Date to be determined]
- Beta testing period: [Duration to be determined]

---

**Generated:** $(date)
**Report Version:** 1.0
EOF

print_success "Release report generated: $RELEASE_REPORT_FILE"

# Check release deployment status
print_status "Checking release deployment status..."

# Check GitHub release
if command -v gh &> /dev/null; then
    if gh release view "$LATEST_TAG" >/dev/null 2>&1; then
        print_success "GitHub release $LATEST_TAG is published"

        # Get release URL
        RELEASE_URL=$(gh release view "$LATEST_TAG" --json url --jq '.url')
        print_info "Release URL: $RELEASE_URL"
    else
        print_warning "GitHub release $LATEST_TAG not found - may still be processing"
    fi
else
    print_warning "GitHub CLI not available - cannot check release status"
fi

# Check if GitHub Actions workflow is running
if command -v gh &> /dev/null; then
    print_status "Checking GitHub Actions status..."

    # Get latest workflow run
    WORKFLOW_STATUS=$(gh run list --workflow=release.yml --limit=1 --json status,conclusion --jq '.[0].status' 2>/dev/null || echo "unknown")

    if [ "$WORKFLOW_STATUS" = "completed" ]; then
        WORKFLOW_CONCLUSION=$(gh run list --workflow=release.yml --limit=1 --json conclusion --jq '.[0].conclusion')
        if [ "$WORKFLOW_CONCLUSION" = "success" ]; then
            print_success "Release workflow completed successfully"
        else
            print_warning "Release workflow completed with status: $WORKFLOW_CONCLUSION"
        fi
    elif [ "$WORKFLOW_STATUS" = "in_progress" ]; then
        print_info "Release workflow is still running..."
        print_info "Monitor progress: gh run list --workflow=release.yml"
    else
        print_warning "Release workflow status: $WORKFLOW_STATUS"
    fi
fi

# Archive release notes and cleanup temporary files
print_status "Archiving release documentation..."

# Create releases directory if it doesn't exist
mkdir -p releases

# Move release documentation to releases directory
if [ -f "release-notes-$RELEASE_VERSION.md" ]; then
    mv "release-notes-$RELEASE_VERSION.md" "releases/"
    print_success "Archived release notes to releases/"
fi

mv "$RELEASE_REPORT_FILE" "releases/"
print_success "Archived release report to releases/"

# Update any version tracking files
if [ -f ".version" ]; then
    echo "$RELEASE_VERSION" > .version
    git add .version
    git commit -m "Update version tracker to $RELEASE_VERSION"
    git push origin main
    print_success "Updated version tracker"
fi

# Send notifications (if configured)
print_status "Sending post-release notifications..."

# Slack notification (if webhook is configured)
if [ -n "${SLACK_WEBHOOK_URL:-}" ]; then
    print_status "Sending Slack notification..."

    SLACK_MESSAGE="{
        \"text\": \"🎉 Release $RELEASE_VERSION Post-Processing Complete!\",
        \"attachments\": [
            {
                \"color\": \"good\",
                \"fields\": [
                    {
                        \"title\": \"Version\",
                        \"value\": \"$RELEASE_VERSION\",
                        \"short\": true
                    },
                    {
                        \"title\": \"Tag\",
                        \"value\": \"$LATEST_TAG\",
                        \"short\": true
                    },
                    {
                        \"title\": \"Status\",
                        \"value\": \"Post-release tasks completed\",
                        \"short\": false
                    }
                ]
            }
        ]
    }"

    if curl -X POST -H 'Content-type: application/json' \
        --data "$SLACK_MESSAGE" \
        "$SLACK_WEBHOOK_URL" >/dev/null 2>&1; then
        print_success "Slack notification sent"
    else
        print_warning "Failed to send Slack notification"
    fi
else
    print_info "SLACK_WEBHOOK_URL not configured - skipping Slack notification"
fi

# Email notification (if configured)
if [ -n "${RELEASE_EMAIL_LIST:-}" ] && command -v mail &> /dev/null; then
    print_status "Sending email notification..."

    EMAIL_SUBJECT="Release $RELEASE_VERSION - Post-Processing Complete"
    EMAIL_BODY="
Release $RELEASE_VERSION post-processing has been completed successfully.

Release Details:
- Version: $RELEASE_VERSION
- Tag: $LATEST_TAG
- Date: $(date)

Post-Release Tasks Completed:
✅ Release branch cleaned up
✅ Develop branch updated
✅ Release documentation archived
✅ Version tracking updated

Next Steps:
- Monitor app performance and user feedback
- Plan next release cycle
- Update project roadmap

For detailed information, see the release report in the releases/ directory.
"

    echo "$EMAIL_BODY" | mail -s "$EMAIL_SUBJECT" "$RELEASE_EMAIL_LIST" && \
        print_success "Email notification sent" || \
        print_warning "Failed to send email notification"
else
    print_info "Email notifications not configured - skipping"
fi

# Generate summary metrics
print_status "Collecting release metrics..."

# Time since last release
PREVIOUS_TAG=$(git describe --tags --abbrev=0 "$LATEST_TAG^" 2>/dev/null || echo "")
if [ -n "$PREVIOUS_TAG" ]; then
    DAYS_SINCE_LAST_RELEASE=$(( ($(git log -1 --format=%ct "$LATEST_TAG") - $(git log -1 --format=%ct "$PREVIOUS_TAG")) / 86400 ))
    print_info "Days since last release: $DAYS_SINCE_LAST_RELEASE"
fi

# Commit count since last release
if [ -n "$PREVIOUS_TAG" ]; then
    COMMITS_SINCE_LAST=$(git rev-list --count "$PREVIOUS_TAG..$LATEST_TAG")
    print_info "Commits in this release: $COMMITS_SINCE_LAST"
fi

# Contributors count
CONTRIBUTORS=$(git shortlog -sn "$LATEST_TAG" | wc -l | xargs)
print_info "Total contributors: $CONTRIBUTORS"

echo
print_success "🎉 Post-release processing completed successfully!"

# Final summary
echo
echo "=== POST-RELEASE SUMMARY ==="
echo "✅ Release version: $RELEASE_VERSION"
echo "✅ Release tag: $LATEST_TAG"
echo "✅ Release branch cleaned up"
echo "✅ Develop branch updated"
echo "✅ Documentation archived"
echo "✅ Notifications sent"
echo

echo "=== NEXT STEPS ==="
echo "1. Monitor app performance and crash reports"
echo "2. Review user feedback and App Store reviews"
echo "3. Plan next release based on roadmap"
echo "4. Update documentation and marketing materials"
echo "5. Announce release through appropriate channels"
echo

echo "=== MONITORING RESOURCES ==="
echo "• GitHub Release: https://github.com/$(git config --get remote.origin.url | sed 's/.*github.com[:/]\([^.]*\).*/\1/')/releases/tag/$LATEST_TAG"
echo "• App Store Connect: https://appstoreconnect.apple.com"
echo "• TestFlight: https://appstoreconnect.apple.com/apps"
echo "• Analytics: Check your preferred analytics platform"
echo

echo "=== ARCHIVED DOCUMENTATION ==="
echo "• Release report: releases/$RELEASE_REPORT_FILE"
if [ -f "releases/release-notes-$RELEASE_VERSION.md" ]; then
    echo "• Release notes: releases/release-notes-$RELEASE_VERSION.md"
fi
echo

print_success "Post-release tasks completed! 🚀"

# Optional: Open release report for review
if command -v open &> /dev/null && [ -f "releases/release-report-$RELEASE_VERSION.md" ]; then
    read -p "Open release report for review? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        open "releases/release-report-$RELEASE_VERSION.md"
    fi
fi