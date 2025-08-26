// lib/features/conversion/controller/conversion_controller.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:currensee/data/services/currency_service.dart';
import 'package:currensee/utils/formatters.dart';
import '../../../core/config.dart';

class ConversionController extends ChangeNotifier {
  final CurrencyService _currencyService;

  ConversionController(this._currencyService);

  // ---- State ----
  String _baseCurrency = 'NGN';
  String _targetCurrency = 'USD';
  double _amount = 0.0;
  double? _conversionResult;
  String? _errorMessage;
  bool _loading = false;
  DateTime? _lastUpdated;
  Timer? _debounce;

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

  // ---- Actions ----
  void updateBaseCurrency(String code) {
    if (code == _baseCurrency) return;
    _baseCurrency = code;
    _clearError();
    _triggerAutoConvert();
    notifyListeners();
  }

  void updateTargetCurrency(String code) {
    if (code == _targetCurrency) return;
    _targetCurrency = code;
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
  }

  // ---- Internals ----
  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      // Don't call notifyListeners here to avoid infinite loops
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

    // Don't auto-convert if manual mode or zero amount
    if (isManualMode || _amount <= 0) {
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
        print(
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
          print(
            '[ConversionController] Conversion successful: $result $_targetCurrency',
          );
        }
      } else {
        _setError(
          'Unable to get exchange rate for $_baseCurrency to $_targetCurrency',
        );
        return;
      }
    } catch (e) {
      if (kDebugMode) {
        print('[ConversionController] Conversion error: $e');
      }
      _setError('Conversion failed: ${_getReadableError(e)}');
      return;
    }

    _loading = false;
    notifyListeners();
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
