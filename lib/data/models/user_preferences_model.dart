// lib/data/models/user_preferences_model.dart
import 'dart:convert';

class UserPreferences {
  final String defaultBaseCurrency;
  final String defaultTargetCurrency;
  final bool isDarkMode;
  final bool enableNotifications;
  final bool autoConvert;
  final DateTime lastUpdated;

  UserPreferences({
    this.defaultBaseCurrency = 'NGN',
    this.defaultTargetCurrency = 'USD',
    this.isDarkMode = false,
    this.enableNotifications = true,
    this.autoConvert = true,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  UserPreferences copyWith({
    String? defaultBaseCurrency,
    String? defaultTargetCurrency,
    bool? isDarkMode,
    bool? enableNotifications,
    bool? autoConvert,
    DateTime? lastUpdated,
  }) {
    return UserPreferences(
      defaultBaseCurrency: defaultBaseCurrency ?? this.defaultBaseCurrency,
      defaultTargetCurrency:
          defaultTargetCurrency ?? this.defaultTargetCurrency,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      autoConvert: autoConvert ?? this.autoConvert,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'defaultBaseCurrency': defaultBaseCurrency,
      'defaultTargetCurrency': defaultTargetCurrency,
      'isDarkMode': isDarkMode,
      'enableNotifications': enableNotifications,
      'autoConvert': autoConvert,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory UserPreferences.fromMap(Map<String, dynamic> map) {
    return UserPreferences(
      defaultBaseCurrency: map['defaultBaseCurrency'] ?? 'NGN',
      defaultTargetCurrency: map['defaultTargetCurrency'] ?? 'USD',
      isDarkMode: map['isDarkMode'] ?? false,
      enableNotifications: map['enableNotifications'] ?? true,
      autoConvert: map['autoConvert'] ?? true,
      lastUpdated:
          DateTime.tryParse(map['lastUpdated'] ?? '') ?? DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());
  factory UserPreferences.fromJson(String source) =>
      UserPreferences.fromMap(json.decode(source));
}
