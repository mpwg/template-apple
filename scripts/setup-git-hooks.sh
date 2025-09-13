#!/bin/bash

# Git Hooks Setup Script
# This script sets up pre-commit and pre-push hooks for SwiftLint and SwiftFormat

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "\n${BLUE}================================${NC}"
    echo -e "${BLUE}🪝 Git Hooks Setup${NC}"
    echo -e "${BLUE}================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

check_requirements() {
    print_info "Checking requirements..."

    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        print_error "Not in a Git repository!"
        exit 1
    fi

    # Check if SwiftLint is installed
    if ! command -v swiftlint &> /dev/null; then
        print_warning "SwiftLint is not installed. Installing via Homebrew..."
        if command -v brew &> /dev/null; then
            brew install swiftlint
        else
            print_error "Homebrew not found. Please install SwiftLint manually:"
            echo "  - Via Homebrew: brew install swiftlint"
            echo "  - Via CocoaPods: Add 'pod SwiftLint' to your Podfile"
            echo "  - Download from: https://github.com/realm/SwiftLint/releases"
            exit 1
        fi
    fi

    # Check if SwiftFormat is installed
    if ! command -v swiftformat &> /dev/null; then
        print_warning "SwiftFormat is not installed. Installing via Homebrew..."
        if command -v brew &> /dev/null; then
            brew install swiftformat
        else
            print_warning "Homebrew not found. SwiftFormat is optional but recommended."
            echo "  Install via: brew install swiftformat"
        fi
    fi

    print_success "Requirements check completed"
}

create_pre_commit_hook() {
    print_info "Creating pre-commit hook..."

    local hook_file=".git/hooks/pre-commit"

    cat > "$hook_file" << 'EOF'
#!/bin/bash

# Pre-commit hook for SwiftLint and SwiftFormat

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

echo "🔍 Running pre-commit checks..."

# Get list of Swift files to be committed
SWIFT_FILES=$(git diff --cached --name-only --diff-filter=d | grep -E '\.(swift)$' || true)

if [ -z "$SWIFT_FILES" ]; then
    echo "No Swift files to check."
    exit 0
fi

echo "Checking ${#SWIFT_FILES[@]} Swift file(s)..."

# Run SwiftFormat (if available)
if command -v swiftformat &> /dev/null; then
    echo "🔧 Running SwiftFormat..."

    # Format the files
    swiftformat --config .swiftformat $SWIFT_FILES

    # Add any changes back to the commit
    git add $SWIFT_FILES

    print_success "SwiftFormat completed"
else
    print_warning "SwiftFormat not found, skipping formatting"
fi

# Run SwiftLint
if command -v swiftlint &> /dev/null; then
    echo "🔍 Running SwiftLint..."

    # Create temporary file list
    TEMP_FILE=$(mktemp)
    printf '%s\n' $SWIFT_FILES > "$TEMP_FILE"

    # Run SwiftLint on staged files
    if swiftlint lint --use-stdin --config .swiftlint.yml < "$TEMP_FILE"; then
        print_success "SwiftLint checks passed"
    else
        print_error "SwiftLint found issues. Please fix them before committing."
        rm "$TEMP_FILE"
        exit 1
    fi

    rm "$TEMP_FILE"
else
    print_error "SwiftLint not found. Please install it first:"
    echo "  brew install swiftlint"
    exit 1
fi

echo "✅ Pre-commit checks passed!"
exit 0
EOF

    chmod +x "$hook_file"
    print_success "Pre-commit hook created"
}

create_pre_push_hook() {
    print_info "Creating pre-push hook..."

    local hook_file=".git/hooks/pre-push"

    cat > "$hook_file" << 'EOF'
#!/bin/bash

# Pre-push hook for comprehensive SwiftLint check

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

echo "🚀 Running pre-push checks..."

# Run comprehensive SwiftLint check on all files
if command -v swiftlint &> /dev/null; then
    echo "🔍 Running comprehensive SwiftLint check..."

    if swiftlint lint --config .swiftlint.yml --strict; then
        print_success "SwiftLint comprehensive check passed"
    else
        print_error "SwiftLint found issues. Please fix them before pushing."
        echo ""
        echo "💡 You can run 'swiftlint lint --fix' to auto-fix some issues"
        echo "💡 You can run 'swiftlint lint --strict' to see all issues"
        exit 1
    fi
else
    print_error "SwiftLint not found. Please install it first:"
    echo "  brew install swiftlint"
    exit 1
fi

# Optional: Run tests before push (uncomment if desired)
# echo "🧪 Running tests..."
# if xcodebuild test -workspace YourApp.xcworkspace -scheme YourApp -destination 'platform=iOS Simulator,name=iPhone 15'; then
#     print_success "Tests passed"
# else
#     print_error "Tests failed. Please fix them before pushing."
#     exit 1
# fi

echo "✅ Pre-push checks passed!"
exit 0
EOF

    chmod +x "$hook_file"
    print_success "Pre-push hook created"
}

