// lib/data/repositories/user_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

/// Enhanced UserRepository with error handling while preserving existing API
class UserRepository {
  final FirebaseFirestore _firestore;

  UserRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection('users');

  /// Create user profile in Firestore with enhanced error handling
  Future<void> createUserProfile(AppUser user) async {
    try {
      await _usersRef
          .doc(user.uid)
          .set(user.toMap(), SetOptions(merge: true))
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw Exception('Database timeout during profile creation');
            },
          );
    } on FirebaseException catch (e) {
      print('Firestore error creating profile: ${e.code} - ${e.message}');
      rethrow; // Preserve existing error handling behavior
    } catch (e) {
      print('Error creating user profile: $e');
      rethrow;
    }
  }

  /// Get user profile by UID with retry logic
  Future<AppUser?> getUserProfile(String uid) async {
    int retryCount = 0;
    const maxRetries = 3;
    const retryDelay = Duration(seconds: 1);

    while (retryCount < maxRetries) {
      try {
        final snapshot = await _usersRef
            .doc(uid)
            .get()
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                throw Exception('Database timeout fetching profile');
              },
            );

        if (snapshot.exists && snapshot.data() != null) {
          return AppUser.fromDoc(snapshot);
        }
        return null;
      } on FirebaseException catch (e) {
        print(
          'Firestore error (attempt ${retryCount + 1}): ${e.code} - ${e.message}',
        );

        if (e.code == 'permission-denied') {
          return null; // Don't retry permission errors
        }

        retryCount++;
        if (retryCount < maxRetries) {
          await Future.delayed(retryDelay * retryCount);
        }
      } catch (e) {
        print('Error fetching user profile (attempt ${retryCount + 1}): $e');
        retryCount++;
        if (retryCount < maxRetries) {
          await Future.delayed(retryDelay * retryCount);
        }
      }
    }

    return null; // All retries exhausted
  }

  /// Update user profile (adds updatedAt timestamp automatically)
  Future<void> updateUserProfile(AppUser user) async {
    try {
      final data = user.toMap()..['updatedAt'] = FieldValue.serverTimestamp();

      await _usersRef
          .doc(user.uid)
          .set(data, SetOptions(merge: true))
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  /// Delete user profile with error handling
  Future<void> deleteUserProfile(String uid) async {
    try {
      await _usersRef.doc(uid).delete().timeout(const Duration(seconds: 10));
    } catch (e) {
      print('Error deleting user profile: $e');
      rethrow;
    }
  }
}
