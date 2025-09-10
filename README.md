# Employee Attendance Tracker

A Flutter mobile application for tracking employee attendance with Firebase integration.

## Features

### MLP 1 (Minimal Lovable Product 1)

-   ✅ Calendar display for current month
-   ✅ "Log Me In" button to mark attendance for today
-   ✅ Visual check marks (✅) for attended days
-   ✅ Attendance statistics (days attended, total days, percentage)
-   ✅ Clean and simple UI

### MLP 2 (Minimal Lovable Product 2)

-   ✅ Firebase Authentication (Google Sign-in & Email/Password)
-   ✅ Firebase Firestore for data persistence
-   ✅ Attendance data structure: userId, date, present: true
-   ✅ Cross-month attendance accumulation
-   ✅ Summary screen with monthly/yearly analysis
-   ✅ Real-time data synchronization

## Technical Stack

-   **Framework**: Flutter 3.9.0+
-   **State Management**: Provider
-   **Backend**: Firebase (Authentication + Firestore)
-   **UI Components**: Material Design 3
-   **Calendar**: table_calendar package
-   **Charts**: fl_chart package

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── firebase_options.dart     # Firebase configuration
├── providers/               # State management
│   ├── auth_provider.dart
│   └── attendance_provider.dart
├── services/                # Business logic
│   ├── auth_service.dart
│   └── attendance_service.dart
├── screens/                 # UI screens
│   ├── login_screen.dart
│   ├── home_screen.dart
│   └── summary_screen.dart
└── widgets/                  # Reusable components
    └── attendance_calendar.dart
```

## Setup Instructions

### 1. Prerequisites

-   Flutter SDK 3.9.0 or higher
-   Dart SDK
-   Android Studio / VS Code
-   Firebase project

### 2. Firebase Setup

1. **Create Firebase Project**

    - Go to [Firebase Console](https://console.firebase.google.com/)
    - Create a new project
    - Enable Authentication and Firestore Database

2. **Configure Authentication**

    - Go to Authentication > Sign-in method
    - Enable Google Sign-in
    - Enable Email/Password authentication

3. **Configure Firestore**

    - Go to Firestore Database
    - Create database in production mode
    - Set up security rules (see below)

4. **Get Firebase Configuration**
    - Install FlutterFire CLI: `dart pub global activate flutterfire_cli`
    - Run: `flutterfire configure`
    - Select your Firebase project and platforms (Android, iOS)

### 3. Install Dependencies

```bash
flutter pub get
```

### 4. Update Firebase Configuration

Replace the placeholder values in `lib/firebase_options.dart` with your actual Firebase configuration:

```dart
// Update these values with your Firebase project details
apiKey: 'your-actual-api-key',
appId: 'your-actual-app-id',
messagingSenderId: 'your-actual-sender-id',
projectId: 'your-actual-project-id',
```

### 5. Run the App

```bash
flutter run
```

## Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Attendance collection - users can only access their own data
    match /attendance/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;

      // Allow access to subcollections
      match /{year}/{month}/{day} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

## Data Model

### Firestore Structure

```
attendance/
  └── {userId}/
      └── {year}/
          └── {month}/
              └── days/
                  └── {day}/
                      ├── present: true
                      └── timestamp: serverTimestamp
```

### Example Queries

1. **Mark attendance for today**

```dart
await FirebaseFirestore.instance
    .collection('attendance')
    .doc(userId)
    .collection(year.toString())
    .doc(month.toString().padLeft(2, '0'))
    .collection('days')
    .doc(day.toString().padLeft(2, '0'))
    .set({'present': true, 'timestamp': FieldValue.serverTimestamp()});
```

2. **Get monthly attendance**

```dart
final snapshot = await FirebaseFirestore.instance
    .collection('attendance')
    .doc(userId)
    .collection(year.toString())
    .doc(month.toString().padLeft(2, '0'))
    .collection('days')
    .get();
```

## Features Overview

### Authentication

-   Google Sign-in integration
-   Email/Password authentication
-   Password reset functionality
-   User profile management

### Attendance Tracking

-   One-click attendance marking
-   Duplicate prevention (can't mark same day twice)
-   Real-time calendar updates
-   Offline support with sync

### Analytics

-   Monthly attendance percentage
-   Yearly summary with charts
-   Best month identification
-   Average monthly attendance

### UI/UX

-   Material Design 3
-   Responsive layout
-   Dark/Light theme support
-   Accessibility features
-   Pull-to-refresh functionality

## Development Notes

### State Management

-   Uses Provider pattern for state management
-   Separate providers for authentication and attendance
-   Reactive UI updates with ChangeNotifier

### Error Handling

-   Comprehensive error handling with user-friendly messages
-   Loading states for better UX
-   Offline error handling

### Performance

-   Firestore offline persistence enabled
-   Efficient data queries
-   Optimized calendar rendering
-   Lazy loading for large datasets

## Future Enhancements

-   [ ] Push notifications for attendance reminders
-   [ ] Export attendance data (CSV/PDF)
-   [ ] Admin dashboard for multiple employees
-   [ ] Attendance reports and analytics
-   [ ] Integration with HR systems
-   [ ] Biometric authentication
-   [ ] Location-based attendance
-   [ ] Team attendance views

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

-   [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
-   [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
