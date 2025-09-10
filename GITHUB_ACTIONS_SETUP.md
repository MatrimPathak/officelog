# 🚀 GitHub Actions Automated Release Setup

This guide will help you set up automated releases for OfficeLog using GitHub Actions.

## 📋 Overview

The GitHub Actions workflow automatically:
- ✅ Builds release APK and AAB files
- ✅ Creates GitHub releases with detailed notes
- ✅ Uploads build artifacts
- ✅ Supports manual and automatic triggers
- ✅ Includes build information and file sizes

## 🔧 Setup Instructions

### Step 1: Set Up GitHub Secrets

You need to configure repository secrets for Firebase integration. Choose one of these methods:

#### Method A: Automatic Setup (Recommended)
```bash
# Make the script executable and run it
chmod +x setup-github-secrets.sh
./setup-github-secrets.sh
```

#### Method B: Manual Setup
Go to your GitHub repository → Settings → Secrets and variables → Actions

Add these secrets:

| Secret Name | Value |
|-------------|-------|
| `FIREBASE_PROJECT_NUMBER` | `89886471430` |
| `FIREBASE_PROJECT_ID` | `pega-attendence` |
| `FIREBASE_STORAGE_BUCKET` | `pega-attendence.firebasestorage.app` |
| `FIREBASE_ANDROID_APP_ID` | `1:89886471430:android:0daf63b7dc13a70af75a87` |
| `FIREBASE_ANDROID_API_KEY` | `AIzaSyDIRPwrWHZ5aVfU4WSEuUj7WtS237z5DO4` |
| `ANDROID_PACKAGE_NAME` | `com.matrimpathak.attendence_flutter` |

#### Method C: Using GitHub CLI
```bash
gh secret set FIREBASE_PROJECT_NUMBER --body "89886471430"
gh secret set FIREBASE_PROJECT_ID --body "pega-attendence"
gh secret set FIREBASE_STORAGE_BUCKET --body "pega-attendence.firebasestorage.app"
gh secret set FIREBASE_ANDROID_APP_ID --body "1:89886471430:android:0daf63b7dc13a70af75a87"
gh secret set FIREBASE_ANDROID_API_KEY --body "AIzaSyDIRPwrWHZ5aVfU4WSEuUj7WtS237z5DO4"
gh secret set ANDROID_PACKAGE_NAME --body "com.matrimpathak.attendence_flutter"
```

### Step 2: Verify Workflow File

The workflow file is located at `.github/workflows/release.yml`. It includes:

- 🐦 Flutter 3.24.0 setup
- ☕ Java 17 configuration
- 📦 Dependency management
- 🔧 Firebase configuration
- 🔨 APK and AAB building
- 🚀 Automated release creation
- 📋 Artifact uploading

## 🎯 Usage

### Automatic Releases (Tag-based)
```bash
# Create and push a version tag
git tag v1.0.1
git push origin v1.0.1

# The workflow will automatically trigger and create a release
```

### Manual Releases
1. Go to your repository on GitHub
2. Click "Actions" tab
3. Select "🚀 Build and Release OfficeLog" workflow
4. Click "Run workflow"
5. Enter version (e.g., `v1.0.1`)
6. Choose if it's a pre-release
7. Click "Run workflow"

## 📱 What Gets Built

Each release includes:

### 📦 APK File
- **File**: `OfficeLog-v1.0.x.apk`
- **Use**: Direct installation on Android devices
- **Size**: ~60-70MB
- **Format**: Universal APK (works on all Android architectures)

### 📱 AAB File  
- **File**: `OfficeLog-v1.0.x.aab`
- **Use**: Google Play Store publishing
- **Size**: ~40-50MB
- **Format**: Android App Bundle (optimized for Play Store)

## 🔍 Workflow Features

### ✨ Enhanced Features
- 📊 **Build Information**: File sizes, build date, commit SHA
- 🏷️ **Smart Versioning**: Automatic version detection from tags
- 📝 **Rich Release Notes**: Detailed installation and feature information
- 🔄 **Fallback Configuration**: Works even without secrets (uses defaults)
- ⏱️ **Timeout Protection**: 30-minute build timeout
- 📋 **Artifact Retention**: 30-day artifact storage
- 🎯 **Pre-release Support**: Option to mark releases as pre-release

### 🛡️ Error Handling
- ✅ Verbose build output for debugging
- ✅ Clean build process to avoid cache issues
- ✅ Graceful handling of missing secrets
- ✅ Build artifact upload even on partial failures

## 📊 Monitoring

### View Build Status
- Go to repository → Actions tab
- Monitor real-time build progress
- View detailed logs for debugging

### Release Management
- Go to repository → Releases
- View all published releases
- Download build artifacts
- Edit release notes if needed

## 🔧 Customization

### Modify Build Configuration
Edit `.github/workflows/release.yml` to:
- Change Flutter version
- Modify build flags
- Update release notes template
- Add additional build steps

### Update Firebase Configuration
- Update secrets in repository settings
- Or modify the workflow to use different values
- The workflow has fallback values for testing

## 🚨 Troubleshooting

### Common Issues

#### Build Fails - Missing Secrets
**Solution**: Ensure all required secrets are set in repository settings

#### Build Fails - Flutter Version
**Solution**: Update Flutter version in workflow file if needed

#### Build Fails - Dependencies
**Solution**: Check `pubspec.yaml` for dependency conflicts

#### Release Creation Fails
**Solution**: Ensure `GITHUB_TOKEN` has sufficient permissions

### Getting Help

1. Check the Actions tab for detailed error logs
2. Verify all secrets are properly set
3. Ensure the tag format matches `v*.*.*` pattern
4. Check repository permissions for GitHub Actions

## 🎉 Success!

Once set up, your workflow will:

1. 🔄 **Auto-trigger** on version tags
2. 🔨 **Build** APK and AAB files
3. 📝 **Generate** detailed release notes
4. 🚀 **Create** GitHub release
5. 📤 **Upload** build artifacts
6. 📧 **Notify** via GitHub notifications

Your OfficeLog app releases are now fully automated! 🎊

---

## 📚 Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Flutter Build Documentation](https://docs.flutter.dev/deployment/android)
- [GitHub CLI Documentation](https://cli.github.com/manual/)
- [Firebase Setup Guide](https://firebase.google.com/docs/flutter/setup)
