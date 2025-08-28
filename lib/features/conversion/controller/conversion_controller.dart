// lib/features/conversion/controller/conversion_controller.dart - ENHANCED VERSION
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:currensee/data/services/currency_service.dart';
import 'package:currensee/data/services/notification_service.dart';
import 'package:currensee/utils/formatters.dart';
import '../../../core/config.dart';
import '../../../data/models/conversion_history_model.dart';
import '../../history/service/conversion_history_service.dart';
import '../../../data/services/preferences_service.dart';
import '../../../data/services/achievement_service.dart';

class ConversionController extends ChangeNotifier {
  final CurrencyService _currencyService;
  final ConversionHistoryService? _historyService;
  final PreferencesService _preferencesService = PreferencesService.instance;
  final NotificationServiceEnhanced _notificationService =
      NotificationServiceEnhanced.instance;

  ConversionController(this._currencyService, [this._historyService]) {
    _loadUserPreferences();
    if (kDebugMode) {
      debugPrint(
        '[ConversionController] Initialized with Firestore history service: ${_historyService != null}',
      );
    }
  }

  // ---- State ----
  String _baseCurrency = 'NGN';
  String _targetCurrency = 'USD';
  double _amount = 0.0;
  double? _conversionResult;
  String? _errorMessage;
  bool _loading = false;
  DateTime? _lastUpdated;
  Timer? _debounce;
  bool _autoConvertEnabled = true; // Track auto-convert preference locally

  // User ID for Firestore operations
  String? _currentUserId;

  // Callback for success notifications
  Function(String)? _onConversionSuccess;

  // ---- Getters for UI ----
  String get baseCurrency => _baseCurrency;
  String get targetCurrency => _targetCurrency;
  double get amount => _amount;
  double? get conversionResult => _conversionResult;
  String? get errorMessage => _errorMessage;
  bool get loading => _loading;
  DateTime? get lastUpdated => _lastUpdated;

  String get formattedAmount =>
      Formatters.formatCurrency(_amount, _baseCurrency);
  String get formattedResult => _conversionResult != null
      ? Formatters.formatCurrency(_conversionResult!, _targetCurrency)
      : '—';

  List<String> get supportedCodes => CurrencyService.supportedCodes;
  Map<String, String> get supportedCurrencyNames =>
      CurrencyService.supportedCurrencyNames;

  bool get isManualMode => AppConfig.enableManualConversion;

  // ---- User Management ----
  void setConversionSuccessCallback(Function(String)? callback) {
    _onConversionSuccess = callback;
  }

  /// Set current user ID for Firestore operations
  void setCurrentUserId(String? userId) {
    if (_currentUserId != userId) {
      _currentUserId = userId;
      if (kDebugMode) {
        debugPrint('[ConversionController] User ID set to: $userId');
      }
    }
  }

  // ---- Enhanced Actions with Notifications ----
  void updateBaseCurrency(String code) {
    if (code == _baseCurrency) return;

    final oldCurrency = _baseCurrency;
    _baseCurrency = code;
    _saveBaseCurrencyPreference(code);
    _clearError();
    _triggerAutoConvert();
    notifyListeners();

    // Create base currency change notification
    _createBaseCurrencyChangeNotification(oldCurrency, code);
  }

  void updateTargetCurrency(String code) {
    if (code == _targetCurrency) return;
    _targetCurrency = code;
    _saveTargetCurrencyPreference(code);
    _clearError();
    _triggerAutoConvert();
    notifyListeners();
  }

  void updateAmount(double newAmount) {
    if ((newAmount - _amount).abs() < 0.000001) {
      return; // Handle floating point precision
    }
    _amount = newAmount;
    _clearError();
    _triggerAutoConvert();
    notifyListeners();
  }

  void swapCurrencies() {
    final temp = _baseCurrency;
    _baseCurrency = _targetCurrency;
    _targetCurrency = temp;

    // Save both preferences after swap
    _saveBaseCurrencyPreference(_baseCurrency);
    _saveTargetCurrencyPreference(_targetCurrency);

    _clearError();
    _triggerAutoConvert();
    notifyListeners();
  }

  Future<void> manualConvert() async {
    if (_amount <= 0) {
      _setError('Please enter an amount greater than 0');
      return;
    }
    await _convert();

    // EDITED: Clear input after 10s and result after 20s
    if (_conversionResult != null && _errorMessage == null) {
      // Clear amount after 10 seconds
      Future.delayed(const Duration(seconds: 10), () {
        _amount = 0.0;
        notifyListeners();
      });
      // Clear result after 20 seconds
      Future.delayed(const Duration(seconds: 20), () {
        _conversionResult = null;
        notifyListeners();
      });
    }
  }

  // ---- Enhanced Profile Integration ----
  void updateBaseCurrencyFromProfile(String newBaseCurrency) {
    if (newBaseCurrency != _baseCurrency) {
      _baseCurrency = newBaseCurrency;
      _saveBaseCurrencyPreference(newBaseCurrency);
      _clearError();
      _triggerAutoConvert();
      notifyListeners();
    }
  }

  String getCurrentBaseCurrency() => _baseCurrency;

  // ---- Create base currency change notification ----
  Future<void> _createBaseCurrencyChangeNotification(
    String oldCurrency,
    String newCurrency,
  ) async {
    if (_currentUserId == null) {
      if (kDebugMode) {
        debugPrint(
          '[ConversionController] No user ID for base currency change notification',
        );
      }
      return;
    }

    try {
      await _notificationService.createBaseCurrencyChangeNotification(
        userId: _currentUserId!,
        oldCurrency: oldCurrency,
        newCurrency: newCurrency,
      );

      if (kDebugMode) {
        debugPrint(
          '[ConversionController] Created base currency change notification: $oldCurrency -> $newCurrency',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[ConversionController] Failed to create base currency notification: $e',
        );
      }
    }
  }

