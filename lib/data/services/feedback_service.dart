// lib/data/services/feedback_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/feedback_model.dart';
import '../models/user_model.dart';

class FeedbackService {
  static const String _collection = 'feedback';
  final FirebaseFirestore _firestore;

  FeedbackService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static final FeedbackService instance = FeedbackService();

  /// Submit user feedback
  Future<bool> submitFeedback({
    required AppUser user,
    required FeedbackType type,
    required String message,
  }) async {
    try {
      final feedback = UserFeedback(
        id: '', // Will be set by Firestore
        userId: user.uid,
        userEmail: user.email,
        userName: '${user.firstName} ${user.lastName}'.trim(),
        type: type,
        message: message.trim(),
        timestamp: DateTime.now(),
        appVersion: '1.0.0', // You can get this from package_info_plus
        deviceInfo: kIsWeb ? 'Web' : 'Mobile',
      );

      await _firestore.collection(_collection).add(feedback.toMap());

      if (kDebugMode) {
        print('[FeedbackService] Feedback submitted successfully');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('[FeedbackService] Error submitting feedback: $e');
      }
      return false;
    }
  }

  /// Get user's feedback history (optional for future use)
  Future<List<UserFeedback>> getUserFeedbackHistory(String userId) async {
    try {
      final query = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      return query.docs
          .map((doc) => UserFeedback.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('[FeedbackService] Error fetching feedback history: $e');
      }
      return [];
    }
  }
}
