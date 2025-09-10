#!/bin/bash

# OfficeLog - GitHub Secrets Setup Script
# This script helps you set up GitHub repository secrets for automated releases

echo "🚀 OfficeLog - GitHub Secrets Setup"
echo "===================================="
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

# Firebase Configuration Values (from config.env)
FIREBASE_PROJECT_NUMBER="89886471430"
FIREBASE_PROJECT_ID="pega-attendence"
FIREBASE_STORAGE_BUCKET="pega-attendence.firebasestorage.app"
FIREBASE_ANDROID_APP_ID="1:89886471430:android:0daf63b7dc13a70af75a87"
FIREBASE_ANDROID_API_KEY="AIzaSyDIRPwrWHZ5aVfU4WSEuUj7WtS237z5DO4"
ANDROID_PACKAGE_NAME="com.matrimpathak.attendence_flutter"

echo "📝 Setting up GitHub repository secrets..."
echo ""

# Set secrets using GitHub CLI
echo "Setting FIREBASE_PROJECT_NUMBER..."
echo "$FIREBASE_PROJECT_NUMBER" | gh secret set FIREBASE_PROJECT_NUMBER

echo "Setting FIREBASE_PROJECT_ID..."
echo "$FIREBASE_PROJECT_ID" | gh secret set FIREBASE_PROJECT_ID

echo "Setting FIREBASE_STORAGE_BUCKET..."
echo "$FIREBASE_STORAGE_BUCKET" | gh secret set FIREBASE_STORAGE_BUCKET

echo "Setting FIREBASE_ANDROID_APP_ID..."
echo "$FIREBASE_ANDROID_APP_ID" | gh secret set FIREBASE_ANDROID_APP_ID

echo "Setting FIREBASE_ANDROID_API_KEY..."
echo "$FIREBASE_ANDROID_API_KEY" | gh secret set FIREBASE_ANDROID_API_KEY

echo "Setting ANDROID_PACKAGE_NAME..."
echo "$ANDROID_PACKAGE_NAME" | gh secret set ANDROID_PACKAGE_NAME

echo ""
echo "✅ All secrets have been set successfully!"
echo ""

# List current secrets to verify
echo "📋 Current repository secrets:"
gh secret list

echo ""
echo "🎉 Setup Complete!"
echo ""
echo "📱 Your GitHub Actions workflow is now ready!"
echo ""
echo "🚀 How to create automated releases:"
echo "   1. Create and push a tag: git tag v1.0.1 && git push origin v1.0.1"
echo "   2. Or manually trigger from GitHub Actions tab"
echo ""
echo "🔗 Workflow file: .github/workflows/release.yml"
echo "🔗 Repository: $(gh repo view --json url -q .url)"
echo ""
