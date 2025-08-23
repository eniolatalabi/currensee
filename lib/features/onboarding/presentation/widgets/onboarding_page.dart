import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../../../core/constants.dart';

/// OnboardingPage - reusable widget for each onboarding step
class OnboardingPage extends StatelessWidget {
  final String title;
  final String description;
  final String? lottieAsset;
  final IconData fallbackIcon;

  const OnboardingPage({
    super.key,
    required this.title,
    required this.description,
    required this.fallbackIcon,
    this.lottieAsset,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animation or fallback (standardized size)
          Expanded(
            flex: 3,
            child: Center(
              child: SizedBox(
                width: 220,
                height: 220,
                child: lottieAsset == null
                    ? Icon(
                        fallbackIcon,
                        size: 120,
                        color: theme.colorScheme.primary,
                      )
                    : Lottie.asset(
                        lottieAsset!,
                        fit: BoxFit.contain,
                        // Recolor to match theme primary
                        delegates: LottieDelegates(
                          values: [
                            ValueDelegate.color(const [
                              '**',
                            ], value: theme.colorScheme.primary),
                          ],
                        ),
                        // Fallback if asset missing
                        errorBuilder: (_, __, ___) => Icon(
                          fallbackIcon,
                          size: 120,
                          color: theme.colorScheme.primary,
                        ),
                      ),
              ),
            ),
          ),

          // spacing
          AppConstants.spacingLarge,

          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),

          // spacing
          AppConstants.spacingMedium,

          Expanded(
            flex: 2,
            child: Text(
              description,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                // replace deprecated withOpacity
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
