import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyOnboardingSeen = "onboarding_seen";
  static const String _keyUserToken = "user_token";

  final SharedPreferences _prefs;

  StorageService._(this._prefs);

  static late final StorageService instance;

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    instance = StorageService._(prefs);
    return instance;
  }

  String _ns(String feature, String key) => '${feature}_$key';

  Future<void> writeString(String key, String value) async =>
      await _prefs.setString(key, value);

  Future<String?> readString(String key) async => _prefs.getString(key);

  Future<void> delete(String key) async => await _prefs.remove(key);

  Future<void> writeJson(
    String feature,
    String key,
    Map<String, dynamic> data,
  ) => writeString(_ns(feature, key), json.encode(data));

  Future<Map<String, dynamic>?> readJson(String feature, String key) async {
    final raw = await readString(_ns(feature, key));
    if (raw == null) return null;
    return json.decode(raw) as Map<String, dynamic>;
  }

  Future<void> deleteFeatureKey(String feature, String key) =>
      delete(_ns(feature, key));

  bool get hasSeenOnboarding => _prefs.getBool(_keyOnboardingSeen) ?? false;
  Future<void> setOnboardingSeen() async =>
      _prefs.setBool(_keyOnboardingSeen, true);

  String? get userToken => _prefs.getString(_keyUserToken);
  Future<void> saveUserToken(String token) async =>
      _prefs.setString(_keyUserToken, token);
  Future<void> clearUserToken() async => _prefs.remove(_keyUserToken);
}
