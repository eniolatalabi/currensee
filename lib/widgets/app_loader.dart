import 'package:flutter/material.dart';
import '../core/constants.dart';
import 'loading_spinner.dart';

/// AppLoader
///
/// A full-screen loading overlay that:
/// - Blocks user interaction while active
/// - Uses our shared LoadingSpinner for visual consistency

class AppLoader extends StatelessWidget {
  /// Optional message to show below the spinner
  final String? message;

  /// Background opacity for the overlay (default = 0.4)
  final double overlayOpacity;

  const AppLoader({super.key, this.message, this.overlayOpacity = 0.4});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AbsorbPointer(
      absorbing: true, // Ensures no UI interaction passes through
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: theme.colorScheme.surface.withValues(alpha: 0.3),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LoadingSpinner(spinnerSize: SpinnerSize.large),
              if (message != null && message!.isNotEmpty) ...[
                const SizedBox(height: AppConstants.paddingMedium),
                Text(
                  message!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
