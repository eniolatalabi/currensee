// lib/data/services/currency_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/config.dart';

class CurrencyService {
  CurrencyService._();
  static final CurrencyService instance = CurrencyService._();

  // Expose what you need; keeping placeholders here
  static const List<String> supportedCodes = [
    'USD',
    'NGN',
    'EUR',
    'GBP',
    'JPY',
    'CAD',
    'AUD',
    'CHF',
    'CNY',
    'ZAR',
    'GHS',
    'KES',
    'INR',
    'AED',
    'SAR',
    'SEK',
    'NOK',
    'DKK',
  ];

  static const Map<String, String> supportedCurrencyNames = {
    'USD': 'US Dollar',
    'NGN': 'Nigerian Naira',
    'EUR': 'Euro',
    'GBP': 'British Pound',
    'JPY': 'Japanese Yen',
    'CAD': 'Canadian Dollar',
    'AUD': 'Australian Dollar',
    'CHF': 'Swiss Franc',
    'CNY': 'Chinese Yuan',
    'ZAR': 'South African Rand',
    'GHS': 'Ghanaian Cedi',
    'KES': 'Kenyan Shilling',
    'INR': 'Indian Rupee',
    'AED': 'UAE Dirham',
    'SAR': 'Saudi Riyal',
    'SEK': 'Swedish Krona',
    'NOK': 'Norwegian Krone',
    'DKK': 'Danish Krone',
  };

  Future<double?> convert({
    required String base,
    required String target,
    required double amount,
  }) async {
    final rate = await getRate(base: base, target: target);
    return rate == null ? null : amount * rate;
  }

  Future<double?> getRate({
    required String base,
    required String target,
  }) async {
    final rates = await _getRates(base);
    return rates?[target];
  }

  Future<Map<String, double>?> _getRates(String base) async {
    final providers = _providers(base);

    dynamic lastError;
    for (final fetch in providers) {
      try {
        final rates = await fetch();
        if (rates != null && rates.isNotEmpty) return rates;
      } catch (e) {
        lastError = e;
        if (kDebugMode) {
          debugPrint('[CurrencyService] Provider failed: $e');
        }
      }
    }
    if (kDebugMode && lastError != null) {
      debugPrint('[CurrencyService] All providers failed: $lastError');
    }
    return null;
  }

  List<Future<Map<String, double>?> Function()> _providers(String base) {
    final List<Future<Map<String, double>?> Function()> fns = [];

    // 1) exchangerate.host (only if key is provided)
    final key = AppConfig.exchangeAccessKey;
    if (key != null && key.isNotEmpty) {
      final url = '${AppConfig.baseUrl}/latest?base=$base&access_key=$key';
      fns.add(() => _fetchRates(url, provider: 'exchangerate.host'));
    }

    // 2) ER-API (keyless, broad coverage inc. NGN)
    fns.add(
      () => _fetchRates(
        'https://open.er-api.com/v6/latest/$base',
        provider: 'er-api',
      ),
    );

    // 3) Frankfurter (keyless, majors via ECB)
    fns.add(
      () => _fetchRates(
        'https://api.frankfurter.app/latest?from=$base',
        provider: 'frankfurter',
      ),
    );

    return fns;
  }

  Future<Map<String, double>?> _fetchRates(
    String url, {
    required String provider,
  }) async {
    if (kDebugMode) debugPrint('[CurrencyService] GET $url');
    final resp = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 12));

    if (kDebugMode) {
      debugPrint('[CurrencyService] $provider status=${resp.statusCode}');
      debugPrint('[CurrencyService] $provider body=${resp.body}');
    }

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('HTTP ${resp.statusCode}');
    }

    final data = jsonDecode(resp.body);

    // Normalize different shapes -> Map<String,double>
    if (data is Map<String, dynamic>) {
      // exchangerate.host / apilayer-style
      if (data.containsKey('success')) {
        if (data['success'] == true && data['rates'] is Map) {
          return (data['rates'] as Map).map(
            (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
          );
        } else {
          final err = data['error'];
          // e.g., { type: missing_access_key, ... } -> try next provider
          throw Exception('API Error: $err');
        }
      }

      // ER-API
      if (data['result'] == 'success' && data['rates'] is Map) {
        return (data['rates'] as Map).map(
          (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
        );
      }

      // Frankfurter
      if (data.containsKey('rates') && data['rates'] is Map) {
        return (data['rates'] as Map).map(
          (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
        );
      }
    }

    throw Exception('Unrecognized $provider response');
  }
}
