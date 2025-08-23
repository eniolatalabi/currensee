import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/constants.dart';

/// IndicatorType defines which style to render
enum IndicatorType { dots, bar, numbers, shapes }

class AppIndicator extends StatelessWidget {
  final PageController controller;
  final int itemCount;
  final IndicatorType type;

  // Appearance configs
  final double dotSize;
  final double activeDotSize;
  final double barHeight;
  final List<IconData>? customShapes; // Optional: use icons instead of dots

  const AppIndicator({
    super.key,
    required this.controller,
    required this.itemCount,
    this.type = IndicatorType.dots,
    this.dotSize = 8.0,
    this.activeDotSize = 16.0,
    this.barHeight = 6.0,
    this.customShapes,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        // PageController.page gives fractional value
        final page = controller.hasClients
            ? (controller.page ?? controller.initialPage.toDouble())
            : 0.0;

        switch (type) {
          case IndicatorType.bar:
            return _buildBar(theme, page);
          case IndicatorType.numbers:
            return _buildNumbers(theme, isDark, page);
          case IndicatorType.shapes:
            return _buildShapes(theme, isDark, page);
          case IndicatorType.dots:
            return _buildDots(theme, isDark, page);
        }
      },
    );
  }

  Widget _buildDots(ThemeData theme, bool isDark, double page) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(itemCount, (index) {
        final selectedness =
            (1.0 - ((page - index).abs().clamp(0.0, 1.0))); // smooth transition
        final size = dotSize + (activeDotSize - dotSize) * selectedness;

        return GestureDetector(
          onTap: () => controller.animateToPage(
            index,
            duration: AppConstants.normalAnim,
            curve: Curves.easeInOut,
          ),
          child: AnimatedContainer(
            duration: AppConstants.fastAnim,
            margin: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingSmall,
            ),
            height: dotSize,
            width: size,
            decoration: BoxDecoration(
              color: selectedness > 0.5
                  ? AppTheme.primaryColor
                  : (isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary),
              borderRadius: BorderRadius.circular(AppConstants.radius),
            ),
          ),
        );
      }),
    );
  }

  /// --- BAR STYLE ---
  Widget _buildBar(ThemeData theme, double page) {
    final progress = ((page + 1) / itemCount).clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(
        AppConstants.radius,
      ), // fixed constant
      child: LinearProgressIndicator(
        value: progress,
        minHeight: barHeight,
        // Avoid newer-only fields; stay compatible and theme-aware
        backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.12),
        valueColor: const AlwaysStoppedAnimation(AppTheme.primaryColor),
      ),
    );
  }

  /// --- NUMBERS STYLE ---
  Widget _buildNumbers(ThemeData theme, bool isDark, double page) {
    final current = (page.round() + 1).clamp(1, itemCount);
    return AnimatedDefaultTextStyle(
      duration: AppConstants.normalAnim,
      curve: Curves.easeOut,
      style: theme.textTheme.bodyLarge!.copyWith(
        color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
        fontWeight: FontWeight.bold,
      ),
      child: Text("$current / $itemCount"),
    );
  }

  /// --- SHAPES / ICONS STYLE ---
  Widget _buildShapes(ThemeData theme, bool isDark, double page) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(itemCount, (index) {
        final selectedness =
            (1.0 - ((page - index).abs().clamp(0.0, 1.0))); // smooth scale
        final size = dotSize + (activeDotSize - dotSize) * selectedness;

        final color = selectedness > 0.5
            ? AppTheme.primaryColor
            : (isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary);

        return AnimatedContainer(
          duration: AppConstants.fastAnim, // fixed: shortAnim -> fastAnim
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingSmall,
          ),
          child: Icon(
            customShapes != null && index < customShapes!.length
                ? customShapes![index]
                : Icons.circle, // fallback to circle
            size: size,
            color: color,
          ),
        );
      }),
    );
  }
}
