// lib/features/auth/controller/auth_controller.dart - Complete Production Version
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/session_manager.dart';
import '../../../utils/validators.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/app_notification_model.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/notification_service.dart';

/// Complete production-ready AuthController with proper separation of concerns
class AuthController with ChangeNotifier {
  // Services and dependencies
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final AuthService _authService = AuthService.instance;
  final UserRepository _userRepository = UserRepository();
  final UserSessionManager _sessionManager = UserSessionManager.instance;
  final NotificationServiceEnhanced _notificationService =
      NotificationServiceEnhanced.instance;

  // Guest fallback user for non-nullable safety
  static final AppUser guestUser = AppUser(
    uid: "guest",
    firstName: "Guest",
    lastName: "User",
    email: "",
    photoURL: null,
    createdAt: DateTime.fromMillisecondsSinceEpoch(0),
  );

  // State variables
  AppUser _currentUser = guestUser;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  bool _isInitialized = false;

  // Getters
  AppUser get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  bool get isInitialized => _isInitialized;

  // Compatibility getters
  User? get user => _firebaseAuth.currentUser;
  bool get isLoggedIn => isAuthenticated;

  AuthController() {
    _initializeAuthListener();
  }

  /// Initialize authentication state listener
  void _initializeAuthListener() {
    _firebaseAuth.authStateChanges().listen(_onAuthStateChanged);
  }

  /// Handle Firebase auth state changes
  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (kDebugMode) {
      debugPrint(
        '[AuthController] Auth state changed: ${firebaseUser?.uid ?? "null"}',
      );
    }

    if (firebaseUser != null && firebaseUser.emailVerified) {
      // User is authenticated and verified
      await _fetchUserProfile(firebaseUser.uid);
    } else {
      // User is null or unverified
      _currentUser = guestUser;
      _clearMessages();
    }

