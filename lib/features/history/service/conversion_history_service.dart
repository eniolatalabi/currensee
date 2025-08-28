// lib/features/history/service/conversion_history_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../data/models/conversion_history_model.dart';

class ConversionHistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'conversion_history';

  ConversionHistoryService(); // Remove the DAO dependency

  /// Save conversion to Firestore with user ID
  Future<String> saveConversion(
    ConversionHistory conversion,
    String userId,
  ) async {
    try {
      // Create conversion with user ID
      final conversionWithUser = conversion.copyWith(userId: userId);

      final docRef = await _firestore
          .collection(_collection)
          .add(conversionWithUser.toFirestore());

      if (kDebugMode) {
        debugPrint('[ConversionHistoryService] Saved conversion: ${docRef.id}');
      }

      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ConversionHistoryService] Error saving conversion: $e');
      }
      rethrow;
    }
  }

  /// Get all conversions for a user
  Future<List<ConversionHistory>> getAllConversions({
    required String userId,
    String? baseCurrency,
    String? targetCurrency,
    DateTime? from,
    DateTime? to,
    int limit = 100,
  }) async {
    try {
      Query query = _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true);

      // Apply filters
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
      return snapshot.docs
          .map((doc) => ConversionHistory.fromFirestore(doc))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ConversionHistoryService] Error getting conversions: $e');
      }
      return [];
    }
  }

  /// Get recent conversions for a user
  Future<List<ConversionHistory>> getRecentConversions({
    required String userId,
    int limit = 10,
  }) async {
    return getAllConversions(userId: userId, limit: limit);
  }

  /// Delete a conversion
  Future<void> deleteConversion(String docId) async {
    try {
      await _firestore.collection(_collection).doc(docId).delete();

      if (kDebugMode) {
        debugPrint('[ConversionHistoryService] Deleted conversion: $docId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ConversionHistoryService] Error deleting conversion: $e');
      }
      rethrow;
    }
  }

  /// Clear all conversions for a user
  Future<void> clearAll(String userId) async {
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

      if (kDebugMode) {
        debugPrint(
          '[ConversionHistoryService] Cleared all conversions for user: $userId',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ConversionHistoryService] Error clearing conversions: $e');
      }
      rethrow;
    }
  }

  /// Get conversion count for a user
  Future<int> getConversionCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ConversionHistoryService] Error getting count: $e');
      }
      return 0;
    }
  }

  /// Search conversions for a user
  Future<List<ConversionHistory>> searchConversions(
    String userId,
    String query,
  ) async {
    // Note: Firestore doesn't support full-text search natively
    // This is a simplified version - you might want to use Algolia for better search
    try {
      final allConversions = await getAllConversions(userId: userId);

      return allConversions.where((conversion) {
        final searchQuery = query.toLowerCase();
        return conversion.baseCurrency.toLowerCase().contains(searchQuery) ||
            conversion.targetCurrency.toLowerCase().contains(searchQuery);
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ConversionHistoryService] Error searching: $e');
      }
      return [];
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
          return snapshot.docs
              .map((doc) => ConversionHistory.fromFirestore(doc))
              .toList();
        });
  }

  /// Get today's conversions for a user
  Future<List<ConversionHistory>> getTodaysConversions(String userId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return getAllConversions(userId: userId, from: startOfDay, to: endOfDay);
  }

  /// Get unique currencies used by a user
  Future<List<String>> getUniqueCurrencies(String userId) async {
    try {
      final conversions = await getAllConversions(userId: userId);
      final currencies = <String>{};

      for (final conversion in conversions) {
        currencies.add(conversion.baseCurrency);
        currencies.add(conversion.targetCurrency);
      }

      return currencies.toList()..sort();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ConversionHistoryService] Error getting currencies: $e');
      }
      return [];
    }
  }

  /// Get total converted amount for a specific currency
  Future<double> getTotalConvertedAmount(String userId, String currency) async {
    try {
      final conversions = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('targetCurrency', isEqualTo: currency)
          .get();

      double total = 0.0;
      for (final doc in conversions.docs) {
        final data = doc.data();
        total += (data['convertedAmount'] as num).toDouble();
      }

      return total;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ConversionHistoryService] Error getting total amount: $e');
      }
      return 0.0;
    }
  }
}
