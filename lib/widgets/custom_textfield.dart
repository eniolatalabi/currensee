import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/constants.dart';

/// CustomTextField - reusable styled text field
/// Supports password toggle, validation, loading, enabled/disabled, focus, and submit actions.
class CustomTextField extends StatefulWidget {
  final String hintText;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool isPassword;
  final String? Function(String?)? validator;
  final bool isLoading;

  // Add support for forwarding
  final bool? enabled;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;

  const CustomTextField({
    super.key,
    required this.hintText,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.isPassword = false,
    this.validator,
    this.isLoading = false,
    this.enabled,
    this.focusNode,
    this.textInputAction,
    this.onFieldSubmitted,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Stack(
      alignment: Alignment.centerRight,
      children: [
        TextFormField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          obscureText: widget.isPassword ? _obscure : false,
          validator: widget.validator,
          enabled: widget.enabled ?? !widget.isLoading,
          focusNode: widget.focusNode,
          textInputAction: widget.textInputAction,
          onFieldSubmitted: widget.onFieldSubmitted,
          decoration: InputDecoration(
            hintText: widget.hintText,
            filled: true,
            fillColor: isDark
                ? AppTheme.darkInputBackground
                : AppTheme.lightInputBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.radius),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: AppConstants.paddingMedium,
              horizontal: AppConstants.paddingMedium,
            ),
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_off : Icons.visibility,
                      color: AppTheme.primaryColor,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  )
                : null,
          ),
          style: theme.textTheme.bodyLarge,
        ),
        if (widget.isLoading)
          Padding(
            padding: const EdgeInsets.only(right: AppConstants.paddingMedium),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(AppTheme.primaryColor),
              ),
            ),
          ),
      ],
    );
  }
}
