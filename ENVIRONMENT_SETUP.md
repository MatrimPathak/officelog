# Environment Variables Setup

This project uses environment variables to securely store API keys and configuration values. Follow these steps to set up your environment:

## 1. Create Environment File

Copy the example configuration file:
```bash
cp config.env.example config.env
```

## 2. Configure Firebase

Replace the placeholder values in `config.env` with your actual Firebase project configuration:

### Get Firebase Configuration:
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project (or create a new one)
3. Go to Project Settings (gear icon)
4. In the "General" tab, scroll down to "Your apps"
5. For each platform (Web, Android, iOS), copy the configuration values

### Required Environment Variables:

```env
# Firebase Project Information
FIREBASE_PROJECT_ID=your-actual-project-id
FIREBASE_PROJECT_NUMBER=your-project-number
FIREBASE_MESSAGING_SENDER_ID=your-sender-id
FIREBASE_STORAGE_BUCKET=your-project-id.appspot.com
FIREBASE_AUTH_DOMAIN=your-project-id.firebaseapp.com

# Firebase API Keys (Platform-specific)
FIREBASE_WEB_API_KEY=your-web-api-key
FIREBASE_ANDROID_API_KEY=your-android-api-key
FIREBASE_IOS_API_KEY=your-ios-api-key

# Firebase App IDs (Platform-specific)
FIREBASE_WEB_APP_ID=your-web-app-id
FIREBASE_ANDROID_APP_ID=your-android-app-id
FIREBASE_IOS_APP_ID=your-ios-app-id

# Bundle/Package Identifiers
IOS_BUNDLE_ID=com.yourcompany.yourapp
ANDROID_PACKAGE_NAME=com.yourcompany.yourapp
```

## 3. Update Google Services Files

### Android:
1. Download `google-services.json` from Firebase Console
2. Place it in `android/app/google-services.json`

### iOS:
1. Download `GoogleService-Info.plist` from Firebase Console
2. Place it in `ios/Runner/GoogleService-Info.plist`

## 4. Security Notes

- **NEVER** commit your actual `config.env` file to version control
- The `config.env` file is already added to `.gitignore`
- Only commit the `config.env.example` template file
- Each team member should create their own `config.env` file

## 5. Troubleshooting

If you see Firebase initialization errors:
1. Verify all environment variables are set correctly
2. Ensure `config.env` file is in the project root
3. Check that the file is included in `pubspec.yaml` assets
4. Make sure Firebase project is properly configured

## 6. Production Deployment

For production deployments:
- Use your CI/CD platform's environment variable system
- Set all required environment variables in your deployment pipeline
- Never expose sensitive keys in your deployment logs
