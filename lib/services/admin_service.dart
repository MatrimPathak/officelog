import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Service to handle admin user verification and admin-related operations
class AdminService {
  static const String _adminConfigCollection = 'admin_config';
  static const String _adminUsersDoc = 'admin_users';

  // Hardcoded admin emails as fallback (can be moved to Firebase config)
  static const List<String> _hardcodedAdminEmails = [
    'matrimpathak1999@gmail.com',
    // Add more admin emails here
  ];

  /// Check if the current user is an admin
  static Future<bool> isCurrentUserAdmin() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      return await isUserAdmin(user.uid, user.email);
    } catch (e) {
      debugPrint('Error checking admin status: $e');
      return false;
    }
  }

  /// Check if a specific user is an admin
  static Future<bool> isUserAdmin(String userId, String? email) async {
    try {
      // First check hardcoded admin emails
      if (email != null &&
          _hardcodedAdminEmails.contains(email.toLowerCase())) {
        return true;
      }

      // Then check Firebase admin configuration
      final adminDoc = await FirebaseFirestore.instance
          .collection(_adminConfigCollection)
          .doc(_adminUsersDoc)
          .get();

      if (adminDoc.exists) {
        final data = adminDoc.data() as Map<String, dynamic>;
        final adminUids = List<String>.from(data['admin_uids'] ?? []);
        final adminEmails = List<String>.from(data['admin_emails'] ?? []);

        // Check by UID
        if (adminUids.contains(userId)) {
          return true;
        }

        // Check by email
        if (email != null && adminEmails.contains(email.toLowerCase())) {
          return true;
        }
      }

      return false;
    } catch (e) {
      debugPrint('Error checking admin status from Firebase: $e');

      // Fallback to hardcoded check if Firebase fails
      if (email != null &&
          _hardcodedAdminEmails.contains(email.toLowerCase())) {
        return true;
      }

      return false;
    }
  }

  /// Add a user as admin (only callable by existing admins)
  static Future<bool> addAdminUser(String userId, String email) async {
    try {
      if (!await isCurrentUserAdmin()) {
        debugPrint('Current user is not admin - cannot add admin users');
        return false;
      }

      final adminDocRef = FirebaseFirestore.instance
          .collection(_adminConfigCollection)
          .doc(_adminUsersDoc);

      await adminDocRef.set({
        'admin_uids': FieldValue.arrayUnion([userId]),
        'admin_emails': FieldValue.arrayUnion([email.toLowerCase()]),
        'updated_at': FieldValue.serverTimestamp(),
        'updated_by': FirebaseAuth.instance.currentUser?.uid,
      }, SetOptions(merge: true));

      debugPrint('Successfully added admin user: $email');
      return true;
    } catch (e) {
      debugPrint('Error adding admin user: $e');
      return false;
    }
  }

  /// Remove a user from admin (only callable by existing admins)
  static Future<bool> removeAdminUser(String userId, String email) async {
    try {
      if (!await isCurrentUserAdmin()) {
        debugPrint('Current user is not admin - cannot remove admin users');
        return false;
      }

      // Prevent removing hardcoded admins
      if (_hardcodedAdminEmails.contains(email.toLowerCase())) {
        debugPrint('Cannot remove hardcoded admin: $email');
        return false;
      }

      final adminDocRef = FirebaseFirestore.instance
          .collection(_adminConfigCollection)
          .doc(_adminUsersDoc);

      await adminDocRef.update({
        'admin_uids': FieldValue.arrayRemove([userId]),
        'admin_emails': FieldValue.arrayRemove([email.toLowerCase()]),
        'updated_at': FieldValue.serverTimestamp(),
        'updated_by': FirebaseAuth.instance.currentUser?.uid,
      });

      debugPrint('Successfully removed admin user: $email');
      return true;
    } catch (e) {
      debugPrint('Error removing admin user: $e');
      return false;
    }
  }

  /// Get all admin users
  static Future<List<Map<String, dynamic>>> getAllAdminUsers() async {
    try {
      if (!await isCurrentUserAdmin()) {
        return [];
      }

      final adminDoc = await FirebaseFirestore.instance
          .collection(_adminConfigCollection)
          .doc(_adminUsersDoc)
          .get();

      List<Map<String, dynamic>> adminUsers = [];

      // Add hardcoded admins
      for (final email in _hardcodedAdminEmails) {
        adminUsers.add({
          'email': email,
          'type': 'hardcoded',
          'removable': false,
        });
      }

      // Add Firebase admins
      if (adminDoc.exists) {
        final data = adminDoc.data() as Map<String, dynamic>;
        final adminEmails = List<String>.from(data['admin_emails'] ?? []);

        for (final email in adminEmails) {
          if (!_hardcodedAdminEmails.contains(email)) {
            adminUsers.add({
              'email': email,
              'type': 'firebase',
              'removable': true,
            });
          }
        }
      }

      return adminUsers;
    } catch (e) {
      debugPrint('Error getting admin users: $e');
      return [];
    }
  }

  /// Show admin access denied message
  static void showAccessDeniedMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔒 Admin access required'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Initialize default admin configuration
  static Future<void> initializeAdminConfig() async {
    try {
      final adminDocRef = FirebaseFirestore.instance
          .collection(_adminConfigCollection)
          .doc(_adminUsersDoc);

      final doc = await adminDocRef.get();
      if (!doc.exists) {
        // Create initial admin configuration
        await adminDocRef.set({
          'admin_emails': _hardcodedAdminEmails,
          'admin_uids': [], // Will be populated when admins first login
          'created_at': FieldValue.serverTimestamp(),
          'version': '1.0',
        });

        debugPrint('Initialized admin configuration');
      }
    } catch (e) {
      debugPrint('Error initializing admin config: $e');
    }
  }
}
