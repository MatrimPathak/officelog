# Geofence Testing Setup Guide

## Quick Test Steps

### 1. Using Built-in Test Feature

1. Open app → Settings
2. Enable "Location-based Check-in"
3. Grant location permissions
4. Tap "Test Location"
5. View results (distance, within range, can auto check-in)

### 2. Change Office Location (for testing)

If you want to test with a different location, you can update the office coordinates in Firestore:

#### Option A: Through Firebase Console

1. Go to Firebase Console → Firestore Database
2. Find `offices/office_1` document
3. Update `latitude` and `longitude` fields
4. Update `radius` if needed (default: 200 meters)

#### Option B: Through Code (temporary for testing)

Update the coordinates in `lib/services/office_service.dart`:

```dart
final defaultOffice = OfficeModel(
  id: 'office_1',
  name: 'Your Test Office',
  latitude: YOUR_LATITUDE,    // Replace with your coordinates
  longitude: YOUR_LONGITUDE,  // Replace with your coordinates
  radius: 50,                 // Smaller radius for easier testing
  timezone: 'Asia/Kolkata',
  createdAt: DateTime.now(),
);
```

### 3. Testing Scenarios

#### Test Case 1: Inside Geofence

-   **Expected**: Auto check-in triggers
-   **Notification**: "Auto check-in successful"
-   **Calendar**: Date marked with attendance
-   **Method**: Shows as "auto"

#### Test Case 2: Outside Geofence

-   **Expected**: No auto check-in
-   **Test Result**: Shows distance > radius
-   **Status**: "Outside office range"

#### Test Case 3: Already Checked In

-   **Expected**: No duplicate check-in
-   **Behavior**: Prevents multiple auto check-ins per day

### 4. Debug Information

The test feature provides:

-   **Current Location**: Your lat/lng
-   **Office Location**: Office lat/lng
-   **Distance**: Calculated distance in meters
-   **Within Range**: Boolean (true/false)
-   **Can Auto Check-in**: Considers working day + not already checked in

### 5. Troubleshooting

**Location Permission Issues:**

-   Check app permissions in device settings
-   Ensure "Allow all the time" for background location

**Not Working on Emulator:**

-   Set location manually in emulator settings
-   Use extended controls to simulate movement

**Auto Check-in Not Triggering:**

-   Check if it's a working day
-   Verify not already checked in today
-   Confirm geofence is enabled in settings

### 6. Real-world Testing Tips

1. **Start Outside**: Begin testing outside the geofence
2. **Walk Into Range**: Move within the radius gradually
3. **Check Logs**: Watch for auto check-in notifications
4. **Verify Database**: Check Firestore for new attendance record

### 7. Get Your Current Location

To find your current coordinates for testing:

1. Open Google Maps
2. Long press on your location
3. Copy the coordinates (lat, lng)
4. Update office location in Firebase/code

### 8. Testing with Different Radii

-   **Small (50m)**: Good for precise testing
-   **Medium (200m)**: Default, good for office buildings
-   **Large (500m)**: Good for campus/complex testing
