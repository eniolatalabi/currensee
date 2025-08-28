// lib/data/models/feedback_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum FeedbackType { bug, feature, general, compliment }

class UserFeedback {
  final String id;
  final String userId;
  final String userEmail;
  final String userName;
  final FeedbackType type;
  final String message;
  final DateTime timestamp;
  final String? appVersion;
  final String? deviceInfo;

  UserFeedback({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.userName,
    required this.type,
    required this.message,
    required this.timestamp,
    this.appVersion,
    this.deviceInfo,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userEmail': userEmail,
      'userName': userName,
      'type': type.name,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'appVersion': appVersion,
      'deviceInfo': deviceInfo,
    };
  }

  factory UserFeedback.fromMap(Map<String, dynamic> map, String documentId) {
    return UserFeedback(
      id: documentId,
      userId: map['userId'] ?? '',
      userEmail: map['userEmail'] ?? '',
      userName: map['userName'] ?? '',
      type: FeedbackType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => FeedbackType.general,
      ),
      message: map['message'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      appVersion: map['appVersion'],
      deviceInfo: map['deviceInfo'],
    );
  }
}
