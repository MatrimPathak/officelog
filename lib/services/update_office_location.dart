import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/office_model.dart';
import '../models/office_model.dart' as office_models;
import '../core/logger/app_logger.dart';

// Temporary service to update office location for testing
class UpdateOfficeLocation {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Call this function to update the office location to your coordinates
  static Future<void> updateToTestLocation() async {
    try {
      final testOffice = OfficeModel(
        id: 'office_1',
        name: 'PegaSystems Hyderabad',
        latitude: 17.438137076749936,
        longitude: 78.38346402527257,
        radius: 100, // 100 meters for easier testing
        timezone: 'Asia/Kolkata',
        createdAt: DateTime.now(),
      );

      // Update the office location
      await _firestore
          .collection('offices')
          .doc('office_1')
          .set(testOffice.toMap());

      // Get current user and assign them to this office
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // Create/update user profile with office assignment
        final userProfile = office_models.UserModel(
          uid: currentUser.uid,
          name: currentUser.displayName ?? 'User',
          email: currentUser.email ?? '',
          role: 'employee',
          officeId: 'office_1', // Assign to the office
          createdAt: DateTime.now(),
        );

        await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .set(userProfile.toMap(), SetOptions(merge: true));

        // Removed malformed log call
        // Removed malformed log call
        // Removed malformed log call
        // Removed malformed log call
      } else {
        // Removed malformed log call
      }
    } catch (e) {
      // Removed malformed log call
    }
  }
}
