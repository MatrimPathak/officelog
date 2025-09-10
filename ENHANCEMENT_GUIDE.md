# Flutter Attendance Tracker - Enhanced Features Guide

## 🎉 New Features Overview

This enhanced version of the Flutter Attendance Tracker includes the following new features:

### ✨ Features Added

1. **Central Holiday List**

    - Global holiday list stored in Firebase Firestore
    - Holidays automatically fetched and displayed in calendar (highlighted with accent color)
    - Local caching for offline access
    - Automatic refresh when holidays are updated

2. **Daily Reminder Notifications**

    - Local notifications reminding users to log attendance
    - Default reminder time: 10:00 AM (configurable)
    - Smart suppression when attendance is already logged
    - Automatic adaptation to dark/light theme

3. **Geo-location Based Auto Check-in**

    - Define office locations with latitude, longitude, and radius
    - Automatic attendance logging when entering office geofence
    - Prevents duplicate logs for multiple entries/exits
    - Shows toast notification on successful auto check-in

4. **Offline-first Support**
    - Attendance logging works without internet connection
    - Local storage using SharedPreferences for offline data
    - Automatic sync when back online
    - Conflict resolution (keeps latest version)
    - Visual indicators for unsynced logs (dashed outline)

### 📱 UI/UX Enhancements

-   **Calendar Improvements:**

    -   Holidays highlighted with accent color (yellow)
    -   Logged-in days show green check marks
    -   Today outlined with primary color
    -   Selected day highlighted with secondary color
    -   Offline unsynced logs show dashed outline

-   **Status Card:**

    -   Shows offline sync status with count
    -   Displays today's holiday information
    -   Geofence status with auto check-in button
    -   One-click sync for offline data

-   **Settings Screen:**
    -   Configure notification time and enable/disable
    -   Toggle geofence-based auto check-in
    -   Test location functionality
    -   Sync offline data manually
    -   Dark/light theme toggle

## 🔧 Setup Instructions

### 1. Dependencies Installation

The following dependencies have been added to `pubspec.yaml`:

```yaml
# Notifications
flutter_local_notifications: ^17.2.2
timezone: ^0.9.4

# Geolocation
geolocator: ^12.0.0
permission_handler: ^11.3.1

# Background tasks
workmanager: ^0.5.2
```

### 2. Android Permissions

Added to `android/app/src/main/AndroidManifest.xml`:

```xml
<!-- Notifications -->
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>

<!-- Geolocation -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />

<!-- Background work -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />
```

### 3. Firestore Schema

#### Users Collection

```javascript
users/{uid}
{
  name: "John Doe",
  email: "john@example.com",
  role: "employee",
  createdAt: "2025-09-07T10:00:00Z",
  officeId: "office_1"
}
```

#### Attendance Subcollection

```javascript
users/{uid}/attendance/{YYYY-MM-DD}
{
  date: "2025-09-07",
  status: "present",     // present | holiday | absent | auto_present
  method: "manual",      // manual | auto | offline
  note: "Logged in automatically via geofence",
  synced: true,
  createdAt: "2025-09-07T09:15:00Z"
}
```

#### Holidays Collection

```javascript
holidays/{holidayId or YYYY-MM-DD}
{
  date: "2025-12-25",
  name: "Christmas Day",
  isRecurring: true,
  country: "IN",
  createdBy: "admin_uid"
}
```

#### Offices Collection

```javascript
offices/{officeId}
{
  name: "Hyderabad HQ",
  latitude: 17.385044,
  longitude: 78.486671,
  radius: 200,
  timezone: "Asia/Kolkata"
}
```

## 🚀 Getting Started

### 1. Install Dependencies

```bash
flutter pub get
```

### 2. Run the App

```bash
flutter run
```

### 3. Initial Setup

1. **Default Data Initialization:**

    - App automatically creates default holidays and office location on first run
    - Default office location: Hyderabad HQ (17.385044, 78.486671) with 200m radius

2. **Notification Setup:**

    - App requests notification permissions on startup
    - Default reminder set to 10:00 AM
    - Can be customized in Settings screen

