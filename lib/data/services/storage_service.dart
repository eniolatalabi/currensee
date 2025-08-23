import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// StorageService - local key-value persistence (onboarding, auth, etc.)
class StorageService {
  static const String _keyOnboardingSeen = "onboarding_seen";
  static const String _keyUserToken = "user_token";

  final SharedPreferences _prefs;

  StorageService._(this._prefs);

  static late final StorageService instance;

  /// Factory initializer
  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    instance = StorageService._(prefs);
    return instance;
  }

  // Onboarding
  bool get hasSeenOnboarding => _prefs.getBool(_keyOnboardingSeen) ?? false;
  Future<void> setOnboardingSeen() async =>
      _prefs.setBool(_keyOnboardingSeen, true);

  // Auth
  String? get userToken => _prefs.getString(_keyUserToken);
  Future<void> saveUserToken(String token) async =>
      _prefs.setString(_keyUserToken, token);
  Future<void> clearUserToken() async => _prefs.remove(_keyUserToken);

  // 🚧 Dev-only: clear all prefs (only in debug mode)
  Future<void> clearAll() async {
    if (kDebugMode) {
      await _prefs.clear();
    } else {
      throw Exception("clearAll() is only allowed in debug mode!");
    }
  }
}
