import 'package:cloud_firestore/cloud_firestore.dart';

class OfficeModel {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radius; // in meters
  final String timezone;
  final DateTime? createdAt;

  OfficeModel({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radius,
    this.timezone = 'Asia/Kolkata',
    this.createdAt,
  });

  factory OfficeModel.fromMap(Map<String, dynamic> map, String id) {
    return OfficeModel(
      id: id,
      name: map['name'] ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      radius: (map['radius'] ?? 200.0).toDouble(),
      timezone: map['timezone'] ?? 'Asia/Kolkata',
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  factory OfficeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OfficeModel.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'timezone': timezone,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  OfficeModel copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    double? radius,
    String? timezone,
    DateTime? createdAt,
  }) {
    return OfficeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radius: radius ?? this.radius,
      timezone: timezone ?? this.timezone,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role;
  final String? officeId;
  final DateTime? createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.role = 'employee',
    this.officeId,
    this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'employee',
      officeId: map['officeId'],
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'officeId': officeId,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? role,
    String? officeId,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      officeId: officeId ?? this.officeId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
