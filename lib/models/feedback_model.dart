import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackModel {
  final String id;
  final String? name;
  final String? email;
  final String message;
  final DateTime timestamp;
  final bool synced;

  FeedbackModel({
    required this.id,
    this.name,
    this.email,
    required this.message,
    required this.timestamp,
    required this.synced,
  });

  factory FeedbackModel.fromMap(Map<String, dynamic> map, String id) {
    return FeedbackModel(
      id: id,
      name: map['name'],
      email: map['email'],
      message: map['message'] ?? '',
      timestamp: map['timestamp'] is Timestamp
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.parse(
              map['timestamp'] ?? DateTime.now().toIso8601String(),
            ),
      synced: map['synced'] ?? true,
    );
  }

  factory FeedbackModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FeedbackModel.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'synced': synced,
    };
  }

  Map<String, dynamic> toLocalMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'synced': synced,
    };
  }

  factory FeedbackModel.fromLocalMap(Map<String, dynamic> map) {
    return FeedbackModel(
      id: map['id'] ?? '',
      name: map['name'],
      email: map['email'],
      message: map['message'] ?? '',
      timestamp: DateTime.parse(
        map['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
      synced: map['synced'] ?? false,
    );
  }

  FeedbackModel copyWith({
    String? id,
    String? name,
    String? email,
    String? message,
    DateTime? timestamp,
    bool? synced,
  }) {
    return FeedbackModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      synced: synced ?? this.synced,
    );
  }

  @override
  String toString() {
    return 'FeedbackModel(id: $id, name: $name, email: $email, message: $message, timestamp: $timestamp, synced: $synced)';
  }
}