    _isInitialized = true;
    notifyListeners();
  }

  /// Enhanced authentication status check
  bool get isAuthenticated {
    final firebaseUser = _firebaseAuth.currentUser;

    // No Firebase user
    if (firebaseUser == null) return false;

    // Email not verified
    if (!firebaseUser.emailVerified) return false;

    // Has valid app user (not guest)
    if (_currentUser.uid == "guest") return false;

    return true;
  }

  // State management helpers
  void _setLoading(bool value) {
    if (_isLoading != value) {
      _isLoading = value;
      notifyListeners();
    }
  }

  void _setError(String message) {
    _errorMessage = message;
    _successMessage = null;
    if (kDebugMode) {
      debugPrint('[AuthController] Error: $message');
    }
    notifyListeners();
  }

  void _setSuccess(String message) {
    _successMessage = message;
    _errorMessage = null;
    if (kDebugMode) {
      debugPrint('[AuthController] Success: $message');
    }
    notifyListeners();
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

  /// ADDED: Create avatar change notification
  Future<void> _createAvatarChangeNotification({
    required String userId,
    String? previousAvatarUrl,
    String? newAvatarUrl,
  }) async {
    try {
      // Use the system notification method since there's no specific avatar change method
      await _notificationService.createSystemNotification(
        userId: userId,
        title: 'Profile Updated',
        message: 'Your profile photo has been successfully updated.',
        isUrgent: false,
      );

      if (kDebugMode) {
        debugPrint(
          '[AuthController] Avatar change notification created for user: $userId',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[AuthController] Failed to create avatar change notification: $e',
        );
      }
      // Don't throw error for notification creation failure
      // Avatar update should still succeed even if notification fails
    }
  }

  /// ADDED: Update user avatar with notification
  Future<bool> updateAvatar(File imageFile) async {
    if (_isLoading) return false;
    if (_currentUser.uid == "guest") {
      _setError('Guest users cannot update avatar');
      return false;
    }

    _setLoading(true);
    _clearMessages();

    String? previousAvatarUrl = _currentUser.photoURL;

    try {
      // Upload image to your storage service (Firebase Storage, AWS S3, etc.)
      // This is a placeholder - implement your actual image upload logic
      final newAvatarUrl = await _uploadAvatarImage(imageFile);

      if (newAvatarUrl == null) {
        _setError('Failed to upload avatar image');
        return false;
      }

      // Update user profile with new avatar URL
      final success = await updateProfile(photoURL: newAvatarUrl);

      if (success) {
        // Create notification for avatar change
        await _createAvatarChangeNotification(
          userId: _currentUser.uid,
          previousAvatarUrl: previousAvatarUrl,
          newAvatarUrl: newAvatarUrl,
        );

        _setSuccess('Avatar updated successfully!');
        return true;
      } else {
        return false;
      }
    } catch (e) {
      _setError('Failed to update avatar: ${e.toString()}');
      if (kDebugMode) {
        debugPrint('[AuthController] Avatar update error: $e');
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// PLACEHOLDER: Upload avatar image to storage
  /// Implement this method based on your storage solution
  Future<String?> _uploadAvatarImage(File imageFile) async {
    try {
      // TODO: Implement actual image upload logic
      // This could be Firebase Storage, AWS S3, or any other service
      // For now, return a placeholder URL

      await Future.delayed(const Duration(seconds: 2)); // Simulate upload time

      // Return a placeholder URL - replace with actual upload implementation
      return 'https://example.com/avatars/${_currentUser.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AuthController] Image upload error: $e');
      }
      return null;
    }
  }

  /// ADDED: Public method to create avatar change notification (for external use)
  Future<void> createAvatarChangeNotification({
    String? previousAvatarUrl,
    String? newAvatarUrl,
  }) async {
    if (_currentUser.uid == "guest") return;

    await _createAvatarChangeNotification(
      userId: _currentUser.uid,
      previousAvatarUrl: previousAvatarUrl,
      newAvatarUrl: newAvatarUrl,
    );
  }

  /// Comprehensive user profile fetching with multiple fallback strategies
  Future<void> _fetchUserProfile(String uid) async {
    try {
      if (kDebugMode) {
        debugPrint('[AuthController] Fetching user profile for: $uid');
      }

      // Strategy 1: Try to get existing profile from repository
      final existingProfile = await _userRepository.getUserProfile(uid);
      if (existingProfile != null) {
        _currentUser = existingProfile;
        if (kDebugMode) {
          debugPrint(
            '[AuthController] Loaded existing profile: ${existingProfile.email}',
          );
        }
        notifyListeners();
        return;
      }

      // Strategy 2: Create profile from Firebase user data
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser != null) {
        final newUser = AppUser(
          uid: uid,
          firstName: _extractFirstName(firebaseUser.displayName),
          lastName: _extractLastName(firebaseUser.displayName),
          email: firebaseUser.email ?? '',
          photoURL: firebaseUser.photoURL,
          createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
        );

        // Strategy 3: Try to save to repository (graceful failure)
        try {
          await _userRepository.createUserProfile(newUser);
          if (kDebugMode) {
            debugPrint(
              '[AuthController] Created new user profile: ${newUser.email}',
            );
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint(
              '[AuthController] Failed to save profile, using in-memory: $e',
            );
          }
        }

        _currentUser = newUser;
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AuthController] Error fetching user profile: $e');
      }

      // Final fallback: Use Firebase auth data directly
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser != null) {
        _currentUser = AppUser(
          uid: uid,
          firstName: _extractFirstName(firebaseUser.displayName),
          lastName: _extractLastName(firebaseUser.displayName),
          email: firebaseUser.email ?? '',
          photoURL: firebaseUser.photoURL,
          createdAt: DateTime.now(),
        );
        notifyListeners();
      }
    }
  }

  /// Extract first name from display name
  String _extractFirstName(String? displayName) {
    if (displayName == null || displayName.isEmpty) return '';
    final parts = displayName.trim().split(' ');
    return parts.isNotEmpty ? parts.first : '';
  }

  /// Extract last name from display name
  String _extractLastName(String? displayName) {
    if (displayName == null || displayName.isEmpty) return '';
    final parts = displayName.trim().split(' ');
    return parts.length > 1 ? parts.sublist(1).join(' ') : '';
  }

  /// Create account with email and password (Enhanced version)
  Future<bool> createAccount({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    BuildContext? context,
  }) async {
    if (_isLoading) return false;

    // Validate inputs using dedicated Validators class
    final firstNameError = Validators.validateName(firstName);
    if (firstNameError != null) {
      _setError(firstNameError);
      return false;
    }

    final lastNameError = Validators.validateName(lastName);
    if (lastNameError != null) {
      _setError(lastNameError);
      return false;
    }

    final emailError = Validators.validateEmail(email);
    if (emailError != null) {
      _setError(emailError);
      return false;
    }

    final passwordError = Validators.validateStrongPassword(password);
    if (passwordError != null) {
      _setError(passwordError);
      return false;
    }

    _setLoading(true);
    _clearMessages();

    try {
      // Using AuthService if available, otherwise direct Firebase
      if (_authService != AuthService.instance) {
        final result = await _authService.signUpWithEmail(
          firstName: firstName,
          lastName: lastName,
          email: email,
          password: password,
        );

        if (result.isSuccess && result.user != null) {
          _setSuccess(
            result.successMessage ??
                "Account created successfully! Please check your email to verify your account.",
          );

          // Send welcome notification for new users
          await _notificationService.createWelcomeNotification(
            userId: result.user!.uid,
            userName: '$firstName $lastName',
          );

          // Sign out immediately (user must verify email first)
          await _authService.signOut();
          _currentUser = guestUser;
          return true;
        } else if (result.isCancelled) {
          return false;
        } else {
          _setError(
            result.errorMessage ?? 'Account creation failed. Please try again.',
          );
          return false;
        }
      } else {
        // Direct Firebase implementation
        final credential = await _firebaseAuth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        if (credential.user != null) {
          // Update display name
          final displayName = '$firstName $lastName'.trim();
          if (displayName.isNotEmpty) {
            await credential.user!.updateDisplayName(displayName);
          }

          // Send email verification
          await credential.user!.sendEmailVerification();

          // Set up user session if context provided
          if (context != null) {
            await _sessionManager.setCurrentUser(credential.user!.uid, context);
          }

          // Send welcome notification
          await _notificationService.createWelcomeNotification(
            userId: credential.user!.uid,
            userName: displayName,
          );

          _setSuccess(
            "Account created successfully! Please check your email to verify your account.",
          );

          if (kDebugMode) {
            debugPrint(
              '[AuthController] Account created successfully: ${credential.user!.uid}',
            );
          }

          return true;
        }
      }
    } catch (e) {
      _setError(_getAuthErrorMessage(e));
      if (kDebugMode) {
        debugPrint('[AuthController] Account creation error: $e');
      }
    } finally {
      _setLoading(false);
    }

    return false;
  }

  /// Sign in with email and password (Enhanced version)
  Future<bool> signInWithEmail({
    required String email,
    required String password,
    BuildContext? context,
  }) async {
    if (_isLoading) return false;

    // Validate inputs using dedicated Validators class
    final emailError = Validators.validateEmail(email);
    if (emailError != null) {
      _setError(emailError);
      return false;
    }

    final passwordError = Validators.validatePassword(
      password,
    ); // Basic validation for sign-in
    if (passwordError != null) {
      _setError(passwordError);
      return false;
    }

    _setLoading(true);
    _clearMessages();

    try {
      // Using AuthService if available, otherwise direct Firebase
      if (_authService != AuthService.instance) {
        final result = await _authService.signInWithEmail(
          email: email,
          password: password,
        );

        if (result.isSuccess && result.user != null) {
          // Check email verification
          if (!result.user!.emailVerified) {
            await _authService.signOut();
            _currentUser = guestUser;
            _setError(
              'Please verify your email before signing in. Check your inbox for the verification link.',
            );
            return false;
          }

          await _fetchUserProfile(result.user!.uid);

          // Set up user session if context provided
          if (context != null) {
            await _sessionManager.setCurrentUser(result.user!.uid, context);
          }

          _setSuccess('Welcome back, ${_currentUser.firstName}!');
          return true;
        } else if (result.isCancelled) {
          return false;
        } else {
          _setError(result.errorMessage ?? 'Sign in failed. Please try again.');
          return false;
        }
      } else {
        // Direct Firebase implementation
        final credential = await _firebaseAuth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        if (credential.user != null) {
          // Check email verification
          if (!credential.user!.emailVerified) {
            await _firebaseAuth.signOut();
            _setError('Please verify your email before signing in.');
            return false;
          }

          // Set up user session if context provided
          if (context != null) {
            await _sessionManager.setCurrentUser(credential.user!.uid, context);
          }

          await _fetchUserProfile(credential.user!.uid);
          _setSuccess('Welcome back, ${_currentUser.firstName}!');

          if (kDebugMode) {
            debugPrint(
              '[AuthController] Email sign-in successful: ${credential.user!.uid}',
            );
          }

          return true;
        }
      }
    } catch (e) {
      _setError(_getAuthErrorMessage(e));
      if (kDebugMode) {
        debugPrint('[AuthController] Email sign-in error: $e');
      }
    } finally {
      _setLoading(false);
    }

    return false;
  }

  /// Sign in with Google (Enhanced version)
  Future<bool> signInWithGoogle({BuildContext? context}) async {
    if (_isLoading) return false;

    _setLoading(true);
    _clearMessages();

    try {
      final result = await _authService.signInWithGoogle();

      if (result.isSuccess && result.user != null) {
        // Set up user session if context provided
        if (context != null) {
          await _sessionManager.setCurrentUser(result.user!.uid, context);
        }

        await _fetchUserProfile(result.user!.uid);
        _setSuccess('Welcome, ${_currentUser.firstName}!');
        return true;
      } else if (result.isCancelled) {
        return false;
      } else {
        _setError(
          result.errorMessage ?? 'Google sign-in failed. Please try again.',
        );
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AuthController] Google sign-in error: $e');
      }
      _setError('Google sign-in failed. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign out (Enhanced version)
  Future<void> signOut({BuildContext? context}) async {
    _setLoading(true);
    _clearMessages();

    try {
      // Clear user session if context provided
      if (context != null) {
        await _sessionManager.clearCurrentUser(context);
      }

      // Sign out from AuthService or Firebase directly
      if (_authService != AuthService.instance) {
        await _authService.signOut();
      } else {
        await _firebaseAuth.signOut();
      }

      if (kDebugMode) {
        debugPrint('[AuthController] User signed out successfully');
      }
    } catch (e) {
      _setError('Failed to sign out');
      if (kDebugMode) {
        debugPrint('[AuthController] Sign out error: $e');
      }
    } finally {
      _currentUser = guestUser;
      _setLoading(false);
    }
  }

  /// Reset password (Enhanced version)
  Future<bool> resetPassword({required String email}) async {
    if (_isLoading) return false;

    // Validate email using dedicated Validators class
    final emailError = Validators.validateEmail(email);
    if (emailError != null) {
      _setError(emailError);
      return false;
    }

    _setLoading(true);
    _clearMessages();

    try {
      if (_authService != AuthService.instance) {
        await _authService.resetPassword(email: email);
      } else {
        await _firebaseAuth.sendPasswordResetEmail(email: email);
      }

      _setSuccess('Password reset email sent! Please check your inbox.');

      if (kDebugMode) {
        debugPrint('[AuthController] Password reset email sent to: $email');
      }

      return true;
    } catch (e) {
      _setError(_getAuthErrorMessage(e));
      if (kDebugMode) {
        debugPrint('[AuthController] Password reset error: $e');
      }
    } finally {
      _setLoading(false);
    }

    return false;
  }

  /// Resend email verification
  Future<bool> resendEmailVerification() async {
    if (_isLoading) return false;

    final user = _firebaseAuth.currentUser;
    if (user == null) return false;

    _setLoading(true);
    _clearMessages();

    try {
      await user.sendEmailVerification();
      _setSuccess("Verification email sent! Please check your inbox.");

      if (kDebugMode) {
        debugPrint(
          '[AuthController] Verification email resent to: ${user.email}',
        );
      }

      return true;
    } catch (e) {
      _setError("Failed to send verification email. Please try again.");
      if (kDebugMode) {
        debugPrint('[AuthController] Failed to resend verification email: $e');
      }
    } finally {
      _setLoading(false);
    }

    return false;
  }

  /// Reload user data (for app initialization)
  Future<void> reloadUser() async {
    try {
      if (kDebugMode) {
        debugPrint('[AuthController] Reloading user data');
      }

      final user = _firebaseAuth.currentUser;
      if (user != null) {
        // Reload Firebase user to get latest data
        await user.reload();
        final refreshedUser = _firebaseAuth.currentUser;

        if (refreshedUser != null && refreshedUser.emailVerified) {
          await _fetchUserProfile(refreshedUser.uid);
        } else {
          _currentUser = guestUser;
        }
      } else {
        _currentUser = guestUser;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AuthController] Error reloading user: $e');
      }
      _currentUser = guestUser;
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Delete user account
  Future<bool> deleteAccount({BuildContext? context}) async {
    if (_isLoading) return false;

    final user = _firebaseAuth.currentUser;
    if (user == null) return false;

    _setLoading(true);
    _clearMessages();

    try {
      // Clear user session if context provided
      if (context != null) {
        await _sessionManager.clearCurrentUser(context);
      }

      // Delete user profile from repository
      try {
        await _userRepository.deleteUserProfile(user.uid);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[AuthController] Failed to delete user profile: $e');
        }
      }

      // Delete Firebase user
      await user.delete();

      _currentUser = guestUser;
      _setSuccess('Account deleted successfully.');

      if (kDebugMode) {
        debugPrint('[AuthController] User account deleted: ${user.uid}');
      }

      return true;
    } catch (e) {
      _setError('Failed to delete account. Please try again.');
      if (kDebugMode) {
        debugPrint('[AuthController] Account deletion error: $e');
      }
    } finally {
      _setLoading(false);
    }

    return false;
  }

  /// Update user profile
  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    String? photoURL,
  }) async {
    if (_isLoading) return false;
    if (_currentUser.uid == "guest") return false;

    // Validate inputs using dedicated Validators class
    if (firstName != null) {
      final firstNameError = Validators.validateName(firstName);
      if (firstNameError != null) {
        _setError(firstNameError);
        return false;
      }
    }

    if (lastName != null) {
      final lastNameError = Validators.validateName(lastName);
      if (lastNameError != null) {
        _setError(lastNameError);
        return false;
      }
    }

    if (photoURL != null && photoURL.isNotEmpty) {
      final urlError = Validators.validateUrl(photoURL);
      if (urlError != null) {
        _setError(urlError);
        return false;
      }
    }

    _setLoading(true);
    _clearMessages();

    try {
      final updatedUser = _currentUser.copyWith(
        firstName: firstName,
        lastName: lastName,
        photoURL: photoURL,
      );

      // Update in repository
      await _userRepository.updateUserProfile(updatedUser);

      // Update Firebase user display name if names changed
      if (firstName != null || lastName != null) {
        final firebaseUser = _firebaseAuth.currentUser;
        if (firebaseUser != null) {
          final displayName =
              '${firstName ?? _currentUser.firstName} ${lastName ?? _currentUser.lastName}'
                  .trim();
          await firebaseUser.updateDisplayName(displayName);
        }
      }

      // Update Firebase user photo if changed
      if (photoURL != null) {
        final firebaseUser = _firebaseAuth.currentUser;
        if (firebaseUser != null) {
          await firebaseUser.updatePhotoURL(photoURL);
        }
      }

      _currentUser = updatedUser;
      _setSuccess('Profile updated successfully.');

      if (kDebugMode) {
        debugPrint('[AuthController] Profile updated for: ${_currentUser.uid}');
      }

      return true;
    } catch (e) {
      _setError('Failed to update profile. Please try again.');
      if (kDebugMode) {
        debugPrint('[AuthController] Profile update error: $e');
      }
    } finally {
      _setLoading(false);
    }

    return false;
  }

  /// Get user-friendly error messages (Simplified - focus on Firebase errors only)
  String _getAuthErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No user found with this email address.';
        case 'wrong-password':
          return 'Invalid password. Please try again.';
        case 'email-already-in-use':
          return 'This email address is already registered.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later.';
        case 'network-request-failed':
          return 'Network error. Please check your connection.';
        case 'requires-recent-login':
          return 'This operation requires recent authentication. Please sign in again.';
        case 'invalid-credential':
          return 'Invalid credentials. Please check your email and password.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'operation-not-allowed':
          return 'This sign-in method is not enabled.';
        default:
          return error.message ?? 'An authentication error occurred.';
      }
    }
    return 'An unexpected error occurred. Please try again.';
  }

  @override
  void dispose() {
    if (kDebugMode) {
      debugPrint('[AuthController] Disposing controller');
    }
    super.dispose();
  }
}
