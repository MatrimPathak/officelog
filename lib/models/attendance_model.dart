import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceModel {
  final String date; // YYYY-MM-DD format
  final String status; // present | holiday | absent | auto_present
  final String method; // manual | auto | offline | geofence
  final String? note;
  final bool synced;
  final DateTime createdAt;

  AttendanceModel({
    required this.date,
    required this.status,
    required this.method,
    this.note,
    required this.synced,
    required this.createdAt,
  });

  factory AttendanceModel.fromMap(Map<String, dynamic> map) {
    return AttendanceModel(
      date: map['date'] ?? '',
      status: map['status'] ?? 'present',
      method: map['method'] ?? 'manual',
      note: map['note'],
      synced: map['synced'] ?? true,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.parse(
              map['createdAt'] ?? DateTime.now().toIso8601String(),
            ),
    );
  }

  factory AttendanceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AttendanceModel.fromMap(data);
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'status': status,
      'method': method,
      'note': note,
      'synced': synced,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  AttendanceModel copyWith({
    String? date,
    String? status,
    String? method,
    String? note,
    bool? synced,
    DateTime? createdAt,
  }) {
    return AttendanceModel(
      date: date ?? this.date,
      status: status ?? this.status,
      method: method ?? this.method,
      note: note ?? this.note,
      synced: synced ?? this.synced,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Convert to old format for backward compatibility
  DateTime toDateTime() {
    final parts = date.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  // Create from DateTime for backward compatibility
  static AttendanceModel fromDateTime(
    DateTime dateTime, {
    String status = 'present',
    String method = 'manual',
    String? note,
    bool synced = true,
  }) {
    return AttendanceModel(
      date:
          '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}',
      status: status,
      method: method,
      note: note,
      synced: synced,
      createdAt: DateTime.now(),
    );
  }
}
