# Background Auto Check-in Setup Guide

## 🎯 Overview

OfficeLog now supports **true background geofencing** that automatically logs attendance when you enter your office area - even when the app is closed or the phone is locked!

## ✨ Features

-   **🔄 Background Monitoring**: Works even when app is killed
-   **📍 Geofence Detection**: 200m radius around office (configurable)
-   **🔔 Auto Notifications**: "✅ Auto login successful for Sept 7"
-   **📱 Widget Updates**: Home screen widgets refresh automatically
-   **🌐 Offline Support**: Saves attendance locally, syncs when online
-   **🔋 Battery Optimized**: Uses efficient background location services

## 📋 Setup Instructions

### 1. Install Dependencies

The following packages have been added for background geofencing:

```yaml
# Background geofencing
geofence_service: ^5.2.1
background_locator_2: ^2.1.7
workmanager: ^0.5.2
```

Run `flutter pub get` to install.

### 2. Enable Background Auto Check-in

1. Open OfficeLog app
2. Go to **Settings** → **Auto Check-in**
3. Toggle **"Background Auto Check-in"** ON
4. Grant location permissions when prompted:
    - **Android**: Allow "All the time" location access
    - **iOS**: Choose "Allow While Using App" then "Change to Always Allow"

### 3. Test Setup

