import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/office_model.dart';
import 'dart:convert';
import '../core/logger/app_logger.dart';

class OfficeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _cacheKey = 'cached_offices';
  static const String _userCacheKey = 'cached_user_profile';
  static const String _lastSyncKey = 'offices_last_sync';
  static const Duration _cacheValidityDuration = Duration(hours: 6);

  // Get user's office information
  Future<OfficeModel?> getUserOffice(String userId) async {
    try {
      // Get user profile to find office ID
      final user = await getUserProfile(userId);
      if (user?.officeId == null) {
        // Auto-assign user to default office if not assigned
        await _autoAssignUserToDefaultOffice(userId);
        final updatedUser = await getUserProfile(userId);
        if (updatedUser?.officeId == null) return null;
        return await getOfficeById(updatedUser!.officeId!);
      }

      // Get office details
      return await getOfficeById(user!.officeId!);
    } catch (e) {
      throw Exception('Failed to get user office: $e');
    }
  }

  // Get office by ID
  Future<OfficeModel?> getOfficeById(String officeId) async {
    try {
      // Check cache first
      final cachedOffices = await _getCachedOffices();
      if (cachedOffices != null && !await _needsRefresh()) {
        final office = cachedOffices.firstWhere(
          (office) => office.id == officeId,
          orElse: () => throw StateError('Office not found in cache'),
        );
        return office;
      }

      // Fetch from Firestore
      final doc = await _firestore.collection('offices').doc(officeId).get();
      if (!doc.exists) return null;

      return OfficeModel.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }

  // Get all offices
  Future<List<OfficeModel>> getAllOffices() async {
    try {
      // Check cache first
      final cachedOffices = await _getCachedOffices();
      if (cachedOffices != null && !await _needsRefresh()) {
        return cachedOffices;
      }

      // Fetch from Firestore
      final offices = await _fetchOfficesFromFirestore();

      // Cache the results
      await _cacheOffices(offices);

      return offices;
    } catch (e) {
      // If network fails, try to return cached data
      final cachedOffices = await _getCachedOffices();
      if (cachedOffices != null) {
        return cachedOffices;
      }
      throw Exception('Failed to load offices: $e');
    }
  }

  // Get user profile
  Future<UserModel?> getUserProfile(String userId) async {
    try {
      // Check cache first
      final cachedUser = await _getCachedUserProfile();
      if (cachedUser != null &&
          cachedUser.uid == userId &&
          !await _needsRefresh()) {
        return cachedUser;
      }

      // Fetch from Firestore
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;

      final user = UserModel.fromFirestore(doc);

      // Cache the result
      await _cacheUserProfile(user);

      return user;
    } catch (e) {
      // If network fails, try to return cached data
      final cachedUser = await _getCachedUserProfile();
      if (cachedUser != null && cachedUser.uid == userId) {
        return cachedUser;
      }
      return null;
    }
  }

  // Create or update user profile
  Future<void> saveUserProfile(UserModel user) async {
    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(user.toMap(), SetOptions(merge: true));

      // Update cache
      await _cacheUserProfile(user);
    } catch (e) {
      throw Exception('Failed to save user profile: $e');
    }
  }

  // Add a new office (admin function)
  Future<void> addOffice(OfficeModel office) async {
    try {
      await _firestore.collection('offices').doc(office.id).set(office.toMap());

      // Clear cache to force refresh
      await _clearCache();
    } catch (e) {
      throw Exception('Failed to add office: $e');
    }
  }

  // Update an office (admin function)
  Future<void> updateOffice(OfficeModel office) async {
    try {
      await _firestore
          .collection('offices')
          .doc(office.id)
          .update(office.toMap());

      // Clear cache to force refresh
      await _clearCache();
    } catch (e) {
      throw Exception('Failed to update office: $e');
    }
  }

  // Delete an office (admin function)
  Future<void> deleteOffice(String officeId) async {
    try {
      await _firestore.collection('offices').doc(officeId).delete();

      // Clear cache to force refresh
      await _clearCache();
    } catch (e) {
      throw Exception('Failed to delete office: $e');
    }
  }

  // Assign user to office
  Future<void> assignUserToOffice(String userId, String officeId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'officeId': officeId,
      });

      // Clear user cache to force refresh
      await _clearUserCache();
    } catch (e) {
      throw Exception('Failed to assign user to office: $e');
    }
  }

  // Private methods
  Future<List<OfficeModel>> _fetchOfficesFromFirestore() async {
    final snapshot = await _firestore.collection('offices').get();
    return snapshot.docs.map((doc) => OfficeModel.fromFirestore(doc)).toList();
  }

  Future<List<OfficeModel>?> _getCachedOffices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_cacheKey);

      if (cachedData == null) return null;

      final List<dynamic> officeMaps = json.decode(cachedData);
      return officeMaps
          .map((map) => OfficeModel.fromMap(map, map['id']))
          .toList();
    } catch (e) {
      return null;
    }
  }

  Future<void> _cacheOffices(List<OfficeModel> offices) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final officeMaps = offices.map((office) {
        final map = office.toMap();
        map['id'] = office.id; // Include ID in the map
        return map;
      }).toList();

      await prefs.setString(_cacheKey, json.encode(officeMaps));
      await prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      // Ignore cache errors
    }
  }

  Future<UserModel?> _getCachedUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_userCacheKey);

      if (cachedData == null) return null;

      final Map<String, dynamic> userMap = json.decode(cachedData);
      return UserModel.fromMap(userMap, userMap['uid']);
    } catch (e) {
      return null;
    }
  }

  Future<void> _cacheUserProfile(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userMap = user.toMap();
      userMap['uid'] = user.uid; // Include UID in the map

      await prefs.setString(_userCacheKey, json.encode(userMap));
    } catch (e) {
      // Ignore cache errors
    }
  }

  Future<bool> _needsRefresh() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSync = prefs.getInt(_lastSyncKey);

      if (lastSync == null) return true;

      final lastSyncTime = DateTime.fromMillisecondsSinceEpoch(lastSync);
      final now = DateTime.now();

      return now.difference(lastSyncTime) > _cacheValidityDuration;
    } catch (e) {
      return true; // If can't check, assume needs refresh
    }
  }

  Future<void> _clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_lastSyncKey);
    } catch (e) {
      // Ignore cache errors
    }
  }

  Future<void> _clearUserCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userCacheKey);
    } catch (e) {
      // Ignore cache errors
    }
  }

  // Initialize default office (call this once during app setup)
  Future<void> initializeDefaultOffice() async {
    try {
      // Check if offices already exist
      final snapshot = await _firestore.collection('offices').limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        return; // Offices already exist
      }

      // Add a default office
      final defaultOffice = OfficeModel(
        id: 'office_1',
        name: 'PegaSystems Hyderabad',
        latitude: 17.438137076749936,
        longitude: 78.38346402527257,
        radius: 100, // Smaller radius for easier testing
        timezone: 'Asia/Kolkata',
        createdAt: DateTime.now(),
      );

      await addOffice(defaultOffice);
    } catch (e) {
      AppLogger.error('Operation failed: $e', tag: 'OfficeService');
    }
  }

  // Auto-assign user to default office if not assigned
  Future<void> _autoAssignUserToDefaultOffice(String userId) async {
    try {
      // Get current user info from Firebase Auth
      final authUser = await _getFirebaseAuthUser(userId);
      if (authUser == null) return;

      // Create user profile with office assignment
      final userProfile = UserModel(
        uid: userId,
        name: authUser['displayName'] ?? 'User',
        email: authUser['email'] ?? '',
        role: 'employee',
        officeId: 'office_1', // Assign to default office
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(userId)
          .set(userProfile.toMap(), SetOptions(merge: true));

      AppLogger.info('User auto-assigned to office: ${authUser['email']}', tag: 'OfficeService');
    } catch (e) {
      AppLogger.error('Operation failed: $e', tag: 'OfficeService');
    }
  }

  // Helper to get Firebase Auth user info
  Future<Map<String, dynamic>?> _getFirebaseAuthUser(String userId) async {
    try {
      // Since we can't directly access Firebase Auth user from here,
      // we'll use the current user from Firebase Auth
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && currentUser.uid == userId) {
        return {
          'displayName': currentUser.displayName,
          'email': currentUser.email,
        };
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
