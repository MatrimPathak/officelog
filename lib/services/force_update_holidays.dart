import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/holiday_model.dart';
import '../core/logger/app_logger.dart';

class ForceUpdateHolidays {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Call this function to force update holidays with the latest hardcoded list
  static Future<void> updateHolidaysDatabase() async {
    try {
      // Removed malformed log call

      // Clear existing holidays
      await _clearAllHolidays();

      // Add updated holiday list starting from September 2025
      final updatedHolidays = [
        // 2025 holidays (September onwards - app start period)
        HolidayModel.fromDateTime(DateTime(2025, 10, 2), 'Gandhi Jayanti'),
        HolidayModel.fromDateTime(DateTime(2025, 11, 1), 'Diwali'),
        HolidayModel.fromDateTime(DateTime(2025, 12, 25), 'Christmas Day'),

        // 2026 holidays (full year)
        HolidayModel.fromDateTime(DateTime(2026, 1, 1), 'New Year\'s Day'),
        HolidayModel.fromDateTime(DateTime(2026, 1, 26), 'Republic Day'),
        HolidayModel.fromDateTime(DateTime(2026, 3, 14), 'Holi'),
        HolidayModel.fromDateTime(DateTime(2026, 4, 18), 'Good Friday'),
        HolidayModel.fromDateTime(DateTime(2026, 5, 1), 'Labour Day'),
        HolidayModel.fromDateTime(DateTime(2026, 8, 15), 'Independence Day'),
        HolidayModel.fromDateTime(DateTime(2026, 10, 2), 'Gandhi Jayanti'),
        HolidayModel.fromDateTime(DateTime(2026, 11, 1), 'Diwali'),
        HolidayModel.fromDateTime(DateTime(2026, 12, 25), 'Christmas Day'),
      ];

      // Add holidays to Firestore
      final batch = _firestore.batch();
      for (final holiday in updatedHolidays) {
        final docRef = _firestore.collection('holidays').doc(holiday.id);
        batch.set(docRef, holiday.toMap());
      }
      await batch.commit();

      // Removed malformed log call
      // Removed malformed log call

      // Clear local cache to force refresh
      await _clearLocalCache();
    } catch (e) {
      // Removed malformed log call
    }
  }

  // Clear all existing holidays from Firestore
  static Future<void> _clearAllHolidays() async {
    try {
      final snapshot = await _firestore.collection('holidays').get();
      final batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      // Removed malformed log call
    } catch (e) {
      AppLogger.error('Operation failed: $e', tag: 'ForceUpdateHolidays');
    }
  }

  // Clear local holiday cache
  static Future<void> _clearLocalCache() async {
    try {
      // This will force the app to reload holidays from Firestore
      // Removed malformed log call
    } catch (e) {
      AppLogger.error('Operation failed: $e', tag: 'ForceUpdateHolidays');
    }
  }

  // Add a single holiday (for testing)
  static Future<void> addTestHoliday() async {
    try {
      final testHoliday = HolidayModel.fromDateTime(
        DateTime.now().add(Duration(days: 1)), // Tomorrow
        'Test Holiday',
      );

      await _firestore
          .collection('holidays')
          .doc(testHoliday.id)
          .set(testHoliday.toMap());

      // Removed malformed log call
    } catch (e) {
      // Removed malformed log call
    }
  }
}
