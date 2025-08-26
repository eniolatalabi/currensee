enum AppEnvironment { dev, staging, prod }

/// App-wide configuration for environments, APIs, and feature flags.
/// Follows industry standards: no hardcoded URLs/keys in services,
/// all environment-dependent configs are centralized here.

class AppConfig {
  /// Current environment
  static const AppEnvironment environment = AppEnvironment.dev;
  static const String? exchangeAccessKey = null;

  /// Base URLs by environment
  static const Map<AppEnvironment, String> _baseUrls = {
    AppEnvironment.dev: "https://api.exchangerate.host",
    AppEnvironment.staging: "https://api.exchangerate.host",
    AppEnvironment.prod: "https://api.exchangerate.host",
  };

  /// API versioning (if provider introduces v2, only update here)
  static const String apiVersion = "latest";

  /// Returns the correct base URL for the current environment
  static String get baseUrl => _baseUrls[environment]!;

  /// Full API endpoint for currency conversion
  static String get conversionEndpoint => "$baseUrl/$apiVersion";

  /// Feature flags (toggle without changing logic)
  static const bool enableManualConversion = true;
  static const bool enableLiveUpdates =
      true; // Websocket/streaming support future
  static const bool logApiRequests = true; // Debugging toggle
}
