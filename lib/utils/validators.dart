import 'package:flutter/material.dart';

class Validators {
  static const String emailPattern =
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';

  /// Email validation (matches LoginScreen usage)
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    if (!RegExp(emailPattern).hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }

    return null;
  }

  /// Alternative email validation method (for consistency)
  static String? email(String? value) => validateEmail(value);

  /// Password validation (matches LoginScreen usage - basic for sign-in)
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }

    return null;
  }

  /// Alternative password validation method (for consistency)
  static String? password(String? value) => validatePassword(value);

  /// Name validation (first/last name)
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }

    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }

    if (value.trim().length > 50) {
      return 'Name must be less than 50 characters';
    }

    // Only allow letters, spaces, hyphens, and apostrophes
    if (!RegExp(r"^[a-zA-Z\s\-']+$").hasMatch(value.trim())) {
      return 'Name can only contain letters, spaces, hyphens, and apostrophes';
    }

    return null;
  }

  /// Alternative name validation method (for consistency)
  static String? name(String? value) => validateName(value);

  /// STRONG PASSWORD (for sign-up) - Industry Standard
  static String? validateStrongPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    // Length check
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }

    if (value.length > 128) {
      return 'Password must be less than 128 characters';
    }

    // Must contain uppercase letter
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }

    // Must contain lowercase letter
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter';
    }

    // Must contain number
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }

    // Must contain special character
    if (!RegExp(r'[!@#$%^&*()_+\-=\[\]{};:"\\|,.<>\/?~`]').hasMatch(value)) {
      return 'Password must contain at least one special character (!@#\$%^&*...)';
    }

    // Check for common weak patterns
    if (_isWeakPassword(value)) {
      return 'Password is too common. Please choose a stronger password';
    }

    return null;
  }

  /// Alternative strong password validation method (for consistency)
  static String? strongPassword(String? value) => validateStrongPassword(value);

  /// CONFIRM PASSWORD
  static String? validateConfirmPassword(
    String? value,
    String originalPassword,
  ) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != originalPassword) {
      return 'Passwords do not match';
    }

    return null;
  }

  /// Alternative confirm password validation method (for consistency)
  static String? confirmPassword(String? value, String originalPassword) =>
      validateConfirmPassword(value, originalPassword);

  /// Check for weak password patterns
  static bool _isWeakPassword(String password) {
    final weakPatterns = [
      'password',
      '12345678',
      'qwerty',
      'abc123',
      'password123',
      '123456789',
      'welcome',
      'admin',
      'letmein',
      'monkey',
      'dragon',
    ];

    final lowerPassword = password.toLowerCase();

    for (final pattern in weakPatterns) {
      if (lowerPassword.contains(pattern)) {
        return true;
      }
    }

    // Check for keyboard patterns
    if (RegExp(
      r'(123|234|345|456|567|678|789|890|qwe|wer|ert|rty|tyu|yui|uio|iop|asd|sdf|dfg|fgh|ghj|hjk|jkl|zxc|xcv|cvb|vbn|bnm)',
    ).hasMatch(lowerPassword)) {
      return true;
    }

    // Check for repeated characters (more than 3 in a row)
    if (RegExp(r'(.)\1{3,}').hasMatch(password)) {
      return true;
    }

    return false;
  }

  /// PASSWORD STRENGTH INDICATOR
  static PasswordStrength getPasswordStrength(String password) {
    if (password.isEmpty) return PasswordStrength.empty;

    int score = 0;

    // Length scoring
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (password.length >= 16) score++;

    // Character variety scoring
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#$%^&*()_+\-=\[\]{};:"\\|,.<>\/?~`]').hasMatch(password)) {
      score++;
    }

    // Penalty for weak patterns
    if (_isWeakPassword(password)) score -= 2;
    // Return strength based on score
    if (score >= 6) return PasswordStrength.strong;
    if (score >= 4) return PasswordStrength.medium;
    if (score >= 2) return PasswordStrength.weak;
    return PasswordStrength.veryWeak;
  }

  /// Phone number validation (optional utility)
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    // Remove all non-digit characters for validation
    final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');

    if (digitsOnly.length < 10) {
      return 'Phone number must be at least 10 digits';
    }

    if (digitsOnly.length > 15) {
      return 'Phone number must be less than 15 digits';
    }

    return null;
  }

  /// URL validation (optional utility)
  static String? validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return 'URL is required';
    }

    final urlPattern =
        r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$';

    if (!RegExp(urlPattern).hasMatch(value.trim())) {
      return 'Enter a valid URL';
    }

    return null;
  }

  /// Generic required field validation
  static String? validateRequired(String? value, [String fieldName = 'Field']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Minimum length validation
  static String? validateMinLength(
    String? value,
    int minLength, [
    String fieldName = 'Field',
  ]) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }

    if (value.length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }

    return null;
  }

  /// Maximum length validation
  static String? validateMaxLength(
    String? value,
    int maxLength, [
    String fieldName = 'Field',
  ]) {
    if (value != null && value.length > maxLength) {
      return '$fieldName must be less than $maxLength characters';
    }

    return null;
  }
}

/// Password strength levels
enum PasswordStrength {
  empty,
  veryWeak,
  weak,
  medium,
  strong;

  Color get color {
    switch (this) {
      case PasswordStrength.empty:
        return Colors.grey;
      case PasswordStrength.veryWeak:
        return Colors.red;
      case PasswordStrength.weak:
        return Colors.orange;
      case PasswordStrength.medium:
        return Colors.yellow;
      case PasswordStrength.strong:
        return Colors.green;
    }
  }

  String get label {
    switch (this) {
      case PasswordStrength.empty:
        return '';
      case PasswordStrength.veryWeak:
        return 'Very Weak';
      case PasswordStrength.weak:
        return 'Weak';
      case PasswordStrength.medium:
        return 'Medium';
      case PasswordStrength.strong:
        return 'Strong';
    }
  }

  double get progress {
    switch (this) {
      case PasswordStrength.empty:
        return 0.0;
      case PasswordStrength.veryWeak:
        return 0.2;
      case PasswordStrength.weak:
        return 0.4;
      case PasswordStrength.medium:
        return 0.6;
      case PasswordStrength.strong:
        return 1.0;
    }
  }
}
