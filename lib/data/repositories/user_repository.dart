import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserRepository {
  final FirebaseFirestore _firestore;

  UserRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection('users');

  /// Create user profile in Firestore
  Future<void> createUserProfile(AppUser user) async {
    await _usersRef.doc(user.uid).set(user.toMap(), SetOptions(merge: true));
  }

  /// Get user profile by UID
  Future<AppUser?> getUserProfile(String uid) async {
    final snapshot = await _usersRef.doc(uid).get();
    if (snapshot.exists && snapshot.data() != null) {
      return AppUser.fromDoc(snapshot); // ✅ use fromDoc
    }
    return null;
  }

  /// Update user profile (adds updatedAt timestamp automatically)
  Future<void> updateUserProfile(AppUser user) async {
    final data = user.toMap()..['updatedAt'] = FieldValue.serverTimestamp();

    await _usersRef.doc(user.uid).set(data, SetOptions(merge: true));
  }

  /// Delete user profile
  Future<void> deleteUserProfile(String uid) async {
    await _usersRef.doc(uid).delete();
  }
}
