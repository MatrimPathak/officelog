# Release Management Scripts

This directory contains scripts to automatically increment version numbers and generate release builds for the OfficeLog Flutter app.

## Scripts Overview

### 1. `increment_version.dart`

Automatically increments the version number in `pubspec.yaml`.

**Usage:**

```bash
dart increment_version.dart [patch|minor|major]
```

**Examples:**

-   `dart increment_version.dart patch` - Increments patch version (1.0.0+2 → 1.0.1+3)
-   `dart increment_version.dart minor` - Increments minor version (1.0.0+2 → 1.1.0+3)
-   `dart increment_version.dart major` - Increments major version (1.0.0+2 → 2.0.0+3)

### 2. `generate_release.sh` / `generate_release.ps1`

Generates release builds for Android and iOS.

**Usage:**

```bash
# Bash (Linux/macOS)
./generate_release.sh [android|ios|both]

# PowerShell (Windows)
.\generate_release.ps1 [android|ios|both]
```

**Examples:**

-   `./generate_release.sh android` - Build only Android APK and AAB
-   `./generate_release.sh ios` - Build only iOS app (macOS only)
-   `./generate_release.sh both` - Build both platforms

### 3. `create_release.sh` / `create_release.ps1` ⭐ **MAIN SCRIPT**

Combines version increment and release generation in one command.

**Usage:**

```bash
# Bash (Linux/macOS)
./create_release.sh [patch|minor|major] [android|ios|both]

# PowerShell (Windows)
.\create_release.ps1 [patch|minor|major] [android|ios|both]
```

**Examples:**

-   `./create_release.sh` - Default: patch version + both platforms
-   `./create_release.sh minor android` - Minor version + Android only
-   `./create_release.sh major both` - Major version + both platforms

## Quick Start

For the most common use case (patch version increment + Android build):

**Windows:**

```powershell
.\create_release.ps1
```

**Linux/macOS:**

```bash
./create_release.sh
```

## Output

All release builds are saved in the `releases/` directory with timestamps:

-   `releases/android_20241214_143022/app-release.apk`
-   `releases/android_20241214_143022/app-release.aab`
-   `releases/ios_20241214_143022/Runner.app`

## Requirements

-   Flutter SDK installed and configured
-   Dart SDK (for version increment script)
-   Android SDK (for Android builds)
-   Xcode (for iOS builds, macOS only)
-   Proper signing configuration for release builds

## Notes

-   The build number (after the +) is always incremented automatically
-   iOS builds require macOS and Xcode for proper signing
-   Android builds include both APK (for direct installation) and AAB (for Play Store)
-   All scripts include error handling and will stop on any failure