create_commit_msg_hook() {
    print_info "Creating commit-msg hook..."

    local hook_file=".git/hooks/commit-msg"

    cat > "$hook_file" << 'EOF'
#!/bin/bash

# Commit message hook for conventional commit format validation

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Read the commit message
commit_msg=$(cat "$1")

# Skip merge commits and revert commits
if [[ $commit_msg =~ ^Merge\ branch ]] || [[ $commit_msg =~ ^Revert ]]; then
    exit 0
fi

# Conventional commit pattern
conventional_pattern='^(feat|fix|docs|style|refactor|perf|test|chore|build|ci)(\(.+\))?: .{1,50}'

# Check if commit message matches conventional format
if [[ $commit_msg =~ $conventional_pattern ]]; then
    print_success "Commit message follows conventional format"
else
    print_error "Commit message does not follow conventional commit format!"
    echo ""
    echo "Expected format: <type>[optional scope]: <description>"
    echo ""
    echo "Types:"
    echo "  feat:     A new feature"
    echo "  fix:      A bug fix"
    echo "  docs:     Documentation only changes"
    echo "  style:    Changes that do not affect the meaning of the code"
    echo "  refactor: A code change that neither fixes a bug nor adds a feature"
    echo "  perf:     A code change that improves performance"
    echo "  test:     Adding missing tests or correcting existing tests"
    echo "  chore:    Changes to the build process or auxiliary tools"
    echo "  build:    Changes that affect the build system or external dependencies"
    echo "  ci:       Changes to our CI configuration files and scripts"
    echo ""
    echo "Examples:"
    echo "  feat: add user authentication"
    echo "  fix: resolve memory leak in image cache"
    echo "  docs: update API documentation"
    echo "  feat(auth): implement OAuth2 login"
    echo ""
    exit 1
fi

exit 0
EOF

    chmod +x "$hook_file"
    print_success "Commit-msg hook created"
}

install_pre_commit_framework() {
    print_info "Setting up pre-commit framework (optional)..."

    if command -v pre-commit &> /dev/null; then
        print_info "Pre-commit framework detected, creating configuration..."

        cat > ".pre-commit-config.yaml" << 'EOF'
# Pre-commit configuration for iOS/macOS development

repos:
  # Swift formatting and linting
  - repo: local
    hooks:
      - id: swiftformat
        name: SwiftFormat
        entry: swiftformat
        language: system
        files: \.swift$
        args: [--config, .swiftformat]

      - id: swiftlint
        name: SwiftLint
        entry: swiftlint
        language: system
        files: \.swift$
        args: [lint, --config, .swiftlint.yml, --strict]

  # General code quality
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.4.0
    hooks:
      - id: trailing-whitespace
        exclude: \.md$
      - id: end-of-file-fixer
        exclude: \.md$
      - id: check-yaml
      - id: check-json
      - id: check-merge-conflict
      - id: check-added-large-files
        args: ['--maxkb=1000']

  # Markdown
  - repo: https://github.com/igorshubovych/markdownlint-cli
    rev: v0.37.0
    hooks:
      - id: markdownlint
        args: [--fix]

# CI configuration
ci:
  autofix_commit_msg: |
    [pre-commit.ci] auto fixes from pre-commit hooks

    for more information, see https://pre-commit.ci
  autofix_prs: true
  autoupdate_branch: ''
  autoupdate_commit_msg: '[pre-commit.ci] pre-commit autoupdate'
  autoupdate_schedule: weekly
  skip: []
  submodules: false
EOF

        # Install pre-commit hooks
        pre-commit install
        pre-commit install --hook-type commit-msg

        print_success "Pre-commit framework configured"
    else
        print_warning "Pre-commit framework not found. Install with: pip install pre-commit"
    fi
}

