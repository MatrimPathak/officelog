# 🚀 GitHub Actions Automated Release Setup

This guide will help you set up automated releases for OfficeLog using GitHub Actions.

## 📋 Overview

The GitHub Actions workflow automatically:

-   ✅ Builds release APK and AAB files
-   ✅ Creates GitHub releases with detailed notes
-   ✅ Uploads build artifacts
-   ✅ Supports manual and automatic triggers
-   ✅ Includes build information and file sizes

## 🔧 Setup Instructions

### Step 1: Firebase Configuration

**🔒 Security Note**: The workflow now uses the existing `google-services.json` file in your repository instead of GitHub secrets. This is more secure and follows Firebase best practices.

#### Required File: `android/app/google-services.json`

Your Firebase configuration file should already be present in the repository. The workflow will verify its existence before building.

#### Verification Script

You can use the verification script to check your setup:

```bash
# Make the script executable and run it (on Unix/Linux/Mac)
chmod +x verify-github-actions.sh
./verify-github-actions.sh

# On Windows, you can run it directly if you have Git Bash or WSL
```

#### 🛡️ Security Best Practices

1. **Keep sensitive keys private**: Never expose API keys in public repositories
2. **Use environment-specific configs**: Consider different Firebase projects for development/production
3. **Rotate keys regularly**: Update Firebase API keys periodically
4. **Review permissions**: Ensure Firebase project permissions are properly configured

#### ⚠️ Important Security Notes

- The `google-services.json` file contains your Firebase configuration
- This file is necessary for Firebase services to work
- Keep your Firebase project permissions restricted
- Consider using Firebase App Check for additional security

### Step 2: Verify Workflow File

The workflow file is located at `.github/workflows/release.yml`. It includes:

-   🐦 Flutter 3.24.0 setup
-   ☕ Java 17 configuration
-   📦 Dependency management
-   🔧 Firebase configuration
-   🔨 APK and AAB building
-   🚀 Automated release creation
-   📋 Artifact uploading

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

-   **File**: `OfficeLog-v1.0.x.apk`
-   **Use**: Direct installation on Android devices
-   **Size**: ~60-70MB
-   **Format**: Universal APK (works on all Android architectures)

### 📱 AAB File

-   **File**: `OfficeLog-v1.0.x.aab`
-   **Use**: Google Play Store publishing
-   **Size**: ~40-50MB
-   **Format**: Android App Bundle (optimized for Play Store)

## 🔍 Workflow Features

### ✨ Enhanced Features

-   📊 **Build Information**: File sizes, build date, commit SHA
-   🏷️ **Smart Versioning**: Automatic version detection from tags
-   📝 **Rich Release Notes**: Detailed installation and feature information
-   🔄 **Fallback Configuration**: Works even without secrets (uses defaults)
-   ⏱️ **Timeout Protection**: 30-minute build timeout
-   📋 **Artifact Retention**: 30-day artifact storage
-   🎯 **Pre-release Support**: Option to mark releases as pre-release

### 🛡️ Error Handling

-   ✅ Verbose build output for debugging
-   ✅ Clean build process to avoid cache issues
-   ✅ Graceful handling of missing secrets
-   ✅ Build artifact upload even on partial failures

## 📊 Monitoring

### View Build Status

-   Go to repository → Actions tab
-   Monitor real-time build progress
-   View detailed logs for debugging

### Release Management

-   Go to repository → Releases
-   View all published releases
-   Download build artifacts
-   Edit release notes if needed

## 🔧 Customization

### Modify Build Configuration

Edit `.github/workflows/release.yml` to:

-   Change Flutter version
-   Modify build flags
-   Update release notes template
-   Add additional build steps

### Update Firebase Configuration

-   Update secrets in repository settings
-   Or modify the workflow to use different values
-   The workflow has fallback values for testing

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

-   [GitHub Actions Documentation](https://docs.github.com/en/actions)
-   [Flutter Build Documentation](https://docs.flutter.dev/deployment/android)
-   [GitHub CLI Documentation](https://cli.github.com/manual/)
-   [Firebase Setup Guide](https://firebase.google.com/docs/flutter/setup)
