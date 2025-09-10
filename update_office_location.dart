// Quick script to update office location for testing
// Add this to a temporary test file or run in Firebase Console

import 'lib/models/office_model.dart';

/*
To update office location for testing:

1. Get your current coordinates:
   - Open Google Maps
   - Long press on your location
   - Copy coordinates (e.g., "12.9716, 77.5946")

2. Update in Firebase Console:
   - Go to Firestore Database
   - Navigate to: offices/office_1
   - Update fields:
     - latitude: YOUR_LATITUDE
     - longitude: YOUR_LONGITUDE
     - radius: 50 (for easier testing)

3. Or update in code temporarily:
   In lib/services/office_service.dart, line 284-292:
*/

final testOffice = OfficeModel(
  id: 'office_1',
  name: 'Test Office Location',
  latitude: 12.9716, // Replace with your coordinates
  longitude: 77.5946, // Replace with your coordinates
  radius: 50, // Small radius for easy testing
  timezone: 'Asia/Kolkata',
  createdAt: DateTime.now(),
);

/*
Example coordinates for testing:
- Bangalore: 12.9716, 77.5946
- Mumbai: 19.0760, 72.8777
- Delhi: 28.7041, 77.1025
- Hyderabad: 17.385044, 78.486671 (current default)

After updating, restart the app and test again.
*/
