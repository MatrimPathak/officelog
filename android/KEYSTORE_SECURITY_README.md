# Keystore Security Setup

## Important Security Files

### Files that MUST be kept secure and backed up:

-   `app-release-key.keystore` - Your signing keystore file
-   `keystore.properties` - Contains your keystore passwords

### Files that are safe to commit:

-   `keystore.properties.example` - Template file showing the format

## Setup Instructions

1. **First Time Setup:**

    - Copy `keystore.properties.example` to `keystore.properties`
    - Fill in your actual keystore credentials in `keystore.properties`

2. **Security:**

    - Never commit `keystore.properties` or `*.keystore` files to version control
    - These files are automatically ignored by `.gitignore`
    - Store backups of these files in a secure location

3. **Team Setup:**
    - Each team member should have their own copy of `keystore.properties`
    - Share keystore credentials through secure channels only
    - Never share credentials in chat, email, or code comments

## Current Configuration

The build system looks for:

-   `android/keystore.properties` - Your keystore configuration
-   `android/app-release-key.keystore` - Your signing key

## Backup Checklist

-   [ ] `app-release-key.keystore` backed up securely
-   [ ] `keystore.properties` backed up securely
-   [ ] Keystore passwords documented in secure password manager
-   [ ] Team members have access to secure credential storage

## Build Commands

```bash
# Build release AAB for Google Play Store
flutter build appbundle --release

# Build release APK for direct distribution
flutter build apk --release
```
