import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/feedback_model.dart';
import 'dart:convert';

class FeedbackService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _offlineFeedbackKey = 'offline_feedback';

  /// Submit feedback to Firebase
  Future<bool> submitFeedback({
    String? name,
    String? email,
    required String message,
  }) async {
    try {
      final feedbackId = _firestore.collection('feedback').doc().id;

      final feedback = FeedbackModel(
        id: feedbackId,
        name: name?.trim().isEmpty == true ? null : name?.trim(),
        email: email?.trim().isEmpty == true ? null : email?.trim(),
        message: message.trim(),
        timestamp: DateTime.now(),
        synced: true,
      );

      // Try to submit to Firebase
      await _firestore
          .collection('feedback')
          .doc(feedbackId)
          .set(feedback.toMap());

      print('✅ Feedback submitted successfully to Firebase');
      return true;
    } catch (e) {
      print('❌ Failed to submit feedback to Firebase: $e');

      // Save offline if Firebase fails
      await _saveFeedbackOffline(name: name, email: email, message: message);

      // Return true since we saved it offline
      return true;
    }
  }

  /// Save feedback offline for later sync
  Future<void> _saveFeedbackOffline({
    String? name,
    String? email,
    required String message,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final feedbackId = DateTime.now().millisecondsSinceEpoch.toString();

      final feedback = FeedbackModel(
        id: feedbackId,
        name: name?.trim().isEmpty == true ? null : name?.trim(),
        email: email?.trim().isEmpty == true ? null : email?.trim(),
        message: message.trim(),
        timestamp: DateTime.now(),
        synced: false,
      );

      // Get existing offline feedback
      final existingFeedbackJson = prefs.getString(_offlineFeedbackKey);
      List<dynamic> offlineFeedback = [];

      if (existingFeedbackJson != null) {
        offlineFeedback = json.decode(existingFeedbackJson);
      }

      // Add new feedback
      offlineFeedback.add(feedback.toLocalMap());

      // Save back to preferences
      await prefs.setString(_offlineFeedbackKey, json.encode(offlineFeedback));

      print('📱 Feedback saved offline for later sync');
    } catch (e) {
      print('❌ Failed to save feedback offline: $e');
      throw Exception('Failed to save feedback: $e');
    }
  }

  /// Get count of offline feedback waiting to be synced
  Future<int> getOfflineFeedbackCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final feedbackJson = prefs.getString(_offlineFeedbackKey);

      if (feedbackJson == null) return 0;

      final List<dynamic> feedbackList = json.decode(feedbackJson);
      return feedbackList.length;
    } catch (e) {
      print('❌ Error getting offline feedback count: $e');
      return 0;
    }
  }

  /// Sync offline feedback to Firebase
  Future<bool> syncOfflineFeedback() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final feedbackJson = prefs.getString(_offlineFeedbackKey);

      if (feedbackJson == null) return true;

      final List<dynamic> offlineFeedback = json.decode(feedbackJson);
      if (offlineFeedback.isEmpty) return true;

      final batch = _firestore.batch();
      int syncedCount = 0;

      for (final feedbackData in offlineFeedback) {
        try {
          final feedback = FeedbackModel.fromLocalMap(feedbackData);
          final docRef = _firestore.collection('feedback').doc(feedback.id);

          batch.set(docRef, feedback.copyWith(synced: true).toMap());
          syncedCount++;
        } catch (e) {
          print('❌ Error preparing feedback for sync: $e');
        }
      }

      if (syncedCount > 0) {
        await batch.commit();

        // Clear offline feedback after successful sync
        await prefs.remove(_offlineFeedbackKey);

        print('✅ Synced $syncedCount offline feedback items to Firebase');
      }

      return true;
    } catch (e) {
      print('❌ Failed to sync offline feedback: $e');
      return false;
    }
  }

  /// Validate email format
  static bool isValidEmail(String email) {
    if (email.trim().isEmpty) return true; // Email is optional

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email.trim());
  }

  /// Validate feedback message
  static bool isValidMessage(String message) {
    return message.trim().isNotEmpty;
  }

  /// Get all feedback (admin function)
  Future<List<FeedbackModel>> getAllFeedback({int? limit}) async {
    try {
      Query query = _firestore
          .collection('feedback')
          .orderBy('timestamp', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => FeedbackModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('❌ Error fetching feedback: $e');
      return [];
    }
  }

  /// Delete feedback (admin function)
  Future<bool> deleteFeedback(String feedbackId) async {
    try {
      await _firestore.collection('feedback').doc(feedbackId).delete();
      print('✅ Feedback deleted successfully');
      return true;
    } catch (e) {
      print('❌ Error deleting feedback: $e');
      return false;
    }
  }

  /// Get feedback statistics (admin function)
  Future<Map<String, dynamic>> getFeedbackStats() async {
    try {
      final snapshot = await _firestore.collection('feedback').get();
      final feedbackList = snapshot.docs
          .map((doc) => FeedbackModel.fromFirestore(doc))
          .toList();

      final totalFeedback = feedbackList.length;
      final feedbackWithEmail = feedbackList
          .where((f) => f.email != null)
          .length;
      final feedbackWithName = feedbackList.where((f) => f.name != null).length;

      // Group by date for analytics
      final Map<String, int> dailyStats = {};
      for (final feedback in feedbackList) {
        final dateKey =
            '${feedback.timestamp.year}-${feedback.timestamp.month.toString().padLeft(2, '0')}-${feedback.timestamp.day.toString().padLeft(2, '0')}';
        dailyStats[dateKey] = (dailyStats[dateKey] ?? 0) + 1;
      }

      return {
        'totalFeedback': totalFeedback,
        'feedbackWithEmail': feedbackWithEmail,
        'feedbackWithName': feedbackWithName,
        'dailyStats': dailyStats,
        'lastUpdated': DateTime.now(),
      };
    } catch (e) {
      print('❌ Error getting feedback stats: $e');
      return {
        'totalFeedback': 0,
        'feedbackWithEmail': 0,
        'feedbackWithName': 0,
        'dailyStats': <String, int>{},
        'lastUpdated': DateTime.now(),
      };
    }
  }
}
