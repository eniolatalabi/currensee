// lib/data/services/preferences_service.dart - ENHANCED VERSION
import 'package:flutter/foundation.dart';
import '../models/user_preferences_model.dart';
import 'storage_service.dart';

class PreferencesService {
  static const String _featureKey = 'user_preferences';
  static const String _dataKey = 'prefs';

  final StorageService _storage;

  PreferencesService(this._storage);

  static final PreferencesService instance = PreferencesService(
    StorageService.instance,
  );

  /// Get user preferences from local storage
  Future<UserPreferences> getUserPreferences() async {
    try {
      final data = await _storage.readJson(_featureKey, _dataKey);
      if (data != null) {
        return UserPreferences.fromMap(data);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PreferencesService] Error reading preferences: $e');
      }
      // Handle corrupted data gracefully
      await _storage.deleteFeatureKey(_featureKey, _dataKey);
    }

    // Return defaults if no saved preferences or error occurred
    return UserPreferences();
  }

  /// Save user preferences to local storage
  Future<void> saveUserPreferences(UserPreferences preferences) async {
    try {
      final updatedPrefs = preferences.copyWith(lastUpdated: DateTime.now());
      await _storage.writeJson(_featureKey, _dataKey, updatedPrefs.toMap());
      if (kDebugMode) {
        debugPrint('[PreferencesService] Preferences saved successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PreferencesService] Error saving preferences: $e');
      }
    }
  }

  /// Update specific preference fields (for ConversionController integration)
  Future<void> updateDefaultBaseCurrency(String currency) async {
    final prefs = await getUserPreferences();
    final updated = prefs.copyWith(defaultBaseCurrency: currency);
    await saveUserPreferences(updated);
  }

  Future<void> updateDefaultTargetCurrency(String currency) async {
    final prefs = await getUserPreferences();
    final updated = prefs.copyWith(defaultTargetCurrency: currency);
    await saveUserPreferences(updated);
  }

  Future<void> updateThemeMode(bool isDarkMode) async {
    final prefs = await getUserPreferences();
    final updated = prefs.copyWith(isDarkMode: isDarkMode);
    await saveUserPreferences(updated);
  }

  Future<void> updateNotifications(bool enabled) async {
    final prefs = await getUserPreferences();
    final updated = prefs.copyWith(enableNotifications: enabled);
    await saveUserPreferences(updated);
  }

  Future<void> updateAutoConvert(bool enabled) async {
    final prefs = await getUserPreferences();
    final updated = prefs.copyWith(autoConvert: enabled);
    await saveUserPreferences(updated);
  }

  // ---- Legacy/Compatibility Methods (for existing ConversionController) ----
  /// Get base currency (for backward compatibility)
  Future<String> getBaseCurrency() async {
    final prefs = await getUserPreferences();
    return prefs.defaultBaseCurrency;
  }

  /// Set base currency (for ConversionController integration)
  Future<void> setBaseCurrency(String currency) async {
    await updateDefaultBaseCurrency(currency);
  }

  /// Get target currency
  Future<String> getTargetCurrency() async {
    final prefs = await getUserPreferences();
    return prefs.defaultTargetCurrency;
  }

  /// Set target currency (for ConversionController integration)
  Future<void> setTargetCurrency(String currency) async {
    await updateDefaultTargetCurrency(currency);
  }

  /// Check if dark mode is enabled
  Future<bool> isDarkModeEnabled() async {
    final prefs = await getUserPreferences();
    return prefs.isDarkMode;
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final prefs = await getUserPreferences();
    return prefs.enableNotifications;
  }

  /// Check if auto-convert is enabled
  Future<bool> isAutoConvertEnabled() async {
    final prefs = await getUserPreferences();
    return prefs.autoConvert;
  }

  /// Clear all preferences (reset to defaults)
  Future<void> resetPreferences() async {
    try {
      await _storage.deleteFeatureKey(_featureKey, _dataKey);
      if (kDebugMode) {
        debugPrint('[PreferencesService] All preferences cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PreferencesService] Error clearing preferences: $e');
      }
    }
  }

  /// Get all preferences as a map (for debugging/export)
  Future<Map<String, dynamic>> getAllPreferencesMap() async {
    final prefs = await getUserPreferences();
    return prefs.toMap();
  }
}
