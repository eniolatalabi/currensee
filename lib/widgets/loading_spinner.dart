import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Enum for standardized spinner sizes
enum SpinnerSize { small, medium, large }

/// Enum for theme-aware colors
enum SpinnerColor { primary, secondary, onBackground }

/// LoadingSpinner - reusable loader for buttons, API calls, forms, etc.
class LoadingSpinner extends StatelessWidget {
  final SpinnerSize spinnerSize;
  final SpinnerColor spinnerColor;

  /// Optional overrides
  final double? customSize;
  final Color? customColor;

  const LoadingSpinner({
    super.key,
    this.spinnerSize = SpinnerSize.medium,
    this.spinnerColor = SpinnerColor.primary,
    this.customSize,
    this.customColor,
  });

  /// Map enum -> actual size values
  double get _resolvedSize {
    switch (spinnerSize) {
      case SpinnerSize.small:
        return 20.0;
      case SpinnerSize.medium:
        return 32.0;
      case SpinnerSize.large:
        return 48.0;
    }
  }

  /// Map enum -> theme color
  Color _resolvedColor(BuildContext context) {
    final theme = Theme.of(context);
    switch (spinnerColor) {
      case SpinnerColor.primary:
        return AppTheme.primaryColor;
      case SpinnerColor.secondary:
        return AppTheme.secondaryColor;
      case SpinnerColor.onBackground:
        return theme.colorScheme.onSurface;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = customSize ?? _resolvedSize;
    final color = customColor ?? _resolvedColor(context);

    return SizedBox(
      height: size,
      width: size,
      child: CircularProgressIndicator(
        strokeWidth: (size / 10).clamp(2.0, 4.0), // auto scale stroke
        valueColor: AlwaysStoppedAnimation(color),
      ),
    );
  }
}
