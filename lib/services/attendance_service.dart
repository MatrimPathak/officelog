import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/working_days_calculator.dart';
import '../models/attendance_model.dart';
import 'dart:convert';

class AttendanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _offlineAttendanceKey = 'offline_attendance';

  // Mark attendance for today
  Future<void> markAttendance(String userId) async {
    await markAttendanceForDate(userId, DateTime.now());
  }

  // Mark attendance via geofence (background auto check-in)
  Future<void> markGeofenceAttendance(String userId, DateTime date) async {
    await markAttendanceForDate(
      userId,
      date,
      method: 'geofence',
      status: 'auto_present',
      note: 'Auto check-in via geofence',
    );
  }

  // Mark attendance for a specific date with new schema
  Future<void> markAttendanceForDate(
    String userId,
    DateTime date, {
    String method = 'manual',
    String? note,
    String status = 'present',
  }) async {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    var attendance = AttendanceModel(
      date: dateStr,
      status: status,
      method: method,
      note: note,
      synced: true,
      createdAt: DateTime.now(),
    );

    try {
      // Write to new schema only
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('attendance')
          .doc(dateStr);
      await docRef.set(attendance.toMap());
    } catch (e) {
      // If online save fails, save offline
      attendance = attendance.copyWith(synced: false, method: 'offline');
      await _saveOfflineAttendance(userId, attendance);
      throw Exception('Failed to mark attendance online, saved offline: $e');
    }
  }

  // Delete attendance for a specific date
  Future<void> deleteAttendanceForDate(String userId, DateTime date) async {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    try {
      // Delete from new schema only
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('attendance')
          .doc(dateStr);
      await docRef.delete();
    } catch (e) {
      throw Exception('Failed to delete attendance: $e');
    }
  }

  // Check if user has already marked attendance for today
  Future<bool> hasMarkedAttendanceToday(String userId) async {
    return await hasMarkedAttendanceForDate(userId, DateTime.now());
  }

  // Check if user has already marked attendance for a specific date
  Future<bool> hasMarkedAttendanceForDate(String userId, DateTime date) async {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    try {
      // Check new schema only
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('attendance')
          .doc(dateStr)
          .get();

      return doc.exists;
    } catch (e) {
      throw Exception('Failed to check attendance: $e');
    }
  }

  // Get attendance for current month
  Future<List<DateTime>> getMonthlyAttendance(
    String userId,
    int year,
    int month,
  ) async {
    try {
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0); // Last day of month

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('attendance')
          .where(
            'date',
            isGreaterThanOrEqualTo:
                '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-01',
          )
          .where(
            'date',
            isLessThanOrEqualTo:
                '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}',
          )
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        final dateParts = data['date'].split('-');
        return DateTime(
          int.parse(dateParts[0]),
          int.parse(dateParts[1]),
          int.parse(dateParts[2]),
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to get monthly attendance: $e');
    }
  }

  // Get attendance for entire year
  Future<Map<String, int>> getYearlySummary(String userId, int year) async {
    try {
      final startDate = DateTime(year, 1, 1);
      final endDate = DateTime(year, 12, 31);

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('attendance')
          .where(
            'date',
            isGreaterThanOrEqualTo:
                '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-01',
          )
          .where(
            'date',
            isLessThanOrEqualTo:
                '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}',
          )
          .get();

      Map<String, int> summary = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final dateParts = data['date'].split('-');
        final month = dateParts[1];

        summary[month] = (summary[month] ?? 0) + 1;
      }

      return summary;
    } catch (e) {
      throw Exception('Failed to get yearly summary: $e');
    }
  }

  // Get attendance data for a specific month with detailed info
  Future<Map<String, dynamic>> getMonthDetails(
    String userId,
    int year,
    int month,
  ) async {
    try {
      final attendedDays = await getMonthlyAttendance(userId, year, month);

      // Import WorkingDaysCalculator
      final totalWorkingDays = WorkingDaysCalculator.getWorkingDaysInMonth(
        year,
        month,
      );

      // Filter attended days to only include working days
      final attendedWorkingDays = attendedDays
          .where((date) => WorkingDaysCalculator.isWorkingDay(date))
          .toList();

      // Use 3-day weekly rule for compliance calculation
      final monthStats = WorkingDaysCalculator.calculateMonthlyCompliance(
        year,
        month,
        attendedDays,
      );

      return {
        'attendedDays': attendedWorkingDays.length,
        'totalDays': totalWorkingDays,
        'totalWeeks':
            monthStats['totalWeeks'], // Add totalWeeks for summary screen
        'requiredDays':
            monthStats['requiredDays'], // Required days based on 3-day rule
        'percentage': monthStats['compliance'], // Use 3-day rule compliance
        'dates': attendedWorkingDays,
      };
    } catch (e) {
      throw Exception('Failed to get month details: $e');
    }
  }

  // Get all attendance data for a year with monthly breakdown
  Future<List<Map<String, dynamic>>> getYearlyDetails(
    String userId,
    int year,
  ) async {
    try {
      List<Map<String, dynamic>> monthlyData = [];

      for (int month = 1; month <= 12; month++) {
        final monthData = await getMonthDetails(userId, year, month);
        monthlyData.add({
          'month': month,
          'monthName': _getMonthName(month),
          ...monthData,
        });
      }

      return monthlyData;
    } catch (e) {
      throw Exception('Failed to get yearly details: $e');
    }
  }

  // Helper method to get month name
  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  // Stream for real-time attendance updates
  Stream<List<DateTime>> getMonthlyAttendanceStream(
    String userId,
    int year,
    int month,
  ) {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0); // Last day of month

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('attendance')
        .where(
          'date',
          isGreaterThanOrEqualTo:
              '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-01',
        )
        .where(
          'date',
          isLessThanOrEqualTo:
              '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}',
        )
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            final dateParts = data['date'].split('-');
            return DateTime(
              int.parse(dateParts[0]),
              int.parse(dateParts[1]),
              int.parse(dateParts[2]),
            );
          }).toList();
        });
  }

  // Offline functionality methods

  // Save attendance offline
  Future<void> _saveOfflineAttendance(
    String userId,
    AttendanceModel attendance,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final offlineDataKey = '${_offlineAttendanceKey}_$userId';

      // Get existing offline data
      final existingData = prefs.getString(offlineDataKey);
      List<Map<String, dynamic>> offlineList = [];

      if (existingData != null) {
        final List<dynamic> decoded = json.decode(existingData);
        offlineList = decoded.cast<Map<String, dynamic>>();
      }

      // Add new attendance
      offlineList.add(attendance.toMap());

      // Save back to preferences
      await prefs.setString(offlineDataKey, json.encode(offlineList));
    } catch (e) {
      print('Failed to save offline attendance: $e');
    }
  }

  // Get offline attendance data
  Future<List<AttendanceModel>> getOfflineAttendance(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final offlineDataKey = '${_offlineAttendanceKey}_$userId';
      final offlineData = prefs.getString(offlineDataKey);

      if (offlineData == null) return [];

      final List<dynamic> decoded = json.decode(offlineData);
      return decoded
          .map((map) => AttendanceModel.fromMap(map.cast<String, dynamic>()))
          .toList();
    } catch (e) {
      print('Failed to get offline attendance: $e');
      return [];
    }
  }

  // Sync offline attendance to Firestore
  Future<void> syncOfflineAttendance(String userId) async {
    try {
      final offlineAttendance = await getOfflineAttendance(userId);
      if (offlineAttendance.isEmpty) return;

      final batch = _firestore.batch();

      for (final attendance in offlineAttendance) {
        final docRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('attendance')
            .doc(attendance.date);

        // Check if already exists online
        final existingDoc = await docRef.get();
        if (!existingDoc.exists) {
          // Only sync if not already present online
          final syncedAttendance = attendance.copyWith(
            synced: true,
            method: attendance.method == 'offline'
                ? 'manual'
                : attendance.method,
          );
          batch.set(docRef, syncedAttendance.toMap());
        }
      }

      await batch.commit();

      // Clear offline data after successful sync
      await _clearOfflineAttendance(userId);
    } catch (e) {
      print('Failed to sync offline attendance: $e');
      throw Exception('Failed to sync offline attendance: $e');
    }
  }

  // Clear offline attendance data
  Future<void> _clearOfflineAttendance(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final offlineDataKey = '${_offlineAttendanceKey}_$userId';
      await prefs.remove(offlineDataKey);
    } catch (e) {
      print('Failed to clear offline attendance: $e');
    }
  }

  // Check if there's offline data to sync
  Future<bool> hasOfflineData(String userId) async {
    final offlineAttendance = await getOfflineAttendance(userId);
    return offlineAttendance.isNotEmpty;
  }

  // Get combined online and offline attendance for a month
  Future<List<DateTime>> getMonthlyAttendanceWithOffline(
    String userId,
    int year,
    int month,
  ) async {
    try {
      // Get online attendance
      final onlineAttendance = await getMonthlyAttendance(userId, year, month);

      // Get offline attendance
      final offlineAttendance = await getOfflineAttendance(userId);
      final offlineForMonth = offlineAttendance
          .where((attendance) {
            final date = attendance.toDateTime();
            return date.year == year && date.month == month;
          })
          .map((attendance) => attendance.toDateTime())
          .toList();

      // Combine and deduplicate
      final combined = <DateTime>[];
      combined.addAll(onlineAttendance);

      for (final offlineDate in offlineForMonth) {
        if (!combined.any(
          (date) =>
              date.year == offlineDate.year &&
              date.month == offlineDate.month &&
              date.day == offlineDate.day,
        )) {
          combined.add(offlineDate);
        }
      }

      return combined;
    } catch (e) {
      print('Failed to get combined attendance: $e');
      return await getMonthlyAttendance(userId, year, month);
    }
  }

  // Get attendance model for a specific date
  Future<AttendanceModel?> getAttendanceForDate(
    String userId,
    DateTime date,
  ) async {
    try {
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      // Try to get from Firestore first
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('attendance')
          .doc(dateStr)
          .get();

      if (doc.exists) {
        return AttendanceModel.fromFirestore(doc);
      }

      // Check offline data
      final offlineAttendance = await getOfflineAttendance(userId);
      return offlineAttendance.firstWhere(
        (attendance) => attendance.date == dateStr,
        orElse: () => throw StateError('Not found'),
      );
    } catch (e) {
      return null;
    }
  }

  // Check if date has unsynced offline attendance
  Future<bool> hasUnsyncedAttendance(String userId, DateTime date) async {
    try {
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final offlineAttendance = await getOfflineAttendance(userId);

      return offlineAttendance.any(
        (attendance) => attendance.date == dateStr && !attendance.synced,
      );
    } catch (e) {
      return false;
    }
  }
}
