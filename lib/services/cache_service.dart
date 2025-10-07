import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/logger/app_logger.dart';

class CacheService {
  static const String _attendanceKey = 'attendance_data';
  static const String _holidaysKey = 'holidays_data';
  static const String _lastSyncKey = 'last_sync';
  static const String _offlineDataKey = 'offline_data';

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cache attendance data (user-specific)
  static Future<void> cacheAttendanceData(
    String userId,
    Map<String, dynamic> attendanceData,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final userKey = '${_attendanceKey}_$userId';
    await prefs.setString(userKey, jsonEncode(attendanceData));
    await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
  }

  // Get cached attendance data (user-specific)
  static Future<Map<String, dynamic>?> getCachedAttendanceData(
    String userId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final userKey = '${_attendanceKey}_$userId';
    final data = prefs.getString(userKey);
    if (data != null) {
      return jsonDecode(data) as Map<String, dynamic>;
    }
    return null;
  }

  // Cache holidays data
  static Future<void> cacheHolidaysData(
    List<Map<String, dynamic>> holidaysData,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_holidaysKey, jsonEncode(holidaysData));
  }

  // Get cached holidays data
  static Future<List<Map<String, dynamic>>?> getCachedHolidaysData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_holidaysKey);
    if (data != null) {
      return List<Map<String, dynamic>>.from(jsonDecode(data));
    }
    return null;
  }

  // Check if data needs refresh (older than 1 day)
  static Future<bool> needsRefresh() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSync = prefs.getString(_lastSyncKey);
    if (lastSync == null) return true;

    final lastSyncDate = DateTime.parse(lastSync);
    final now = DateTime.now();
    return now.difference(lastSyncDate).inDays >= 1;
  }

  // Clear all cached data for a specific user
  static Future<void> clearCache(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final userKey = '${_attendanceKey}_$userId';
    await prefs.remove(userKey);
    await prefs.remove(_holidaysKey);
    await prefs.remove(_lastSyncKey);
  }

  // Cache specific month attendance (user-specific)
  static Future<void> cacheMonthAttendance(
    String userId,
    int year,
    int month,
    List<DateTime> attendedDates,
  ) async {
    final cachedData = await getCachedAttendanceData(userId) ?? {};
    final monthKey = '${year}_$month';
    cachedData[monthKey] = attendedDates
        .map((date) => date.toIso8601String())
        .toList();
    await cacheAttendanceData(userId, cachedData);
  }

  // Get cached month attendance (user-specific)
  static Future<List<DateTime>?> getCachedMonthAttendance(
    String userId,
    int year,
    int month,
  ) async {
    final cachedData = await getCachedAttendanceData(userId);
    if (cachedData == null) return null;

    final monthKey = '${year}_$month';
    final monthData = cachedData[monthKey];
    if (monthData == null) return null;

    return (monthData as List)
        .map((dateString) => DateTime.parse(dateString))
        .toList();
  }

  // Cache holidays for a specific year
  static Future<void> cacheYearHolidays(
    int year,
    List<DateTime> holidays,
  ) async {
    final cachedData = await getCachedHolidaysData() ?? [];
    final yearData = {
      'year': year,
      'holidays': holidays.map((date) => date.toIso8601String()).toList(),
    };

    // Remove existing year data and add new
    cachedData.removeWhere((data) => data['year'] == year);
    cachedData.add(yearData);

    await cacheHolidaysData(cachedData);
  }

  // Get cached holidays for a specific year
  static Future<List<DateTime>?> getCachedYearHolidays(int year) async {
    final cachedData = await getCachedHolidaysData();
    if (cachedData == null) return null;

    final yearData = cachedData.firstWhere(
      (data) => data['year'] == year,
      orElse: () => <String, dynamic>{},
    );

    if (yearData.isEmpty) return null;

    return (yearData['holidays'] as List)
        .map((dateString) => DateTime.parse(dateString))
        .toList();
  }

  // Enhanced caching with Firestore integration

  // Cache attendance data to both local storage and Firestore (user-specific)
  static Future<void> cacheAttendanceWithSync(
    String userId,
    int year,
    int month,
    List<DateTime> attendedDates,
  ) async {
    try {
      // Cache locally first for immediate access
      await cacheMonthAttendance(userId, year, month, attendedDates);

      // Also store in Firestore for cloud backup
      await _storeInFirestore(userId, year, month, attendedDates);

      // Update sync timestamp
      await _updateSyncTimestamp();
    } catch (e) {
      // If Firestore fails, at least we have local cache
      AppLogger.error('Failed to sync to Firestore: $e', tag: 'CacheService');
    }
  }

  // Get attendance data with fallback strategy (user-specific)
  static Future<List<DateTime>?> getAttendanceWithFallback(
    String userId,
    int year,
    int month,
  ) async {
    try {
      // First try to get from local cache
      List<DateTime>? localData = await getCachedMonthAttendance(
        userId,
        year,
        month,
      );

      if (localData != null) {
        // Check if we need to refresh from Firestore
        if (await needsRefresh()) {
          // Try to get fresh data from Firestore in background
          _refreshFromFirestoreInBackground(userId, year, month);
        }
        return localData;
      }

      // If no local data, try Firestore
      return await _getFromFirestore(userId, year, month);
    } catch (e) {
      AppLogger.error('Failed to get attendance data: $e', tag: 'CacheService');
      return null;
    }
  }

  // Store data in Firestore
  static Future<void> _storeInFirestore(
    String userId,
    int year,
    int month,
    List<DateTime> attendedDates,
  ) async {
    final monthKey = month.toString().padLeft(2, '0');
    final batch = _firestore.batch();

    // Clear existing data for this month
    final monthRef = _firestore
        .collection('attendance_cache')
        .doc(userId)
        .collection(year.toString())
        .doc(monthKey);

    // Store each attended date
    for (final date in attendedDates) {
      final dayKey = date.day.toString().padLeft(2, '0');
      final dayRef = monthRef.collection('days').doc(dayKey);
      batch.set(dayRef, {
        'date': date.toIso8601String(),
        'timestamp': FieldValue.serverTimestamp(),
      });
    }

    // Store metadata
    batch.set(monthRef, {
      'year': year,
      'month': month,
      'lastUpdated': FieldValue.serverTimestamp(),
      'totalDays': attendedDates.length,
    });

    await batch.commit();
  }

  // Get data from Firestore
  static Future<List<DateTime>?> _getFromFirestore(
    String userId,
    int year,
    int month,
  ) async {
    try {
      final monthKey = month.toString().padLeft(2, '0');
      final snapshot = await _firestore
          .collection('attendance_cache')
          .doc(userId)
          .collection(year.toString())
          .doc(monthKey)
          .collection('days')
          .get();

      if (snapshot.docs.isEmpty) return null;

      final dates = snapshot.docs.map((doc) {
        final data = doc.data();
        return DateTime.parse(data['date']);
      }).toList();

      // Cache the data locally for future use
      await cacheMonthAttendance(userId, year, month, dates);

      return dates;
    } catch (e) {
      AppLogger.error('Failed to get from Firestore: $e', tag: 'CacheService');
      return null;
    }
  }

  // Refresh from Firestore in background
  static Future<void> _refreshFromFirestoreInBackground(
    String userId,
    int year,
    int month,
  ) async {
    try {
      final freshData = await _getFromFirestore(userId, year, month);
      if (freshData != null) {
        await cacheMonthAttendance(userId, year, month, freshData);
        await _updateSyncTimestamp();
      }
    } catch (e) {
      // Silent fail for background refresh
    }
  }

  // Update sync timestamp
  static Future<void> _updateSyncTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
  }

  // Store offline data for when user is offline
  static Future<void> storeOfflineData(
    String userId,
    Map<String, dynamic> data,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final offlineData = await getOfflineData() ?? {};
    offlineData[userId] = data;
    await prefs.setString(_offlineDataKey, jsonEncode(offlineData));
  }

  // Get offline data
  static Future<Map<String, dynamic>?> getOfflineData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_offlineDataKey);
    if (data != null) {
      return jsonDecode(data) as Map<String, dynamic>;
    }
    return null;
  }

  // Sync offline data when connection is restored
  static Future<void> syncOfflineData(String userId) async {
    try {
      final offlineData = await getOfflineData();
      if (offlineData == null || !offlineData.containsKey(userId)) return;

      final userOfflineData = offlineData[userId] as Map<String, dynamic>;

      // Process offline attendance data
      if (userOfflineData.containsKey('attendance')) {
        final attendanceData =
            userOfflineData['attendance'] as Map<String, dynamic>;

        for (final entry in attendanceData.entries) {
          final yearMonth = entry.key.split('_');
          final year = int.parse(yearMonth[0]);
          final month = int.parse(yearMonth[1]);
          final dates = (entry.value as List)
              .map((dateString) => DateTime.parse(dateString))
              .toList();

          await _storeInFirestore(userId, year, month, dates);
        }
      }

      // Clear offline data after successful sync
      await _clearOfflineData(userId);
    } catch (e) {
      AppLogger.error('Failed to sync offline data: $e', tag: 'CacheService');
    }
  }

  // Clear offline data for a specific user
  static Future<void> _clearOfflineData(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final offlineData = await getOfflineData() ?? {};
    offlineData.remove(userId);
    await prefs.setString(_offlineDataKey, jsonEncode(offlineData));
  }

  // Check if user has offline data
  static Future<bool> hasOfflineData(String userId) async {
    final offlineData = await getOfflineData();
    return offlineData != null && offlineData.containsKey(userId);
  }

  // Delete attendance data from both local storage and Firestore (user-specific)
  static Future<void> deleteAttendanceWithSync(
    String userId,
    int year,
    int month,
    DateTime dateToDelete,
  ) async {
    try {
      // Remove from local cache
      final cachedData = await getCachedAttendanceData(userId) ?? {};
      final monthKey = '${year}_$month';
      final monthData = cachedData[monthKey];

      if (monthData != null) {
        final dates = (monthData as List)
            .map((dateString) => DateTime.parse(dateString))
            .toList();

        // Remove the specific date
        dates.removeWhere(
          (date) =>
              date.year == dateToDelete.year &&
              date.month == dateToDelete.month &&
              date.day == dateToDelete.day,
        );

        // Update local cache
        cachedData[monthKey] = dates
            .map((date) => date.toIso8601String())
            .toList();
        await cacheAttendanceData(userId, cachedData);
      }

      // Remove from Firestore cache
      await _deleteFromFirestore(userId, year, month, dateToDelete);

      // Update sync timestamp
      await _updateSyncTimestamp();
    } catch (e) {
      AppLogger.error('Failed to delete attendance from cache: $e', tag: 'CacheService');
    }
  }

  // Delete specific date from Firestore cache
  static Future<void> _deleteFromFirestore(
    String userId,
    int year,
    int month,
    DateTime dateToDelete,
  ) async {
    try {
      final monthKey = month.toString().padLeft(2, '0');
      final dayKey = dateToDelete.day.toString().padLeft(2, '0');

      await _firestore
          .collection('attendance_cache')
          .doc(userId)
          .collection(year.toString())
          .doc(monthKey)
          .collection('days')
          .doc(dayKey)
          .delete();
    } catch (e) {
      AppLogger.error('Failed to delete from Firestore cache: $e', tag: 'CacheService');
    }
  }

  // Force sync all cached data to Firestore (user-specific)
  static Future<void> forceSyncToFirestore(String userId) async {
    try {
      final cachedData = await getCachedAttendanceData(userId);
      if (cachedData == null) return;

      for (final entry in cachedData.entries) {
        final yearMonth = entry.key.split('_');
        final year = int.parse(yearMonth[0]);
        final month = int.parse(yearMonth[1]);
        final dates = (entry.value as List)
            .map((dateString) => DateTime.parse(dateString))
            .toList();

        await _storeInFirestore(userId, year, month, dates);
      }

      await _updateSyncTimestamp();
    } catch (e) {
      AppLogger.error('Failed to force sync: $e', tag: 'CacheService');
    }
  }
}
