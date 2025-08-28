// lib/features/history/service/firestore_conversion_history_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../data/models/conversion_history_model.dart';

class FirestoreConversionHistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'conversion_history';

  /// Save a conversion to Firestore
  Future<String> saveConversion(
    ConversionHistory conversion,
    String userId,
  ) async {
    try {
      final docRef = await _firestore.collection(_collection).add({
        'userId': userId,
        'baseCurrency': conversion.baseCurrency,
        'targetCurrency': conversion.targetCurrency,
        'baseAmount': conversion.baseAmount,
        'convertedAmount': conversion.convertedAmount,
        'rate': conversion.rate,
        'timestamp': Timestamp.fromDate(conversion.timestamp),
        'createdAt': Timestamp.now(),
      });

      if (kDebugMode) {
        debugPrint('[FirestoreConversionHistory] Saved: ${docRef.id}');
      }

      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FirestoreConversionHistory] Error saving: $e');
      }
      rethrow;
    }
  }

  /// Get user's conversion history
  Future<List<ConversionHistory>> getUserConversions(
    String userId, {
    int limit = 50,
    String? baseCurrency,
    String? targetCurrency,
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      Query query = _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true);

      if (baseCurrency != null) {
        query = query.where('baseCurrency', isEqualTo: baseCurrency);
      }

      if (targetCurrency != null) {
        query = query.where('targetCurrency', isEqualTo: targetCurrency);
      }

      if (from != null) {
        query = query.where(
          'timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(from),
        );
      }

      if (to != null) {
        query = query.where(
          'timestamp',
          isLessThanOrEqualTo: Timestamp.fromDate(to),
        );
      }

      query = query.limit(limit);

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return ConversionHistory(
          id: doc.id, // Use doc ID hash as int ID for compatibility
          baseCurrency: data['baseCurrency'],
          targetCurrency: data['targetCurrency'],
          baseAmount: (data['baseAmount'] as num).toDouble(),
          convertedAmount: (data['convertedAmount'] as num).toDouble(),
          rate: (data['rate'] as num).toDouble(),
          timestamp: (data['timestamp'] as Timestamp).toDate(),
        );
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FirestoreConversionHistory] Error fetching: $e');
      }
      return [];
    }
  }

  /// Get recent conversions for a user
  Future<List<ConversionHistory>> getRecentConversions(
    String userId, {
    int limit = 10,
  }) async {
    return getUserConversions(userId, limit: limit);
  }

  /// Delete a conversion
  Future<void> deleteConversion(String docId) async {
    try {
      await _firestore.collection(_collection).doc(docId).delete();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FirestoreConversionHistory] Error deleting: $e');
      }
      rethrow;
    }
  }

  /// Clear all conversions for a user
  Future<void> clearUserConversions(String userId) async {
    try {
      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .get();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FirestoreConversionHistory] Error clearing: $e');
      }
      rethrow;
    }
  }

  /// Stream user conversions in real-time
  Stream<List<ConversionHistory>> streamUserConversions(
    String userId, {
    int limit = 20,
  }) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return ConversionHistory(
              id: doc.id,
              baseCurrency: data['baseCurrency'],
              targetCurrency: data['targetCurrency'],
              baseAmount: (data['baseAmount'] as num).toDouble(),
              convertedAmount: (data['convertedAmount'] as num).toDouble(),
              rate: (data['rate'] as num).toDouble(),
              timestamp: (data['timestamp'] as Timestamp).toDate(),
            );
          }).toList();
        });
  }
}
