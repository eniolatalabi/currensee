import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/services/auth_service.dart';

/// 🔹 Centralized user-friendly messages
class AuthMessages {
  static const signUpSuccess =
      "Welcome aboard! We've sent a confirmation link to your email.";
  static const signInSuccess = "You're signed in. Welcome back!";
  static const emailNotVerified =
      "Please confirm your email before signing in. Didn't get the link? Check spam or request a new one.";
  static const resetPasswordSuccess =
      "We've sent you a reset link. Please check your inbox.";
  static const accountExists =
      "This email is already registered. Try signing in instead.";
  static const wrongPassword =
      "That password doesn't look right. Try again or reset it.";
  static const userNotFound =
      "No account found with this email. Would you like to create one?";
  static const networkError =
      "Network timeout. Please check your connection and try again.";
  static const weakPassword =
      "Please choose a stronger password (at least 6 characters).";
  static const invalidEmail = "Please enter a valid email address.";
  static const genericError = "Something went wrong. Please try again later.";
}

/// 🔹 Enhanced AuthController with improved state management
class AuthController with ChangeNotifier {
  final AuthService _authService = AuthService.instance;
  final UserRepository _userRepository = UserRepository();

  /// 🔹 Guest fallback user (non-nullable safety)
  static final AppUser guestUser = AppUser(
    uid: "guest",
    firstName: "Guest",
    lastName: "User",
    email: "",
    photoURL: null,
    createdAt: DateTime.fromMillisecondsSinceEpoch(0),
  );

  /// 🔹 Always non-nullable current user
  AppUser _currentUser = guestUser;
  AppUser get currentUser => _currentUser;

  /// ✅ One-liner getter for AuthScreen compatibility
  User? get user => FirebaseAuth.instance.currentUser;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _successMessage;
  String? get successMessage => _successMessage;

  // 🔹 Enhanced utility methods with proper state management
  void _setLoading(bool value) {
    if (_isLoading != value) {
      // Only notify if state actually changes
      _isLoading = value;
      notifyListeners();
    }
  }

  void _clearMessages() {
    bool shouldNotify = _errorMessage != null || _successMessage != null;
    _errorMessage = null;
    _successMessage = null;
    if (shouldNotify) {
      notifyListeners();
    }
  }

  void clearMessages() => _clearMessages();

  void _setError(String msg) {
    _errorMessage = msg;
    _successMessage = null;
    notifyListeners();
  }

  void _setSuccess(String msg) {
    _successMessage = msg;
    _errorMessage = null;
    notifyListeners();
  }

  /// 🔹 Enhanced error message mapping
  String _mapErrorToMessage(String? errorMessage) {
    if (errorMessage == null) return AuthMessages.genericError;

    final error = errorMessage.toLowerCase();

    if (error.contains("email-already-in-use") ||
        error.contains("already registered")) {
      return AuthMessages.accountExists;
    } else if (error.contains("wrong-password") ||
        error.contains("invalid-credential")) {
      return AuthMessages.wrongPassword;
    } else if (error.contains("user-not-found")) {
      return AuthMessages.userNotFound;
    } else if (error.contains("weak-password")) {
      return AuthMessages.weakPassword;
    } else if (error.contains("invalid-email") ||
        error.contains("badly formatted")) {
      return AuthMessages.invalidEmail;
    } else if (error.contains("timeout") ||
        error.contains("network") ||
        error.contains("connection")) {
      return AuthMessages.networkError;
    } else {
      return AuthMessages.genericError;
    }
  }

  /// 🔹 Enhanced profile fetching with retry logic and fallback user creation
  Future<void> _fetchUserProfile(String uid) async {
    int retryCount = 0;
    const maxRetries = 3;
    const retryDelay = Duration(seconds: 2);

    while (retryCount < maxRetries) {
      try {
        final profile = await _userRepository.getUserProfile(uid);
        if (profile != null) {
          _currentUser = profile;
          notifyListeners();
          return;
        } else {
          // Profile doesn't exist, create a basic one from Firebase user
          final firebaseUser = FirebaseAuth.instance.currentUser;
          if (firebaseUser != null) {
            final basicUser = AppUser(
              uid: uid,
              firstName: firebaseUser.displayName?.split(' ').first ?? '',
              lastName:
                  firebaseUser.displayName?.split(' ').skip(1).join(' ') ?? '',
              email: firebaseUser.email ?? '',
              photoURL: firebaseUser.photoURL,
              createdAt: DateTime.now(),
            );

            try {
              await _userRepository.createUserProfile(basicUser);
              _currentUser = basicUser;
            } catch (e) {
              debugPrint('Failed to create basic profile: $e');
              _currentUser =
                  basicUser; // Use it anyway, just don't save to Firestore
            }

            notifyListeners();
            return;
          }
        }
      } catch (e) {
        debugPrint(
          'Failed to fetch user profile (attempt ${retryCount + 1}): $e',
        );
        retryCount++;

        if (retryCount < maxRetries) {
          await Future.delayed(retryDelay);
        } else {
          // Final fallback - create user from Firebase auth data
          final firebaseUser = FirebaseAuth.instance.currentUser;
          if (firebaseUser != null) {
            _currentUser = AppUser(
              uid: uid,
              firstName: firebaseUser.displayName?.split(' ').first ?? '',
              lastName:
                  firebaseUser.displayName?.split(' ').skip(1).join(' ') ?? '',
              email: firebaseUser.email ?? '',
              photoURL: firebaseUser.photoURL,
              createdAt: DateTime.now(),
            );
            notifyListeners();
          }
          break;
        }
      }
    }
  }

