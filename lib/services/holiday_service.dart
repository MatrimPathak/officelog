import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/holiday_model.dart';
import 'dart:convert';
import '../core/logger/app_logger.dart';

class HolidayService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _cacheKey = 'cached_holidays';
  static const String _lastSyncKey = 'holidays_last_sync';
  static const Duration _cacheValidityDuration = Duration(hours: 24);

  // Get holidays for a specific month with caching
  Future<List<HolidayModel>> getHolidaysForMonth(int year, int month) async {
    try {
      // Check cache first
      final cachedHolidays = await _getCachedHolidays();
      if (cachedHolidays != null && !await _needsRefresh()) {
        return _filterHolidaysForMonth(cachedHolidays, year, month);
      }

      // Fetch from Firestore
      final holidays = await _fetchHolidaysFromFirestore();

      // Cache the results
      await _cacheHolidays(holidays);

      return _filterHolidaysForMonth(holidays, year, month);
    } catch (e) {
      // If network fails, try to return cached data
      final cachedHolidays = await _getCachedHolidays();
      if (cachedHolidays != null) {
        return _filterHolidaysForMonth(cachedHolidays, year, month);
      }
      throw Exception('Failed to load holidays: $e');
    }
  }

  // Get all holidays
  Future<List<HolidayModel>> getAllHolidays() async {
    try {
      // Check cache first
      final cachedHolidays = await _getCachedHolidays();
      if (cachedHolidays != null && !await _needsRefresh()) {
        return cachedHolidays;
      }

      // Fetch from Firestore
      final holidays = await _fetchHolidaysFromFirestore();

      // Cache the results
      await _cacheHolidays(holidays);

      return holidays;
    } catch (e) {
      // If network fails, try to return cached data
      final cachedHolidays = await _getCachedHolidays();
      if (cachedHolidays != null) {
        return cachedHolidays;
      }
      throw Exception('Failed to load holidays: $e');
    }
  }

  // Check if a specific date is a holiday
  Future<bool> isHoliday(DateTime date) async {
    try {
      final holidays = await getAllHolidays();
      return holidays.any((holiday) => holiday.matchesDate(date));
    } catch (e) {
      return false; // If can't check, assume not a holiday
    }
  }

  // Get holiday for a specific date
  Future<HolidayModel?> getHolidayForDate(DateTime date) async {
    try {
      final holidays = await getAllHolidays();
      return holidays.firstWhere(
        (holiday) => holiday.matchesDate(date),
        orElse: () => throw StateError('No holiday found'),
      );
    } catch (e) {
      return null;
    }
  }

  // Get upcoming holidays (for widgets)
  Future<List<HolidayModel>> getUpcomingHolidays({int limit = 5}) async {
    try {
      final holidays = await getAllHolidays();
      final now = DateTime.now();

      final upcomingHolidays = holidays.where((holiday) {
        final holidayDate = holiday.toDateTime();
        return holidayDate.isAfter(now) ||
            (holidayDate.year == now.year &&
                holidayDate.month == now.month &&
                holidayDate.day == now.day);
      }).toList();

      // Sort by date
      upcomingHolidays.sort((a, b) => a.toDateTime().compareTo(b.toDateTime()));

      // Return limited results
      return upcomingHolidays.take(limit).toList();
    } catch (e) {
      return [];
    }
  }

  // Add a new holiday (admin function)
  Future<void> addHoliday(HolidayModel holiday) async {
    try {
      await _firestore
          .collection('holidays')
          .doc(holiday.id)
          .set(holiday.toMap());

      // Clear cache to force refresh
      await _clearCache();
    } catch (e) {
      throw Exception('Failed to add holiday: $e');
    }
  }

  // Update a holiday (admin function)
  Future<void> updateHoliday(HolidayModel holiday) async {
    try {
      await _firestore
          .collection('holidays')
          .doc(holiday.id)
          .update(holiday.toMap());

      // Clear cache to force refresh
      await _clearCache();
    } catch (e) {
      throw Exception('Failed to update holiday: $e');
    }
  }

  // Delete a holiday (admin function)
  Future<void> deleteHoliday(String holidayId) async {
    try {
      await _firestore.collection('holidays').doc(holidayId).delete();

      // Clear cache to force refresh
      await _clearCache();
    } catch (e) {
      throw Exception('Failed to delete holiday: $e');
    }
  }

  // Force refresh holidays from server
  Future<List<HolidayModel>> refreshHolidays() async {
    try {
      await _clearCache();
      return await getAllHolidays();
    } catch (e) {
      throw Exception('Failed to refresh holidays: $e');
    }
  }

  // Private methods
  Future<List<HolidayModel>> _fetchHolidaysFromFirestore() async {
    final snapshot = await _firestore.collection('holidays').get();
    return snapshot.docs.map((doc) => HolidayModel.fromFirestore(doc)).toList();
  }

  List<HolidayModel> _filterHolidaysForMonth(
    List<HolidayModel> holidays,
    int year,
    int month,
  ) {
    return holidays.where((holiday) {
      final holidayDate = holiday.toDateTime();

      // Check year and month
      return holidayDate.year == year && holidayDate.month == month;
    }).toList();
  }

  Future<List<HolidayModel>?> _getCachedHolidays() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_cacheKey);

      if (cachedData == null) return null;

      final List<dynamic> holidayMaps = json.decode(cachedData);
      return holidayMaps
          .map((map) => HolidayModel.fromMap(map, map['id']))
          .toList();
    } catch (e) {
      return null;
    }
  }

  Future<void> _cacheHolidays(List<HolidayModel> holidays) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final holidayMaps = holidays.map((holiday) {
        final map = holiday.toMap();
        map['id'] = holiday.id; // Include ID in the map
        return map;
      }).toList();

      await prefs.setString(_cacheKey, json.encode(holidayMaps));
      await prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
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

  // Initialize default holidays (call this once during app setup)
  Future<void> initializeDefaultHolidays() async {
    try {
      // Check if holidays already exist
      final snapshot = await _firestore.collection('holidays').limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        return; // Holidays already exist
      }

      // Add holidays starting from September 2025 (app start)
      final defaultHolidays = [
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
      for (final holiday in defaultHolidays) {
        final docRef = _firestore.collection('holidays').doc(holiday.id);
        batch.set(docRef, holiday.toMap());
      }
      await batch.commit();

      // Clear cache to force refresh
      await _clearCache();
    } catch (e) {
      AppLogger.error('Failed to initialize default holidays: $e', tag: 'HolidayService');
    }
  }
}
