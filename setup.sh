#!/bin/bash

# iOS/macOS Template Setup Script
# This script helps you quickly customize the template for your project

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 iOS/macOS Template Setup${NC}"
echo "==============================="
echo

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}⚠️  .env file not found. Copying from .env.template${NC}"
    cp .env.template .env
    echo -e "${GREEN}✅ Created .env file from template${NC}"
    echo
fi

# Load environment variables from .env
set -a
source .env
set +a

echo -e "${BLUE}📋 Current Configuration:${NC}"
echo "Project Name: $PROJECT_NAME"
echo "Bundle ID: $PRODUCT_BUNDLE_IDENTIFIER"
echo "Development Team: ${DEVELOPMENT_TEAM:-'Not set'}"
echo

# Ask user if they want to proceed with renaming
echo -e "${YELLOW}This will rename files and update references to use your project name.${NC}"
read -p "Do you want to proceed? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Setup cancelled. You can run this script again when ready.${NC}"
    exit 0
fi

echo -e "${BLUE}🔄 Renaming project files...${NC}"

# Rename Xcode project
if [ -d "MyApp.xcodeproj" ] && [ "$PROJECT_NAME" != "MyApp" ]; then
    mv MyApp.xcodeproj "${PROJECT_NAME}.xcodeproj"
    echo -e "${GREEN}✅ Renamed Xcode project to ${PROJECT_NAME}.xcodeproj${NC}"
fi

# Rename app folder
if [ -d "MyApp" ] && [ "$PROJECT_NAME" != "MyApp" ]; then
    mv MyApp "${PROJECT_NAME}"
    echo -e "${GREEN}✅ Renamed app folder to ${PROJECT_NAME}/${NC}"
fi

# Update SwiftLint configuration
if [ -f ".swiftlint.yml" ]; then
    sed -i '' "s/MyApp/${PROJECT_NAME}/g" .swiftlint.yml
    echo -e "${GREEN}✅ Updated SwiftLint configuration${NC}"
fi

echo -e "${BLUE}🔧 Next steps:${NC}"
echo "1. Open ${PROJECT_NAME}.xcodeproj in Xcode"
echo "2. Update the project name in Xcode (select project → rename)"
echo "3. Review and update your .env file with correct values"
echo "4. Set up your GitHub secrets (see README.md)"
echo "5. Initialize Fastlane Match: fastlane match init"
echo
echo -e "${GREEN}✅ Template setup complete!${NC}"
echo -e "${BLUE}📖 For detailed instructions, see README.md${NC}"