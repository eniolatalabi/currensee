import 'package:flutter/material.dart';

class AppConstants {
  // App info
  static const String appName = "CurrenSee";

  // Firestore collections
  static const String usersCollection = "users";

  // Raw spacing values
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;

  // Pre-built spacing widgets
  static const spacingSmall = SizedBox(height: paddingSmall);
  static const spacingMedium = SizedBox(height: paddingMedium);
  static const spacingLarge = SizedBox(height: paddingLarge);

  static const hSpacingSmall = SizedBox(width: paddingSmall);
  static const hSpacingMedium = SizedBox(width: paddingMedium);
  static const hSpacingLarge = SizedBox(width: paddingLarge);

  // Border radius
  static const double radius = 12.0;

  // Animation durations
  static const Duration fastAnim = Duration(milliseconds: 200);
  static const Duration normalAnim = Duration(milliseconds: 400);

  // Shadows
  static List<BoxShadow> boxShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 6,
      offset: const Offset(0, 3),
    ),
  ];
}
