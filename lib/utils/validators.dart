/// Validators - centralized form validation helpers
/// Used across onboarding, auth, preferences, etc.
class Validators {
  /// Validates an email address
  static String? validateEmail(String? value, {String fieldName = "Email"}) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required';
    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!regex.hasMatch(value)) return 'Enter a valid $fieldName';
    return null;
  }

  /// Validates a password (min 6 chars, customizable)
  static String? validatePassword(String? value, {String fieldName = "Password", int minLength = 6}) {
    if (value == null || value.isEmpty) return '$fieldName is required';
    if (value.length < minLength) return '$fieldName must be at least $minLength characters';
    return null;
  }

  /// Validates that a field is not empty, with optional trimming
  static String? validateNotEmpty(String? value, {String fieldName = "Field", bool trim = true}) {
    if (value == null || (trim && value.trim().isEmpty) || (!trim && value.isEmpty)) {
      return '$fieldName cannot be empty';
    }
    return null;
  }

  /// Validates names (firstName, lastName) with min/max length
  static String? validateName(String? value, {String fieldName = "Name", int min = 2, int max = 50}) {
    final emptyCheck = validateNotEmpty(value, fieldName: fieldName);
    if (emptyCheck != null) return emptyCheck;
    if (value!.length < min) return '$fieldName must be at least $min characters';
    if (value.length > max) return '$fieldName must be at most $max characters';
    final regex = RegExp(r'^[a-zA-Z\s-]+$'); // letters, spaces, hyphens
    if (!regex.hasMatch(value)) return '$fieldName contains invalid characters';
    return null;
  }

  /// Validates a phone number
  static String? validatePhone(String? value, {String fieldName = "Phone"}) {
    if (value == null || value.isEmpty) return '$fieldName is required';
    final regex = RegExp(r'^\+?[0-9]{7,15}$');
    if (!regex.hasMatch(value)) return 'Enter a valid $fieldName';
    return null;
  }

  /// Validates a URL
  static String? validateUrl(String? value, {String fieldName = "URL"}) {
    if (value == null || value.isEmpty) return '$fieldName is required';
    final regex = RegExp(r'^(https?:\/\/)?([\w-]+(\.[\w-]+)+)(\/[\w-]*)*\/?$');
    if (!regex.hasMatch(value)) return 'Enter a valid $fieldName';
    return null;
  }

  /// Validates min/max length
  static String? validateLength(String? value, {String fieldName = "Field", int? min, int? max}) {
    if (value == null || value.isEmpty) return '$fieldName is required';
    if (min != null && value.length < min) return '$fieldName must be at least $min characters';
    if (max != null && value.length > max) return '$fieldName must be at most $max characters';
    return null;
  }

  /// Validate against a custom regex
  static String? validatePattern(String? value, {required String pattern, String? errorMessage}) {
    if (value == null || value.isEmpty) return errorMessage ?? 'Invalid input';
    final regex = RegExp(pattern);
    if (!regex.hasMatch(value)) return errorMessage ?? 'Invalid input';
    return null;
  }
}
