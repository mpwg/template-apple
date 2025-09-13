#!/bin/bash

# Setup Secrets Script
# This script helps set up environment variables and GitHub repository secrets
# for iOS/macOS development with Fastlane

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ENV_FILE=".env"
ENV_TEMPLATE=".env.template"
VALIDATION_SCRIPT="scripts/validate-environment.sh"

# Functions
print_header() {
    echo -e "\n${BLUE}================================${NC}"
    echo -e "${BLUE}🚀 Environment Setup Helper${NC}"
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

check_prerequisites() {
    print_info "Checking prerequisites..."

    # Check if gh CLI is installed
    if ! command -v gh &> /dev/null; then
        print_error "GitHub CLI (gh) is not installed. Please install it first:"
        echo "  brew install gh"
        echo "  or visit: https://cli.github.com/"
        exit 1
    fi

    # Check if gh is authenticated
    if ! gh auth status &> /dev/null; then
        print_error "GitHub CLI is not authenticated. Please run:"
        echo "  gh auth login"
        exit 1
    fi

    # Check if bundle is available
    if ! command -v bundle &> /dev/null; then
        print_warning "Bundler is not installed. Install with: gem install bundler"
    fi

    print_success "Prerequisites check completed"
}

setup_env_file() {
    print_info "Setting up environment file..."

    if [[ ! -f "$ENV_TEMPLATE" ]]; then
        print_error "Environment template file ($ENV_TEMPLATE) not found!"
        exit 1
    fi

    if [[ -f "$ENV_FILE" ]]; then
        print_warning "Environment file ($ENV_FILE) already exists!"
        read -p "Do you want to overwrite it? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Skipping environment file setup"
            return
        fi
    fi

    cp "$ENV_TEMPLATE" "$ENV_FILE"
    print_success "Environment file created: $ENV_FILE"
    print_warning "Please edit $ENV_FILE and replace all placeholder values with your actual configuration"

    # Open file in default editor if available
    if command -v code &> /dev/null; then
        print_info "Opening $ENV_FILE in VS Code..."
        code "$ENV_FILE"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        print_info "Opening $ENV_FILE in default editor..."
        open "$ENV_FILE"
    fi
}

validate_env_file() {
    print_info "Validating environment file..."

    if [[ ! -f "$ENV_FILE" ]]; then
        print_error "Environment file ($ENV_FILE) not found!"
        print_info "Run this script with --setup-env first"
        return 1
    fi

    # Source the environment file
    set -a  # Automatically export all variables
    source "$ENV_FILE"
    set +a

    # Check required variables
    required_vars=(
        "APPLE_ID"
        "DEVELOPMENT_TEAM"
        "APPSTORE_TEAM_ID"
        "APP_STORE_CONNECT_API_KEY_KEY_ID"
        "APP_STORE_CONNECT_API_KEY_ISSUER_ID"
        "APP_STORE_CONNECT_API_KEY_CONTENT"
        "MATCH_PASSWORD"
        "MATCH_GIT_URL"
        "MATCH_GIT_BASIC_AUTHORIZATION"
        "KEYCHAIN_PASSWORD"
    )

    missing_vars=()
    placeholder_vars=()

    for var in "${required_vars[@]}"; do
        if [[ -z "${!var}" ]]; then
            missing_vars+=("$var")
        elif [[ "${!var}" == *"your"* ]] || [[ "${!var}" == *"YOUR"* ]] || [[ "${!var}" == *"example.com"* ]]; then
            placeholder_vars+=("$var")
        fi
    done

    if [[ ${#missing_vars[@]} -gt 0 ]]; then
        print_error "Missing required variables:"
        for var in "${missing_vars[@]}"; do
            echo "  - $var"
        done
        return 1
    fi

    if [[ ${#placeholder_vars[@]} -gt 0 ]]; then
        print_warning "Variables with placeholder values (please update):"
        for var in "${placeholder_vars[@]}"; do
            echo "  - $var"
        done
        return 1
    fi

    print_success "Environment file validation completed successfully"
    return 0
}

upload_secrets() {
    print_info "Uploading secrets to GitHub repository..."

    if ! validate_env_file; then
        print_error "Environment validation failed. Please fix the issues and try again."
        return 1
    fi

    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        print_error "Not in a Git repository!"
        return 1
    fi

    # Get repository info
    repo_info=$(gh repo view --json owner,name -q '.owner.login + "/" + .name' 2>/dev/null || echo "")
    if [[ -z "$repo_info" ]]; then
        print_error "Could not determine repository information"
        return 1
    fi

    print_info "Repository: $repo_info"
    read -p "Upload secrets to this repository? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Secrets upload cancelled"
        return
    fi

    # Upload secrets
    print_info "Uploading secrets..."
    if gh secret set -f "$ENV_FILE"; then
        print_success "Secrets uploaded successfully"

        # List uploaded secrets
        print_info "Uploaded secrets:"
        gh secret list | while read -r line; do
            echo "  - $line"
        done
    else
        print_error "Failed to upload secrets"
        return 1
    fi
}

list_secrets() {
    print_info "Listing GitHub repository secrets..."

    if ! gh secret list &> /dev/null; then
        print_error "Failed to list secrets. Make sure you have access to the repository."
        return 1
    fi

    echo "Repository secrets:"
    gh secret list | while read -r line; do
        echo "  - $line"
    done
}

create_validation_script() {
    print_info "Creating validation script..."

    cat > "$VALIDATION_SCRIPT" << 'EOF'
#!/bin/bash

# Environment Validation Script
# Validates that all required environment variables are set

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

echo "🔍 Validating environment configuration..."

# Check if .env file exists and source it
if [[ -f ".env" ]]; then
    set -a
    source .env
    set +a
    print_success ".env file loaded"
else
    print_warning ".env file not found, checking system environment variables"
fi

# Required environment variables
required_vars=(
    "APPLE_ID"
    "DEVELOPMENT_TEAM"
    "APPSTORE_TEAM_ID"
    "APP_STORE_CONNECT_API_KEY_KEY_ID"
    "APP_STORE_CONNECT_API_KEY_ISSUER_ID"
    "APP_STORE_CONNECT_API_KEY_CONTENT"
    "MATCH_PASSWORD"
    "MATCH_GIT_URL"
    "MATCH_GIT_BASIC_AUTHORIZATION"
    "KEYCHAIN_PASSWORD"
)

missing_vars=()
set_vars=()

for var in "${required_vars[@]}"; do
    if [[ -z "${!var}" ]]; then
        missing_vars+=("$var")
        print_error "Missing: $var"
    else
        set_vars+=("$var")
        print_success "Set: $var"
    fi
done

echo ""
echo "📊 Validation Summary:"
echo "  ✅ Variables set: ${#set_vars[@]}"
echo "  ❌ Variables missing: ${#missing_vars[@]}"

if [[ ${#missing_vars[@]} -eq 0 ]]; then
    echo ""
    print_success "🎉 All required environment variables are set!"
    exit 0
else
    echo ""
    print_error "❌ Missing required environment variables. Please configure them in your .env file."
    exit 1
fi
EOF

    chmod +x "$VALIDATION_SCRIPT"
    print_success "Validation script created: $VALIDATION_SCRIPT"
}

show_help() {
    echo "Environment Setup Helper"
    echo ""
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  --setup-env       Create .env file from template"
    echo "  --validate        Validate environment configuration"
    echo "  --upload-secrets  Upload secrets to GitHub repository"
    echo "  --list-secrets    List current GitHub repository secrets"
    echo "  --create-validator Create validation script"
    echo "  --all             Run complete setup (setup-env, validate, upload-secrets)"
    echo "  --help            Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --setup-env                 # Create .env file"
    echo "  $0 --validate                  # Validate environment"
    echo "  $0 --upload-secrets           # Upload to GitHub"
    echo "  $0 --all                      # Complete setup"
}

# Main script logic
main() {
    print_header
    check_prerequisites

    case "${1:-}" in
        --setup-env)
            setup_env_file
            ;;
        --validate)
            validate_env_file
            ;;
        --upload-secrets)
            upload_secrets
            ;;
        --list-secrets)
            list_secrets
            ;;
        --create-validator)
            create_validation_script
            ;;
        --all)
            setup_env_file
            echo ""
            print_info "Please edit $ENV_FILE with your actual values, then run:"
            print_info "$0 --validate && $0 --upload-secrets"
            ;;
        --help|-h)
            show_help
            ;;
        "")
            print_info "No option specified. Use --help for usage information."
            print_info "Quick start: $0 --all"
            ;;
        *)
            print_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"