3. **Location Setup:**
    - App requests location permissions when geofence is enabled
    - Users can test their location relative to office in Settings

## 📋 How to Use New Features

### Holiday Management

-   Holidays are automatically loaded and cached
-   Calendar shows holidays with accent color highlights
-   Holiday information displays in status card when applicable

### Notification Setup

1. Go to Settings → Notifications
2. Toggle "Daily Reminder" on/off
3. Tap "Reminder Time" to set custom time
4. Notifications automatically suppress if attendance already logged

### Auto Check-in Setup

1. Go to Settings → Auto Check-in
2. Toggle "Location-based Check-in" on
3. Grant location permissions when prompted
4. Use "Test Location" to verify you're within office range
5. App will automatically log attendance when you enter office geofence

### Offline Usage

1. Log attendance normally even without internet
2. Offline logs show with dashed outline in calendar
3. Status card shows count of unsynced records
4. Tap "Sync" to manually sync when online
5. App auto-syncs when internet connection restored

### Status Monitoring

-   Status card shows:
    -   Offline sync status with count and sync button
    -   Today's holiday information
    -   Geofence status with auto check-in option

## 🏗️ Architecture

### New Services Added:

-   `HolidayService`: Manages holiday data with caching
-   `NotificationService`: Handles local notifications
-   `GeolocationService`: Manages location-based features
-   `OfficeService`: Handles office and user profile data

### New Models Added:

-   `AttendanceModel`: Enhanced attendance with sync status
-   `HolidayModel`: Holiday data with recurring support
-   `OfficeModel`: Office location data
-   `UserModel`: User profile with office assignment

### Enhanced Providers:

-   `AttendanceProvider`: Added offline sync and geolocation methods
-   `HolidayProvider`: New provider for holiday management

## 🔧 Configuration

### Default Settings:

-   Reminder time: 10:00 AM
-   Office location: Hyderabad HQ
-   Geofence radius: 200 meters
-   Cache validity: 24 hours (holidays), 6 hours (offices)

### Customizable Options:

-   Notification time and enable/disable
-   Geofence enable/disable
-   Theme (dark/light mode)
-   Manual sync triggers

## 🐛 Troubleshooting

### Common Issues:

1. **Notifications not working:**

    - Check app notification permissions in device settings
    - Verify notification service initialization

2. **Auto check-in not working:**

    - Ensure location permissions granted (including background location)
    - Test location to verify within office range
    - Check if geofence monitoring is enabled

3. **Offline sync issues:**

    - Check internet connection
    - Try manual sync from Settings or status card
    - Verify Firestore connectivity

4. **Holiday not showing:**
    - Check internet connection for initial holiday fetch
    - Holidays cache for 24 hours, may need refresh

## 📱 Testing Features

### Notification Testing:

1. Set reminder time to near future
2. Close app and wait for notification
3. Verify notification shows and can be tapped

### Geofence Testing:

1. Go to Settings → Auto Check-in → Test Location
2. View distance and range status
3. Move within/outside office radius to test

### Offline Testing:

1. Turn off internet connection
2. Log attendance (should work offline)
3. Turn on internet and verify sync

## 🎯 Best Practices

1. **For Users:**

    - Keep location services enabled for auto check-in
    - Allow notification permissions for reminders
    - Regularly sync offline data when online

2. **For Administrators:**
    - Configure office locations with appropriate radius
    - Add relevant holidays for your region
    - Monitor user profiles and office assignments

## 🔒 Privacy & Security

-   Location data used only for geofence detection
-   No location tracking or storage
-   Offline data encrypted in local storage
-   All network requests use Firebase security rules

## 📊 Performance Considerations

-   Holiday data cached locally (24-hour validity)
-   Office data cached locally (6-hour validity)
-   Offline data stored efficiently in SharedPreferences
-   Background location monitoring optimized for battery life
-   Automatic sync prevents data accumulation

---

**Need Help?** Check the troubleshooting section or review the code comments for detailed implementation details.
