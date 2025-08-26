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
  final bool isLoading; // disables field during loading
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.isLoading = false,
    this.focusNode,
    this.textInputAction,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    // Auth-specific defaults: email keyboard if hintText contains "email"
    final effectiveKeyboardType =
        hintText.toLowerCase().contains("email") ? TextInputType.emailAddress : keyboardType;

    return CustomTextField(
      controller: controller,
      hintText: hintText,
      keyboardType: effectiveKeyboardType,
      isPassword: isPassword,
      validator: validator,
      focusNode: focusNode,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      enabled: !isLoading, 
    );
  }
}
