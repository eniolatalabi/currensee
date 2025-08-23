import 'package:flutter/material.dart';
import '../../../../widgets/custom_textfield.dart';

/// AuthTextField - specialized for authentication forms
/// Adds auth-specific defaults and validation while using CustomTextField internally
class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool isPassword;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final bool isLoading;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    // Auth-specific defaults: for example, email keyboard if hintText contains "email"
    TextInputType effectiveKeyboardType = keyboardType;
    if (hintText.toLowerCase().contains("email")) {
      effectiveKeyboardType = TextInputType.emailAddress;
    }

    return CustomTextField(
      controller: controller,
      hintText: hintText,
      keyboardType: effectiveKeyboardType,
      isPassword: isPassword,
      validator: validator,
      isLoading: isLoading,
    );
  }
}
