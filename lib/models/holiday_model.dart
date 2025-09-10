import 'package:cloud_firestore/cloud_firestore.dart';

class HolidayModel {
  final String id;
  final String date; // YYYY-MM-DD format
  final String name;
  final String? createdBy;
  final DateTime? createdAt;

  HolidayModel({
    required this.id,
    required this.date,
    required this.name,
    this.createdBy,
    this.createdAt,
  });

  factory HolidayModel.fromMap(Map<String, dynamic> map, String id) {
    return HolidayModel(
      id: id,
      date: map['date'] ?? '',
      name: map['name'] ?? '',
      createdBy: map['createdBy'],
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  factory HolidayModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HolidayModel.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'name': name,
      'createdBy': createdBy,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  // Convert to DateTime for easier comparison
  DateTime toDateTime() {
    final parts = date.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  // Create from DateTime
  static HolidayModel fromDateTime(
    DateTime dateTime,
    String name, {
    String? createdBy,
  }) {
    final dateStr =
        '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
    return HolidayModel(
      id: dateStr, // Use date as ID for easy lookup
      date: dateStr,
      name: name,
      createdBy: createdBy,
      createdAt: DateTime.now(),
    );
  }

  // Check if this holiday matches a given date
  bool matchesDate(DateTime date) {
    final holidayDate = toDateTime();

    // Check exact date match
    return holidayDate.year == date.year &&
        holidayDate.month == date.month &&
        holidayDate.day == date.day;
  }

  HolidayModel copyWith({
    String? id,
    String? date,
    String? name,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return HolidayModel(
      id: id ?? this.id,
      date: date ?? this.date,
      name: name ?? this.name,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
