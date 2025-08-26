// lib/utils/formatters.dart
import 'package:intl/intl.dart';

/// Centralized formatters for numbers and currencies.
/// Single source of truth to ensure consistent display across the app.
class Formatters {
  Formatters._(); // Prevent instantiation

  /// Formats a double as a currency string.
  /// Uses ISO currency code; can later support locale-specific symbols.
  static String formatCurrency(
    double value,
    String currencyCode, {
    String? locale,
    bool showSymbol = true,
    int decimals = 2,
  }) {
    try {
      final symbol = showSymbol ? _getCurrencySymbol(currencyCode) : '';
      final f = NumberFormat.currency(
        locale: locale,
        name: currencyCode,
        symbol: symbol,
        decimalDigits: decimals,
      );
      return f.format(value);
    } catch (_) {
      // Fallback in case of invalid code
      return '$currencyCode ${value.toStringAsFixed(decimals)}';
    }
  }

  /// Format a number with fixed decimal points
  static String formatNumber(double value, {int decimals = 2, String? locale}) {
    final f = NumberFormat.decimalPattern(locale)
      ..minimumFractionDigits = decimals
      ..maximumFractionDigits = decimals;
    return f.format(value);
  }

  /// Parse user input into a double, stripping symbols & spaces
  /// Locale-agnostic: keeps '.' as decimal
  static double? parseNumber(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^\d\.\-]'), '');
    return double.tryParse(cleaned);
  }

  /// ---- Internal helpers ----

  /// Map currency code -> symbol (extendable)
  static String _getCurrencySymbol(String code) {
    const symbols = {
      'USD': '\$',
      'NGN': '₦',
      'EUR': '€',
      'GBP': '£',
      'JPY': '¥',
      'CNY': '¥',
      'CAD': '\$',
      'AUD': '\$',
      'CHF': 'CHF',
      'ZAR': 'R',
      'GHS': '₵',
      'KES': 'Sh',
      'SEK': 'kr',
      'NOK': 'kr',
      'DKK': 'kr',
      'AED': 'د.إ',
      'SAR': '﷼',
      'INR': '₹',
    };
    return symbols[code] ?? code; // fallback to code itself
  }
}