1. In Settings → Auto Check-in → **"Test Location"**
2. Verify you see:
    - Your current coordinates
    - Distance to office
    - "Within office range" status
    - "Auto check-in available" (if it's a working day)

## 🔧 How It Works

### Background Flow

```
1. User enters office geofence (200m radius)
   ↓
2. Background service detects entry
   ↓
3. Checks if it's a working day
   ↓
4. Checks if not already checked in
   ↓
5. Logs attendance to Firebase
   ↓
6. Shows notification: "✅ Auto login successful"
   ↓
7. Updates home screen widgets
   ↓
8. If offline: Saves locally, syncs later
```

### Attendance Data Structure

```javascript
{
  date: "2025-09-07",
  status: "auto_present",
  method: "geofence",
  note: "Auto check-in via geofence",
  synced: true,
  createdAt: "2025-09-07T09:15:00Z"
}
```

## 🔐 Permissions Required

### Android

-   `ACCESS_FINE_LOCATION`
-   `ACCESS_BACKGROUND_LOCATION`
-   `FOREGROUND_SERVICE_LOCATION`
-   `WAKE_LOCK`
-   `RECEIVE_BOOT_COMPLETED`

### iOS

-   `NSLocationAlwaysAndWhenInUseUsageDescription`
-   `NSLocationWhenInUseUsageDescription`
-   `NSLocationAlwaysUsageDescription`
-   Background modes: `location`, `background-processing`

## 🧪 Testing Guide

### Test Scenarios

#### ✅ Scenario 1: Inside Office Range

-   **Setup**: Be within 200m of office coordinates
-   **Expected**: Auto check-in triggers
-   **Notification**: "✅ Auto login successful for Sept 7"
-   **Result**: Attendance marked, widget updated

#### ❌ Scenario 2: Outside Office Range

-   **Setup**: Be >200m from office coordinates
-   **Expected**: No auto check-in
-   **Test Result**: Shows "Outside office range"

#### 🔄 Scenario 3: Already Checked In

-   **Setup**: Already have attendance for today
-   **Expected**: No duplicate check-in
-   **Behavior**: Prevents multiple entries per day

#### 📴 Scenario 4: Offline Mode

-   **Setup**: Turn off internet, enter office
-   **Expected**: Attendance saved locally
-   **Later**: Auto-syncs when online

### Testing on Emulator

1. **Android Studio Emulator**:

    - Use Extended Controls → Location
    - Set custom coordinates near office
    - Simulate movement into geofence

2. **iOS Simulator**:
    - Debug → Location → Custom Location
    - Enter office coordinates
    - Simulate geofence entry

### Testing on Physical Device

1. **Update Office Location** (for testing):

    ```dart
    // In Firebase Console or update_office_location.dart
    latitude: YOUR_CURRENT_LATITUDE,
    longitude: YOUR_CURRENT_LONGITUDE,
    radius: 50, // Smaller radius for testing
    ```

2. **Walk Test**:
    - Start outside 200m from office
    - Walk into range
    - Watch for auto check-in notification

## 🎛️ Configuration

### Office Location Setup

Update office coordinates in Firebase:

```javascript
// offices/office_1
{
  name: "Your Office Name",
  latitude: 17.385044,
  longitude: 78.486671,
  radius: 200, // meters
  timezone: "Asia/Kolkata"
}
```

### Geofence Settings

Modify in `BackgroundGeofenceService`:

```dart
// Check interval (default: 5 seconds)
interval: 5000,

// Location accuracy (default: 100m)
accuracy: 100,

// Loitering delay (default: 1 minute)
loiteringDelayMs: 60000,
```

## 🔧 Troubleshooting

### Common Issues

**❌ Auto check-in not working**

-   ✅ Check location permissions are "Always Allow"
-   ✅ Verify geofencing is enabled in Settings
-   ✅ Test location shows "Within office range"
-   ✅ Check it's a working day
-   ✅ Ensure not already checked in

**❌ Notifications not showing**

-   ✅ Check notification permissions
-   ✅ Verify app not in battery optimization
-   ✅ Test with manual notification first

**❌ Background service stops**

-   ✅ Disable battery optimization for OfficeLog
-   ✅ Check "Allow background activity"
-   ✅ Restart app to reinitialize service

**❌ Location permissions denied**

-   ✅ Go to device Settings → Apps → OfficeLog → Permissions
-   ✅ Enable Location → "Allow all the time"
-   ✅ Restart app after permission change

### Debug Information

Check logs for:

```
🎯 Geofence event: ENTER
🏢 User entered office area
✅ Auto check-in saved online
🎉 Auto check-in completed successfully
```

### Battery Optimization

**Android**:

1. Settings → Apps → OfficeLog → Battery
2. Choose "Don't optimize" or "Unrestricted"

**iOS**:

-   Background app refresh should be enabled
-   Low power mode may affect background processing

## 📊 Monitoring

### Check Background Service Status

```dart
// In app, check if monitoring is active
final isActive = await BackgroundGeofenceService.isMonitoring();
```

### Sync Offline Data

-   Settings → Data Management → "Sync Offline Data"
-   Shows count of unsynced records
-   One-tap sync when connection available

### Widget Updates

-   Home screen widgets automatically refresh
-   Shows latest attendance percentage
-   Calendar view updates with new check-ins

## 🔄 Migration from Old System

The new background geofencing system:

-   ✅ **Replaces** basic location checking
-   ✅ **Adds** true background monitoring
-   ✅ **Maintains** compatibility with existing data
-   ✅ **Improves** battery efficiency
-   ✅ **Enhances** reliability

Old geofence settings will be automatically migrated when you enable the new background system.

## 🚀 Production Deployment

### Release Checklist

-   [ ] Test on multiple devices
-   [ ] Verify permissions in app stores
-   [ ] Test battery optimization scenarios
-   [ ] Validate offline sync functionality
-   [ ] Check notification delivery
-   [ ] Test widget updates

### App Store Requirements

**Google Play**:

-   Declare background location usage
-   Provide clear permission rationale
-   Test on Android 10+ for background restrictions

**Apple App Store**:

-   Justify background location usage
-   Provide clear user benefit explanation
-   Test on iOS 14+ for app tracking transparency

---

## 🎉 Success Metrics

When working correctly, you should see:

-   ✅ Automatic attendance logging without opening app
-   🔔 Timely notifications: "Auto login successful"
-   📱 Updated home screen widgets
-   📊 Accurate attendance statistics
-   🌐 Seamless offline/online sync

**The goal**: Walk into office → Automatic check-in → Notification → Widget update → All without touching your phone! 📱✨