create_xcode_run_script() {
    print_info "Creating Xcode Run Script template..."

    cat > "scripts/xcode-swiftlint-script.sh" << 'EOF'
#!/bin/bash

# Xcode Run Script Phase for SwiftLint
# Add this script to your Xcode project's Build Phases

# Only run SwiftLint on simulator builds for faster development
if [[ "$(uname -m)" == arm64 ]]; then
    export PATH="/opt/homebrew/bin:$PATH"
else
    export PATH="/usr/local/bin:$PATH"
fi

# Check if SwiftLint is available
if which swiftlint > /dev/null; then
    # Run SwiftLint
    swiftlint lint --config "${SRCROOT}/.swiftlint.yml"
else
    echo "warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint"
fi
EOF

    chmod +x "scripts/xcode-swiftlint-script.sh"
    print_success "Xcode Run Script template created"
}

show_xcode_integration_instructions() {
    echo ""
    echo -e "${BLUE}📱 Xcode Integration Instructions:${NC}"
    echo ""
    echo "1. Open your Xcode project"
    echo "2. Select your project in the navigator"
    echo "3. Select your target"
    echo "4. Go to Build Phases tab"
    echo "5. Click '+' and add 'New Run Script Phase'"
    echo "6. Name it 'SwiftLint'"
    echo "7. Add this script content:"
    echo ""
    echo "   if which swiftlint > /dev/null; then"
    echo "       swiftlint lint --config \"\${SRCROOT}/.swiftlint.yml\""
    echo "   else"
    echo "       echo \"warning: SwiftLint not installed\""
    echo "   fi"
    echo ""
    echo "8. Drag the SwiftLint phase to run before 'Compile Sources'"
    echo ""
}

show_usage_instructions() {
    echo ""
    echo -e "${BLUE}📖 Usage Instructions:${NC}"
    echo ""
    echo "SwiftLint Commands:"
    echo "  swiftlint lint                    # Check all files"
    echo "  swiftlint lint --fix              # Auto-fix violations"
    echo "  swiftlint lint --strict           # Treat warnings as errors"
    echo "  swiftlint autocorrect             # Auto-correct violations"
    echo ""
    echo "SwiftFormat Commands:"
    echo "  swiftformat .                     # Format all Swift files"
    echo "  swiftformat --config .swiftformat # Use custom config"
    echo "  swiftformat --lint .              # Check formatting without changing"
    echo ""
    echo "Git Commands:"
    echo "  git commit                        # Triggers pre-commit hook"
    echo "  git push                          # Triggers pre-push hook"
    echo ""
}

# Main execution
main() {
    print_header
    check_requirements

    # Create hooks
    create_pre_commit_hook
    create_pre_push_hook
    create_commit_msg_hook

    # Optional pre-commit framework
    install_pre_commit_framework

    # Create Xcode integration script
    create_xcode_run_script

    # Show integration instructions
    show_xcode_integration_instructions
    show_usage_instructions

    echo ""
    print_success "Git hooks setup completed successfully!"
    echo ""
    print_info "Hooks installed:"
    echo "  ✅ pre-commit: SwiftFormat + SwiftLint"
    echo "  ✅ pre-push: Comprehensive SwiftLint check"
    echo "  ✅ commit-msg: Conventional commit validation"
    echo ""
    print_info "Next steps:"
    echo "  1. Add SwiftLint Run Script Phase to Xcode (see instructions above)"
    echo "  2. Configure your team to run: ./scripts/setup-git-hooks.sh"
    echo "  3. Test the setup by making a commit"
    echo ""
}

# Handle command line arguments
case "${1:-}" in
    --help|-h)
        echo "Git Hooks Setup Script"
        echo ""
        echo "Usage: $0 [OPTION]"
        echo ""
        echo "Options:"
        echo "  --help, -h    Show this help message"
        echo ""
        echo "This script sets up:"
        echo "  - Pre-commit hook (SwiftFormat + SwiftLint)"
        echo "  - Pre-push hook (Comprehensive SwiftLint)"
        echo "  - Commit message validation"
        echo "  - Xcode integration script"
        ;;
    *)
        main "$@"
        ;;
esac