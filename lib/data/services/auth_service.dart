import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  AuthService._privateConstructor();
  static final AuthService instance = AuthService._privateConstructor();

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// GOOGLE SIGN-IN
  Future<AuthResult> signInWithGoogle() async {
    try {
      await _googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return AuthResult.cancelled();

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        return AuthResult.error(
          'Authentication service is temporarily unavailable. Please try again.',
        );
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );

      if (userCredential.user != null) {
        await _saveUserToFirestore(userCredential.user!);
        return AuthResult.success(userCredential.user!);
      }

      return AuthResult.error('Sign-in failed. Please try again.');
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_getFirebaseErrorMessage(e));
    } catch (e) {
      if (e.toString().contains('DEVELOPER_ERROR') ||
          e.toString().contains('10')) {
        return AuthResult.error(
          'Authentication service is currently unavailable. Please try again later.',
        );
      }
      return AuthResult.error(
        'Something went wrong. Please check your connection and try again.',
      );
    }
  }

  /// EMAIL SIGN-UP WITH VERIFICATION - FIXED VERSION
  Future<AuthResult> signUpWithEmail({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    try {
      // Step 1: Create Firebase Auth user with timeout
      final userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception(
                'Request timed out. Please check your connection.',
              );
            },
          );

      final user = userCredential.user;
      if (user == null) {
        return AuthResult.error('Account creation failed. Please try again.');
      }

      try {
        // Step 2: Save to Firestore with timeout and transaction-like behavior
        await _firestore
            .collection('users')
            .doc(user.uid)
            .set({
              'firstName': firstName,
              'lastName': lastName,
              'email': email,
              'uid': user.uid,
              'createdAt': FieldValue.serverTimestamp(),
              'isEmailVerified': false,
            })
            .timeout(
              const Duration(seconds: 15),
              onTimeout: () {
                throw Exception(
                  'Database timeout. Your account was created but profile setup failed.',
                );
              },
            );

        // Step 3: Send verification email with timeout
        try {
          await user.sendEmailVerification().timeout(
            const Duration(seconds: 10),
          );

          return AuthResult.success(
            user,
            message:
                'Account created! Please check your email to verify your account.',
          );
        } catch (emailError) {
          // Account and profile created successfully, but email failed
          return AuthResult.success(
            user,
            message:
                'Account created! Please request a verification email from the sign-in page.',
          );
        }
      } catch (firestoreError) {
        // Rollback: Delete the Firebase Auth user if Firestore fails
        try {
          await user.delete();
        } catch (_) {
          // If rollback fails, log but don't throw
          print('Failed to rollback user creation: $firestoreError');
        }

        if (firestoreError.toString().contains('timeout')) {
          return AuthResult.error(
            'Network timeout. Please check your connection and try again.',
          );
        }

        return AuthResult.error('Account creation failed. Please try again.');
      }
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_getFirebaseErrorMessage(e));
    } catch (e) {
      if (e.toString().contains('timeout')) {
        return AuthResult.error(
          'Request timed out. Please check your connection and try again.',
        );
      }
      return AuthResult.error('Something went wrong. Please try again.');
    }
  }

  /// EMAIL SIGN-IN (requires email verified) - ENHANCED WITH TIMEOUT
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception(
                'Sign-in timed out. Please check your connection.',
              );
            },
          );

      final user = userCredential.user;
      if (user == null) {
        return AuthResult.error('Sign-in failed. Please try again.');
      }

      // Refresh user to get latest email verification status
      await user.reload();
      final refreshedUser = _firebaseAuth.currentUser;

      if (refreshedUser != null && !refreshedUser.emailVerified) {
        await _firebaseAuth.signOut();
        return AuthResult.error('Please verify your email before signing in.');
      }

      return AuthResult.success(refreshedUser ?? user);
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_getFirebaseErrorMessage(e));
    } catch (e) {
      if (e.toString().contains('timeout')) {
        return AuthResult.error(
          'Sign-in timed out. Please check your connection and try again.',
        );
      }
      return AuthResult.error('Something went wrong. Please try again.');
    }
  }

  /// PASSWORD RESET - ENHANCED WITH TIMEOUT
  Future<AuthResult> resetPassword({required String email}) async {
    try {
      await _firebaseAuth
          .sendPasswordResetEmail(email: email)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw Exception(
                'Request timed out. Please check your connection.',
              );
            },
          );

      return AuthResult.success(
        null,
        message: 'Password reset email sent! Check your inbox.',
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_getFirebaseErrorMessage(e));
    } catch (e) {
      if (e.toString().contains('timeout')) {
        return AuthResult.error(
          'Request timed out. Please check your connection and try again.',
        );
      }
      return AuthResult.error('Unable to send reset email. Please try again.');
    }
  }

  /// SIGN OUT - ENHANCED WITH TIMEOUT
  Future<void> signOut() async {
    try {
      await Future.wait([
        _firebaseAuth.signOut(),
        _googleSignIn.signOut(),
      ]).timeout(const Duration(seconds: 10));
    } catch (e) {
      // Sign out should not fail the user experience
      print('Sign out error (non-critical): $e');
    }
  }

  /// SAVE USER TO FIRESTORE (Google users mainly) - ENHANCED WITH TIMEOUT
  Future<void> _saveUserToFirestore(User user) async {
    try {
      final userDoc = _firestore.collection('users').doc(user.uid);
      final snapshot = await userDoc.get().timeout(const Duration(seconds: 10));

      if (!snapshot.exists) {
        final fullName = user.displayName ?? '';
        final nameParts = fullName.split(' ');

        await userDoc
            .set({
              'firstName': nameParts.isNotEmpty ? nameParts[0] : '',
              'lastName': nameParts.length > 1
                  ? nameParts.sublist(1).join(' ')
                  : '',
              'email': user.email,
              'uid': user.uid,
              'createdAt': FieldValue.serverTimestamp(),
              'photoURL': user.photoURL,
              'isEmailVerified': user.emailVerified,
            })
            .timeout(const Duration(seconds: 10));
      }
    } catch (e) {
      // fail silently, auth was successful
      print('Firestore save error (non-critical): $e');
    }
  }

  /// ERROR HANDLER - ENHANCED WITH MORE CASES
  String _getFirebaseErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email. Please sign up first.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled. Please contact support.';
      case 'invalid-credential':
        return 'Invalid email or password. Please check your credentials.';
      case 'email-already-in-use':
        return 'An account with this email already exists. Please sign in instead.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'network-request-failed':
        return 'Network error. Please check your connection and try again.';
      case 'requires-recent-login':
        return 'Please sign out and sign in again to perform this action.';
      case 'invalid-verification-code':
        return 'Invalid verification code. Please try again.';
      case 'invalid-verification-id':
        return 'Invalid verification ID. Please try again.';
      case 'missing-verification-code':
        return 'Please enter the verification code.';
      case 'missing-verification-id':
        return 'Verification ID is missing. Please try again.';
      case 'quota-exceeded':
        return 'Quota exceeded. Please try again later.';
      case 'captcha-check-failed':
        return 'Captcha verification failed. Please try again.';
      case 'app-not-authorized':
        return 'App is not authorized. Please contact support.';
      case 'keychain-error':
        return 'Keychain error. Please try again.';
      case 'internal-error':
        return 'Internal error occurred. Please try again later.';
      case 'invalid-app-credential':
        return 'Invalid app credential. Please contact support.';
      case 'user-mismatch':
        return 'User mismatch detected. Please try again.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with a different sign-in method.';
      case 'credential-already-in-use':
        return 'This credential is already associated with another account.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}

/// RESULT WRAPPER
class AuthResult {
  final bool isSuccess;
  final User? user;
  final String? errorMessage;
  final String? successMessage;
  final bool isCancelled;

  AuthResult._(
    this.isSuccess,
    this.user,
    this.errorMessage,
    this.successMessage,
    this.isCancelled,
  );

  factory AuthResult.success(User? user, {String? message}) =>
      AuthResult._(true, user, null, message, false);

  factory AuthResult.error(String message) =>
      AuthResult._(false, null, message, null, false);

  factory AuthResult.cancelled() => AuthResult._(false, null, null, null, true);
}
