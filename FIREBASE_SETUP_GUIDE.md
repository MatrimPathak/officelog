# 🔥 Firebase Setup Guide for Attendance Flutter App

## Prerequisites

-   Google account
-   Flutter project (already set up ✅)
-   Android Studio or VS Code

## Step-by-Step Setup

### 1. Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project" or "Add project"
3. **Project name**: `attendence-flutter-app` (or your preferred name)
4. **Enable Google Analytics**: Optional but recommended
5. Click "Create project"

### 2. Enable Authentication

1. In Firebase Console → **Authentication** → **Get started**
2. Go to **Sign-in method** tab
3. Enable **Google**:
    - Click on Google
    - Toggle "Enable"
    - Add project support email
    - Click "Save"
4. Enable **Email/Password**:
    - Click on Email/Password
    - Toggle "Enable" for both options
    - Click "Save"

### 3. Enable Firestore Database

1. Go to **Firestore Database** → **Create database**
2. Choose **"Start in test mode"** (we'll update rules later)
3. Select location closest to your users
4. Click "Done"

### 4. Add Android App

1. Go to **Project Settings** (gear icon ⚙️)
2. Scroll to **"Your apps"** section
3. Click **Android icon** 📱
4. **Package name**: `com.matrimpathak.attendence_flutter`
5. **App nickname**: `Attendance Flutter Android`
6. Click **"Register app"**
7. **Download** `google-services.json`
8. **Place** the file in `android/app/` directory

### 5. Add iOS App (Optional)

1. Click **iOS icon** 🍎
2. **Bundle ID**: `com.example.attendenceFlutter`
3. **App nickname**: `Attendance Flutter iOS`
4. Click **"Register app"**
5. **Download** `GoogleService-Info.plist`
6. **Place** the file in `ios/Runner/` directory

### 6. Update Firebase Configuration

1. Go to **Project Settings** → **General** tab
2. Scroll to **"Your apps"** section
3. Click on your Android app
4. Copy the **config values**:

    - `apiKey`
    - `appId`
    - `messagingSenderId`
    - `projectId`
    - `storageBucket`

5. **Update** `lib/firebase_options.dart` with your actual values:

```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'YOUR_ACTUAL_API_KEY',
  appId: 'YOUR_ACTUAL_APP_ID',
  messagingSenderId: 'YOUR_ACTUAL_SENDER_ID',
  projectId: 'YOUR_ACTUAL_PROJECT_ID',
  storageBucket: 'YOUR_ACTUAL_PROJECT_ID.appspot.com',
);
```

### 7. Set Up Firestore Security Rules

1. Go to **Firestore Database** → **Rules** tab
2. **Replace** the default rules with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Attendance collection - users can only access their own data
    match /attendance/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;

      // Allow access to subcollections (year/month/day structure)
      match /{year}/{month}/{day} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

3. Click **"Publish"**

### 8. Test Your Setup

1. **Run** the app: `flutter run`
2. **Test** Google Sign-in
3. **Test** Email/Password authentication
4. **Test** attendance marking
5. **Check** Firestore for data

## Troubleshooting

### Common Issues:

1. **"Firebase not initialized"**:

    - Check if `google-services.json` is in `android/app/`
    - Verify Firebase configuration values

2. **"Authentication failed"**:

    - Check if Google Sign-in is enabled
    - Verify SHA-1 fingerprint (for Android)

3. **"Permission denied"**:
    - Check Firestore security rules
    - Ensure user is authenticated

### Getting SHA-1 Fingerprint (Android):

```bash
# Debug keystore
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# Release keystore (if you have one)
keytool -list -v -keystore path/to/your/release.keystore -alias your_alias
```

Add the SHA-1 fingerprint to Firebase Console → Project Settings → Your apps → Android app.

## Next Steps

Once Firebase is set up:

1. ✅ **Test authentication** (Google + Email/Password)
2. ✅ **Test attendance marking**
3. ✅ **Check data in Firestore**
4. ✅ **Test offline functionality**
5. ✅ **Deploy to production** (optional)

## Support

If you encounter issues:

-   Check Firebase Console for error logs
-   Verify all configuration files are in place
-   Ensure internet connection for initial setup
-   Check Flutter and Firebase package versions

---

**Your attendance tracking app is now ready to use Firebase! 🎉**
