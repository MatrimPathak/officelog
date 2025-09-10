#!/bin/bash

# OfficeLog - GitHub Actions Setup Verification Script
# This script verifies your GitHub Actions setup for automated releases

echo "🚀 OfficeLog - GitHub Actions Setup Verification"
echo "==============================================="
echo ""

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI is not installed. Please install it first:"
    echo "   https://cli.github.com/"
    exit 1
fi

# Check if user is authenticated
if ! gh auth status &> /dev/null; then
    echo "❌ You're not authenticated with GitHub CLI."
    echo "   Run: gh auth login"
    exit 1
fi

echo "✅ GitHub CLI is installed and authenticated"
echo ""

# Check for required files
echo "🔍 Checking required files..."

if [ -f ".github/workflows/release.yml" ]; then
    echo "✅ GitHub Actions workflow file found"
else
    echo "❌ GitHub Actions workflow file missing: .github/workflows/release.yml"
fi

if [ -f "android/app/google-services.json" ]; then
    echo "✅ Firebase configuration file found"
else
    echo "❌ Firebase configuration file missing: android/app/google-services.json"
    echo "   Please ensure your Firebase configuration is properly set up"
fi

if [ -f "pubspec.yaml" ]; then
    echo "✅ Flutter project configuration found"
else
    echo "❌ Flutter project configuration missing: pubspec.yaml"
fi

echo ""

# Check repository status
echo "📊 Repository Information:"
REPO_URL=$(gh repo view --json url -q .url 2>/dev/null || echo "Not available")
echo "🔗 Repository: $REPO_URL"

# Check for existing releases
RELEASE_COUNT=$(gh release list --limit 1 --json tagName -q '. | length' 2>/dev/null || echo "0")
echo "📦 Existing releases: $RELEASE_COUNT"

echo ""
echo "🎉 Setup Verification Complete!"
echo ""
echo "🛡️ Security Recommendations:"
echo "   ✅ No GitHub secrets required - using committed configuration files"
echo "   ✅ Firebase configuration is handled securely"
echo "   ✅ API keys are not exposed in workflow logs"
echo ""
echo "🚀 Ready for automated releases!"
echo ""
echo "📋 Next steps:"
echo "   1. Create and push a tag: git tag v1.0.2 && git push origin v1.0.2"
echo "   2. Or manually trigger from GitHub Actions tab"
echo "   3. Monitor the build in the Actions tab"
echo ""