  // ---- User Preferences Management ----
  Future<void> _loadUserPreferences() async {
    try {
      final prefs = await _preferencesService.getUserPreferences();

      if (CurrencyService.supportedCodes.contains(prefs.defaultBaseCurrency)) {
        _baseCurrency = prefs.defaultBaseCurrency;
      }

      if (CurrencyService.supportedCodes.contains(
        prefs.defaultTargetCurrency,
      )) {
        _targetCurrency = prefs.defaultTargetCurrency;
      }

      _autoConvertEnabled = prefs.autoConvert;

      if (kDebugMode) {
        debugPrint(
          '[ConversionController] Loaded preferences: base=$_baseCurrency, target=$_targetCurrency, autoConvert=$_autoConvertEnabled',
        );
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ConversionController] Failed to load preferences: $e');
      }
    }
  }

  Future<void> updateAutoConvertSetting(bool enabled) async {
    if (_autoConvertEnabled != enabled) {
      _autoConvertEnabled = enabled;
      if (kDebugMode) {
        debugPrint(
          '[ConversionController] Auto-convert setting updated: $enabled',
        );
      }
      // Trigger conversion if enabled and amount > 0
      if (enabled && _amount > 0) {
        _triggerAutoConvert();
      }
      notifyListeners();
    }
  }

  Future<void> _saveBaseCurrencyPreference(String currency) async {
    try {
      await _preferencesService.updateDefaultBaseCurrency(currency);
      if (kDebugMode) {
        debugPrint(
          '[ConversionController] Base currency preference saved: $currency',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[ConversionController] Failed to save base currency preference: $e',
        );
      }
    }
  }

  Future<void> _saveTargetCurrencyPreference(String currency) async {
    try {
      await _preferencesService.updateDefaultTargetCurrency(currency);
      if (kDebugMode) {
        debugPrint(
          '[ConversionController] Target currency preference saved: $currency',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[ConversionController] Failed to save target currency preference: $e',
        );
      }
    }
  }

  // ---- Internal Logic (Enhanced) ----
  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
    }
  }

  void _setError(String error) {
    _errorMessage = error;
    _conversionResult = null;
    _loading = false;
    notifyListeners();
  }

  void _triggerAutoConvert() {
    _debounce?.cancel();

    if (isManualMode || !_autoConvertEnabled || _amount <= 0) {
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      await _convert();
    });
  }

  Future<void> _convert() async {
    if (_amount <= 0) return;

    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (kDebugMode) {
        debugPrint(
          '[ConversionController] Converting $_amount $_baseCurrency to $_targetCurrency',
        );
      }

      final result = await _currencyService.convert(
        base: _baseCurrency,
        target: _targetCurrency,
        amount: _amount,
      );

      if (result != null) {
        _conversionResult = result;
        _lastUpdated = DateTime.now();
        _errorMessage = null;

        if (kDebugMode) {
          debugPrint(
            '[ConversionController] Conversion successful: $result $_targetCurrency',
          );
        }

        // Save to Firestore and create notification
        await _saveToFirestoreHistory(result);

        // Trigger success callback for UI updates
        _onConversionSuccess?.call(
          'Your conversion of $formattedAmount to $formattedResult was successful!',
        );
      } else {
        _setError(
          'Unable to get exchange rate for $_baseCurrency to $_targetCurrency',
        );
        return;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ConversionController] Conversion error: $e');
      }
      _setError('Conversion failed: ${_getReadableError(e)}');
      return;
    }

    _loading = false;
    notifyListeners();
  }

  // ---- SINGLE Enhanced Firestore History Tracking with Achievements ----
  Future<void> _saveToFirestoreHistory(double result) async {
    if (_historyService == null || _currentUserId == null) {
      if (kDebugMode) {
        debugPrint(
          '[ConversionController] No history service or user ID available - userId: $_currentUserId',
        );
      }
      return;
    }

    try {
      final rate = result / _amount;

      final historyItem = ConversionHistory(
        userId: _currentUserId,
        baseCurrency: _baseCurrency,
        targetCurrency: _targetCurrency,
        baseAmount: _amount,
        convertedAmount: result,
        rate: rate,
        timestamp: DateTime.now(),
      );

      final savedId = await _historyService!.saveConversion(
        historyItem,
        _currentUserId!,
      );

      if (kDebugMode) {
        debugPrint(
          '[ConversionController] Saved to Firestore with ID $savedId',
        );
      }

      // Check achievements after successful conversion
      await _checkAchievements();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ConversionController] Failed to save to Firestore: $e');
      }
    }
  }

  /// Check achievements after conversion
  Future<void> _checkAchievements() async {
    if (_currentUserId == null || _historyService == null) return;

    try {
      final AchievementService achievementService = AchievementService.instance;
      await achievementService.checkAchievements(
        _currentUserId!,
        _historyService!,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ConversionController] Error checking achievements: $e');
      }
      // Don't show error to user for achievement failures
    }
  }

  String _getReadableError(dynamic error) {
    final errorStr = error.toString();

    if (errorStr.contains('SocketException') ||
        errorStr.contains('TimeoutException')) {
      return 'Please check your internet connection';
    } else if (errorStr.contains('HTTP 429')) {
      return 'Rate limit exceeded. Please try again later';
    } else if (errorStr.contains('HTTP 401')) {
      return 'API authentication failed';
    } else if (errorStr.contains('HTTP')) {
      return 'Server error. Please try again later';
    } else {
      return 'Unexpected error occurred';
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
