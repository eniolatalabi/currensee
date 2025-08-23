import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  AuthService._privateConstructor();
  static final AuthService instance = AuthService._privateConstructor();

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ===== Google Sign-In =====
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User canceled

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );

      // Save to Firestore if first login
      final userDoc = _firestore
          .collection('users')
          .doc(userCredential.user!.uid);
      final snapshot = await userDoc.get();
      if (!snapshot.exists) {
        final fullName = userCredential.user!.displayName ?? '';
        final nameParts = fullName.split(' ');
        await userDoc.set({
          'firstName': nameParts.isNotEmpty ? nameParts[0] : '',
          'lastName': nameParts.length > 1
              ? nameParts.sublist(1).join(' ')
              : '',
          'email': userCredential.user!.email,
          'uid': userCredential.user!.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return userCredential.user;
    } catch (e) {
      rethrow;
    }
  }

  /// ===== Email Sign-Up =====
  Future<User?> signUpWithEmail({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save user profile to Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'uid': userCredential.user!.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return userCredential.user;
    } catch (e) {
      rethrow;
    }
  }

  /// ===== Email Sign-In =====
  Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      rethrow;
    }
  }

  /// ===== Password Reset =====
  Future<void> resetPassword({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  /// ===== Sign Out =====
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    await _googleSignIn.signOut();
  }
}
