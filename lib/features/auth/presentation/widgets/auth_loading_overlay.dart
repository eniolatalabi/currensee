import 'package:flutter/material.dart';
import '../../../../widgets/loading_spinner.dart';

/// AuthLoadingOverlay - overlay spinner for authentication screens
/// Provides a semi-transparent background and theme-aware spinner
class AuthLoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;

  const AuthLoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child, // Main content
        if (isLoading)
          // Full screen semi-transparent overlay
          Container(
            color: Colors.black.withValues(
              alpha: 0.3,
            ), // withValues(alpha:) equivalent
            child: const Center(
              child: LoadingSpinner(), // uses theme color by default
            ),
          ),
      ],
    );
  }
}
