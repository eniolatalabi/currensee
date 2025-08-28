// lib/core/config.dart
enum AppEnvironment { dev, staging, prod }

/// App-wide configuration for environments, APIs, and feature flags.
class AppConfig {
  /// Current environment
  static const AppEnvironment environment = AppEnvironment.dev;

  /// NEWS API CONFIGURATION (NewsAPI.org)
  static const String newsApiKey = '6705b6bd7c3f454fbb8916918b0158a4';

  /// API FEATURE TOGGLES - Using real APIs directly
  static const bool useRealNewsApi = true;
  static const bool useRealMarketApi = true;

  /// Exchange rate API (keep existing)
  static const String? exchangeAccessKey = null;

  /// Base URLs by environment
  static const Map<AppEnvironment, String> _baseUrls = {
    AppEnvironment.dev: "https://api.exchangerate.host",
    AppEnvironment.staging: "https://api.exchangerate.host",
    AppEnvironment.prod: "https://api.exchangerate.host",
  };

  /// NEWS API BASE URL
  static const String newsApiBaseUrl = 'https://newsapi.org/v2/everything';

  /// MARKET DATA API BASE URL
  static const String marketApiBaseUrl =
      'https://api.exchangerate-api.com/v4/latest';

  /// API versioning
  static const String apiVersion = "latest";

  /// Returns the correct base URL for the current environment
  static String get baseUrl => _baseUrls[environment]!;

  /// Full API endpoint for currency conversion
  static String get conversionEndpoint => "$baseUrl/$apiVersion";

  /// Feature flags
  static const bool enableManualConversion = true;
  static const bool enableLiveUpdates = true;
  static const bool logApiRequests = true; // Enable detailed logging

  /// News feature flags
  static const bool enableNewsSearch = true;
  static const bool enableMarketCharts = true;
  static const bool enableNewsPushNotifications = false;

  /// API RATE LIMITING
  static const int newsApiDailyLimit = 1000; // NewsAPI free tier
  static const int marketApiMonthlyLimit = 1500; // ExchangeRate-API free tier
}
