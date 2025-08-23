import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand colors
  static const Color primaryColor = Color(0xFF007BFF);
  static const Color successColor = Color(0xFF28A745);
  static const Color errorColor = Color(0xFFDC3545);
  static const Color warningColor = Color(0xFFFFC107);

  // Light mode colors
  static const Color lightBackground = Colors.white;
  static const Color lightTextPrimary = Colors.black87;
  static const Color lightTextSecondary = Colors.black54;
  static const Color lightInputBackground = Color(0xFFF5F5F5);

  // Dark mode colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkTextPrimary = Colors.white;
  static const Color darkTextSecondary = Colors.white70;
  static const Color darkInputBackground = Color(0xFF1E1E1E);

  // Base text theme
  static TextTheme _baseTextTheme(Color textColor) {
    return GoogleFonts.interTextTheme(
      TextTheme(
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textColor,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textColor,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
        labelSmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: textColor,
        ),
      ),
    );
  }

  /// ===== Light Theme =====
static final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  colorScheme: const ColorScheme.light(
    primary: primaryColor,
    secondary: primaryColor,
    surface: lightBackground,
    error: errorColor,
  ),
  scaffoldBackgroundColor: lightBackground,
  textTheme: _baseTextTheme(lightTextPrimary),

    // Elevated Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      ),
    ),

    // Outlined Buttons
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      ),
    ),

    // Text Buttons
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      ),
    ),

    // Input fields
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: lightInputBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      hintStyle: TextStyle(color: lightTextSecondary),
    ),

    // Snackbars
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: primaryColor,
      contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
    ),

    // Switches
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) => primaryColor),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => primaryColor.withValues(alpha: 0.4),
      ),
    ),

    // Checkbox
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) => primaryColor),
      checkColor: WidgetStateProperty.resolveWith((states) => Colors.white),
    ),

    // Radio
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) => primaryColor),
    ),

    // Dialog
    dialogTheme: DialogThemeData(
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      titleTextStyle: _baseTextTheme(lightTextPrimary).headlineMedium,
      contentTextStyle: _baseTextTheme(lightTextSecondary).bodyMedium,
    ),

    // Progress indicators
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: primaryColor,
    ),
  );

  /// ===== Dark Theme =====
static final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary: primaryColor,
    secondary: primaryColor,
    surface: darkBackground,
    error: errorColor,
  ),
  scaffoldBackgroundColor: darkBackground,
  textTheme: _baseTextTheme(darkTextPrimary),

    // Elevated Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      ),
    ),

    // Outlined Buttons
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      ),
    ),

    // Text Buttons
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      ),
    ),

    // Input fields
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkInputBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      hintStyle: TextStyle(color: darkTextSecondary),
    ),

    // Snackbars
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: primaryColor,
      contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
    ),

    // Switches
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) => primaryColor),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => primaryColor.withValues(alpha: 0.4),
      ),
    ),

    // Checkbox
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) => primaryColor),
      checkColor: WidgetStateProperty.resolveWith((states) => Colors.white),
    ),

    // Radio
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) => primaryColor),
    ),

    // Dialog
    dialogTheme: DialogThemeData(
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      titleTextStyle: _baseTextTheme(darkTextPrimary).headlineMedium,
      contentTextStyle: _baseTextTheme(darkTextSecondary).bodyMedium,
    ),

    // Progress indicators
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: primaryColor,
    ),
  );

  /// ===== Text Logo =====
  static const String appName = "CurrenSee";

  static Widget logo({
    double fontSize = 36,
    Color? color,
    FontWeight fontWeight = FontWeight.bold,
  }) {
    return Text(
      appName,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color ?? primaryColor,
        letterSpacing: 1.2,
      ),
    );
  }

  /// Optional motto
  static const String appMotto = "Track. Convert. Stay Ahead.";

  static Widget motto({
    double fontSize = 14,
    Color? color,
    FontWeight fontWeight = FontWeight.w400,
  }) {
    return Text(
      appMotto,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color ?? primaryColor.withValues(alpha: 0.5),
      ),
      textAlign: TextAlign.center,
    );
  }
}