  /// 🔹 ENHANCED: Sign up with comprehensive error handling
  Future<bool> signUpWithEmail({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    if (_isLoading) return false; // Prevent multiple simultaneous calls

    _setLoading(true);
    _clearMessages();

    try {
      final result = await _authService.signUpWithEmail(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
      );

      if (result.isSuccess && result.user != null) {
        // Create AppUser model
        final appUser = AppUser(
          uid: result.user!.uid,
          firstName: firstName,
          lastName: lastName,
          email: email,
          photoURL: result.user!.photoURL,
          createdAt: DateTime.now(),
        );

        try {
          // Store in repository (backup if AuthService didn't handle it)
          await _userRepository.createUserProfile(appUser);
        } catch (e) {
          debugPrint('Repository save failed, but auth succeeded: $e');
          // Continue anyway since AuthService should have handled it
        }

        // Send verification email with retry logic
        try {
          await result.user!.sendEmailVerification();
        } catch (e) {
          debugPrint('Failed to send verification email: $e');
          // Don't fail the signup for this
        }

        // Sign out immediately (user must verify email first)
        await _authService.signOut();
        _currentUser = guestUser;

        // Set success message
        _setSuccess(result.successMessage ?? AuthMessages.signUpSuccess);
        return true;
      } else if (result.isCancelled) {
        // User cancelled, don't show error
        return false;
      } else {
        // Handle specific errors with improved mapping
        _setError(_mapErrorToMessage(result.errorMessage));
        return false;
      }
    } catch (e) {
      debugPrint('AuthController.signUpWithEmail error: $e');
      _setError(AuthMessages.genericError);
      return false;
    } finally {
      _setLoading(false); // CRITICAL: Always reset loading state
    }
  }

  /// 🔹 ENHANCED: Sign in with improved error handling
  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (_isLoading) return false;

    _setLoading(true);
    _clearMessages();

    try {
      final result = await _authService.signInWithEmail(
        email: email,
        password: password,
      );

      if (result.isSuccess && result.user != null) {
        // Check email verification
        if (!result.user!.emailVerified) {
          await _authService.signOut();
          _currentUser = guestUser;
          _setError(AuthMessages.emailNotVerified);
          return false;
        }

        // Fetch user profile with enhanced retry logic
        await _fetchUserProfile(result.user!.uid);
        _setSuccess(AuthMessages.signInSuccess);
        return true;
      } else if (result.isCancelled) {
        return false;
      } else {
        _setError(_mapErrorToMessage(result.errorMessage));
        return false;
      }
    } catch (e) {
      debugPrint('AuthController.signInWithEmail error: $e');
      _setError(AuthMessages.genericError);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 🔹 ENHANCED: Google sign-in with better error handling and profile creation
  Future<bool> signInWithGoogle() async {
    if (_isLoading) return false;

    _setLoading(true);
    _clearMessages();

    try {
      final result = await _authService.signInWithGoogle();

      if (result.isSuccess && result.user != null) {
        // Fetch or create user profile with enhanced retry logic
        await _fetchUserProfile(result.user!.uid);
        _setSuccess(AuthMessages.signInSuccess);
        return true;
      } else if (result.isCancelled) {
        return false;
      } else {
        _setError(result.errorMessage ?? AuthMessages.genericError);
        return false;
      }
    } catch (e) {
      debugPrint('AuthController.signInWithGoogle error: $e');
      _setError(AuthMessages.genericError);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 🔹 ENHANCED: Reset password with better error handling
  Future<bool> resetPassword({required String email}) async {
    if (_isLoading) return false;

    _setLoading(true);
    _clearMessages();

    try {
      await _authService.resetPassword(email: email);
      _setSuccess(AuthMessages.resetPasswordSuccess);
      return true;
    } catch (e) {
      debugPrint('AuthController.resetPassword error: $e');
      _setError(_mapErrorToMessage(e.toString()));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 🔹 Sign out with proper cleanup
  Future<void> signOut() async {
    try {
      await _authService.signOut();
    } catch (e) {
      debugPrint('Error during signOut: $e');
    } finally {
      _currentUser = guestUser;
      _clearMessages();
      notifyListeners();
    }
  }

  /// 🔹 Reload user on app start with error handling
  Future<void> reloadUser() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.emailVerified) {
        await _fetchUserProfile(user.uid);
      } else {
        _currentUser = guestUser;
      }
    } catch (e) {
      debugPrint('Error reloading user: $e');
      _currentUser = guestUser;
    } finally {
      notifyListeners();
    }
  }

  /// 🔹 Resend email verification
  Future<bool> resendEmailVerification() async {
    if (_isLoading) return false;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    _setLoading(true);
    _clearMessages();

    try {
      await user.sendEmailVerification();
      _setSuccess("Verification email sent! Please check your inbox.");
      return true;
    } catch (e) {
      debugPrint('Failed to resend verification email: $e');
      _setError("Failed to send verification email. Please try again.");
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 🔹 IMPROVED: Authentication check that prioritizes Firebase Auth state
  /// This ensures users can access home even when Firestore is temporarily unavailable
  bool get isAuthenticated {
    final firebaseUser = FirebaseAuth.instance.currentUser;

    // If no Firebase user, definitely not authenticated
    if (firebaseUser == null) return false;

    // If Firebase user exists but email is not verified, not authenticated
    if (!firebaseUser.emailVerified) return false;

    // If we have a valid Firebase user with verified email, consider authenticated
    // This allows access even if Firestore profile fetch failed temporarily
    return true;
  }

  /// 🔹 Dispose method for cleanup
  @override
  void dispose() {
    // Clean up any listeners or resources if needed
    super.dispose();
  }
}
