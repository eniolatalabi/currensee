// lib/features/profile/controller/preferences_controller.dart
import 'package:flutter/foundation.dart';
import '../../../data/models/user_preferences_model.dart';
import '../../../data/services/preferences_service.dart';
import '../../../data/services/notification_service.dart';

class PreferencesController extends ChangeNotifier {
  final PreferencesService _preferencesService;
  final NotificationServiceEnhanced _notificationService =
      NotificationServiceEnhanced.instance;

  UserPreferences _preferences = UserPreferences();
  bool _isLoading = false;
  String? _errorMessage;
  String? _currentUserId;

  // ISSUE 2 FIX: Add callback for auto-convert changes
  Function(bool)? _onAutoConvertChanged;

  PreferencesController(this._preferencesService);

  UserPreferences get preferences => _preferences;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Set current user ID for notifications
  void setCurrentUserId(String? userId) {
    _currentUserId = userId;
  }

  /// ISSUE 2 FIX: Set callback for auto-convert changes
  void setAutoConvertCallback(Function(bool)? callback) {
    _onAutoConvertChanged = callback;
  }

  /// Load preferences on initialization
  Future<void> loadPreferences() async {
    _setLoading(true);
    _clearError();

    try {
      _preferences = await _preferencesService.getUserPreferences();
      if (kDebugMode) {
        debugPrint(
          '[PreferencesController] Preferences loaded: ${_preferences.toMap()}',
        );
      }

      // Notify conversion controller about auto-convert setting
      _onAutoConvertChanged?.call(_preferences.autoConvert);

      notifyListeners();
    } catch (e) {
      _setError('Failed to load preferences: $e');
      if (kDebugMode) {
        debugPrint('[PreferencesController] Error loading preferences: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  /// Update default base currency with notification
  Future<bool> updateDefaultBaseCurrency(String currency) async {
    if (currency == _preferences.defaultBaseCurrency) return true;

    final oldCurrency = _preferences.defaultBaseCurrency;
    _clearError();

    try {
      await _preferencesService.updateDefaultBaseCurrency(currency);
      _preferences = _preferences.copyWith(defaultBaseCurrency: currency);
      notifyListeners();

      // Create notification for base currency change
      if (_currentUserId != null) {
        await _notificationService.createBaseCurrencyChangeNotification(
          userId: _currentUserId!,
          oldCurrency: oldCurrency,
          newCurrency: currency,
        );
      }

      if (kDebugMode) {
        debugPrint(
          '[PreferencesController] Base currency updated: $oldCurrency -> $currency',
        );
      }

      return true;
    } catch (e) {
      _setError('Failed to update base currency');
      if (kDebugMode) {
        debugPrint('[PreferencesController] Error updating base currency: $e');
      }
      return false;
    }
  }

  /// Update default target currency
  Future<bool> updateDefaultTargetCurrency(String currency) async {
    if (currency == _preferences.defaultTargetCurrency) return true;

    _clearError();

    try {
      await _preferencesService.updateDefaultTargetCurrency(currency);
      _preferences = _preferences.copyWith(defaultTargetCurrency: currency);
      notifyListeners();

      if (kDebugMode) {
        debugPrint(
          '[PreferencesController] Default target currency updated to: $currency',
        );
      }

      return true;
    } catch (e) {
      _setError('Failed to update target currency');
      if (kDebugMode) {
        debugPrint(
          '[PreferencesController] Error updating target currency: $e',
        );
      }
      return false;
    }
  }

  /// Update theme mode
  Future<bool> updateThemeMode(bool isDarkMode) async {
    if (isDarkMode == _preferences.isDarkMode) return true;

    _clearError();

    try {
      await _preferencesService.updateThemeMode(isDarkMode);
      _preferences = _preferences.copyWith(isDarkMode: isDarkMode);
      notifyListeners();

      if (kDebugMode) {
        debugPrint(
          '[PreferencesController] Theme mode updated to: ${isDarkMode ? 'dark' : 'light'}',
        );
      }

      return true;
    } catch (e) {
      _setError('Failed to update theme');
      if (kDebugMode) {
        debugPrint('[PreferencesController] Error updating theme: $e');
      }
      return false;
    }
  }

  /// Update notifications setting
  Future<bool> updateNotifications(bool enabled) async {
    if (enabled == _preferences.enableNotifications) return true;

    _clearError();

    try {
      await _preferencesService.updateNotifications(enabled);
      _preferences = _preferences.copyWith(enableNotifications: enabled);

      // Also update notification service setting
      await _notificationService.setNotificationsEnabled(enabled);

      notifyListeners();

      if (kDebugMode) {
        debugPrint(
          '[PreferencesController] Notifications updated to: $enabled',
        );
      }

      return true;
    } catch (e) {
      _setError('Failed to update notifications');
      if (kDebugMode) {
        debugPrint('[PreferencesController] Error updating notifications: $e');
      }
      return false;
    }
  }

  /// ISSUE 2 FIX: Update auto-convert setting with callback to ConversionController
  Future<bool> updateAutoConvert(bool enabled) async {
    if (enabled == _preferences.autoConvert) return true;

    _clearError();

    try {
      await _preferencesService.updateAutoConvert(enabled);
      _preferences = _preferences.copyWith(autoConvert: enabled);

      // Notify conversion controller about the change
      _onAutoConvertChanged?.call(enabled);

      notifyListeners();

      if (kDebugMode) {
        debugPrint('[PreferencesController] Auto-convert updated to: $enabled');
      }

      return true;
    } catch (e) {
      _setError('Failed to update auto-convert');
      if (kDebugMode) {
        debugPrint('[PreferencesController] Error updating auto-convert: $e');
      }
      return false;
    }
  }

  /// Reset all preferences to defaults
  Future<bool> resetPreferences() async {
    _setLoading(true);
    _clearError();

    try {
      await _preferencesService.resetPreferences();
      _preferences = UserPreferences(); // Reset to defaults

      // Notify conversion controller about reset auto-convert setting
      _onAutoConvertChanged?.call(_preferences.autoConvert);

      notifyListeners();

      if (kDebugMode) {
        debugPrint('[PreferencesController] Preferences reset to defaults');
      }

      return true;
    } catch (e) {
      _setError('Failed to reset preferences');
      if (kDebugMode) {
        debugPrint('[PreferencesController] Error resetting preferences: $e');
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Helper methods
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      // Don't notify here to prevent unnecessary rebuilds
    }
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }
}
