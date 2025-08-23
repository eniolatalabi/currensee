import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/storage_service.dart';

class AuthController extends ChangeNotifier {
  final AuthService _authService = AuthService.instance;

  bool _loading = false;
  String? _errorMessage;
  User? _user;

  bool get loading => _loading;
  String? get errorMessage => _errorMessage;
  User? get user => _user;

  AuthController() {
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _user = currentUser;
      await StorageService.instance.saveUserToken(currentUser.uid);
      notifyListeners();
    }
  }

  /// Google Sign-In
  Future<void> signInWithGoogle() async {
    _setLoading(true);
    _errorMessage = null;
    notifyListeners();

    try {
      final signedInUser = await _authService.signInWithGoogle();
      if (signedInUser != null) {
        _user = signedInUser;
        await StorageService.instance.saveUserToken(signedInUser.uid);
      } else {
        _errorMessage = 'Sign in canceled by user';
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  /// Email/Password Sign-In
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    notifyListeners();

    try {
      final signedInUser = await _authService.signInWithEmail(
        email: email,
        password: password,
      );
      if (signedInUser != null) {
        _user = signedInUser;
        await StorageService.instance.saveUserToken(signedInUser.uid);
      } else {
        _errorMessage = 'Sign in failed';
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  /// Email/Password Sign-Up
  Future<void> signUpWithEmail({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    notifyListeners();

    try {
      final newUser = await _authService.signUpWithEmail(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
      );
      if (newUser != null) {
        _user = newUser;
        await StorageService.instance.saveUserToken(newUser.uid);
      } else {
        _errorMessage = 'Sign up failed';
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  /// Password reset
  Future<void> resetPassword({required String email}) async {
    _setLoading(true);
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.resetPassword(email: email);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    await StorageService.instance.clearUserToken();
    notifyListeners();
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }
}
