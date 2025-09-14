# 🏷️ OfficeLog Versioning Strategy

## 🎯 Overview

This document outlines the automated versioning strategy for OfficeLog that ensures Google Play Store compatibility and eliminates manual version code management.

## 📋 Strategy

### Semantic Versioning (Major.Minor.Patch)
- **User-facing version**: Clean semantic version (e.g., `1.2.5`)
- **Auto-calculated versionCode**: Formula-based integer for Google Play
- **Single source of truth**: `pubspec.yaml` version field

### Version Code Formula
```
versionCode = (major × 10,000) + (minor × 100) + patch
```

**Examples:**
- `1.0.0` → versionCode `10000`
- `1.2.5` → versionCode `10205`
- `2.0.0` → versionCode `20000`
- `1.15.99` → versionCode `11599`

This formula ensures:
- ✅ Version codes always increase with semantic versions
- ✅ No conflicts or duplicates
- ✅ Google Play Store compatibility
- ✅ Support for up to 99 minor/patch versions

## 🔧 Implementation

### 1. pubspec.yaml
```yaml
version: 1.1.0  # Clean semantic version (no +build)
```

### 2. Android build.gradle.kts
Automatically reads `pubspec.yaml` and calculates:
- `versionName`: `"1.1.0"` (user-facing)
- `versionCode`: `11000` (internal)

### 3. GitHub Actions
Validates version bumps and ensures consistency between:
- Git tag/workflow input
- pubspec.yaml version
- Previous release versions

## 🚀 Release Process

### Option 1: Manual Workflow Trigger
```bash
# 1. Update pubspec.yaml version
version: 1.2.0

# 2. Commit changes
git add pubspec.yaml
git commit -m "bump: version 1.2.0"
git push

# 3. Trigger release workflow
gh workflow run "🚀 Build and Release OfficeLog" --ref master -f version=v1.2.0
```

### Option 2: Git Tag Trigger
```bash
# 1. Update pubspec.yaml version
version: 1.2.0

# 2. Commit and tag
git add pubspec.yaml
git commit -m "bump: version 1.2.0"
git tag v1.2.0
git push origin master --tags
```

## ✅ Validation Rules

The GitHub Actions workflow enforces:

1. **Version Match**: pubspec.yaml version must match git tag/input
   - `v1.2.0` input ↔ `1.2.0` in pubspec.yaml

2. **Version Increment**: New version must be greater than last release
   - `1.1.0` → `1.2.0` ✅
   - `1.2.0` → `1.1.0` ❌

3. **No Duplicates**: Version cannot already exist as a git tag
   - Prevents accidental re-releases

## 📊 Version Code Limits

The formula supports versions up to `99.99.99`:
- Maximum versionCode: `999,999`
- Google Play limit: `2,100,000,000`
- **Headroom**: 2,100× more than we'll ever need

## 🔄 Migration from Old System

**Before** (manual management):
```yaml
version: 1.0.0+4  # Manual build number
```

**After** (automatic):
```yaml
version: 1.0.0    # Clean semantic version
```

The build system now:
- ✅ Ignores any `+build` numbers in pubspec.yaml
- ✅ Auto-calculates versionCode from semantic version
- ✅ Shows calculated values during build

## 🛠️ Troubleshooting

### "Version mismatch" error
```
❌ Version mismatch. Bump pubspec.yaml to 1.2.0 before running.
```
**Fix**: Update `version:` in pubspec.yaml to match your intended release version.

### "Version already exists" error
```
❌ Version 1.1.0 already exists. Bump the version.
```
**Fix**: Choose a higher version number that hasn't been released yet.

### "Version must be greater" error
```
❌ Version 1.0.0 must be greater than last tag 1.1.0.
```
**Fix**: Use a version number higher than the last release.

## 📈 Version History Examples

| Release | pubspec.yaml | versionName | versionCode | Notes |
|---------|--------------|-------------|-------------|-------|
| v1.0.0  | `1.0.0`      | `"1.0.0"`   | `10000`     | Initial release |
| v1.1.0  | `1.1.0`      | `"1.1.0"`   | `11000`     | Feature release |
| v1.1.1  | `1.1.1`      | `"1.1.1"`   | `11001`     | Bug fix |
| v1.2.0  | `1.2.0`      | `"1.2.0"`   | `11200`     | Feature release |
| v2.0.0  | `2.0.0`      | `"2.0.0"`   | `20000`     | Major release |

## 🎉 Benefits

- ✅ **Zero manual version code management**
- ✅ **Google Play Store compatibility guaranteed**
- ✅ **No version conflicts or duplicates**
- ✅ **Clean, semantic version names for users**
- ✅ **Automatic validation in CI/CD**
- ✅ **Single source of truth (pubspec.yaml)**
- ✅ **Future-proof for thousands of releases**

---

**Need help?** Check the GitHub Actions logs for detailed version calculation output during builds.
