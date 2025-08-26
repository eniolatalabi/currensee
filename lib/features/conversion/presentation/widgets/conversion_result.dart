// lib/features/conversion/presentation/widgets/conversion_result.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:currensee/utils/formatters.dart';
import '../../../../core/constants.dart';

class ConversionResult extends StatelessWidget {
  final double baseAmount;
  final double? convertedAmount;
  final String baseCurrency;
  final String targetCurrency;
  final DateTime? lastUpdated;
  final String? errorMessage;
  final bool compact;

  const ConversionResult({
    super.key,
    required this.baseAmount,
    required this.baseCurrency,
    required this.targetCurrency,
    this.convertedAmount,
    this.lastUpdated,
    this.errorMessage,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Don't show anything if no amount entered
    if (baseAmount <= 0 && errorMessage == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(
        compact ? AppConstants.paddingMedium : AppConstants.paddingLarge,
      ),
      decoration: BoxDecoration(
        color: errorMessage != null
            ? theme.colorScheme.errorContainer.withOpacity(0.1)
            : theme.colorScheme.primaryContainer.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.radius),
        border: Border.all(
          color: errorMessage != null
              ? theme.colorScheme.error.withOpacity(0.3)
              : theme.colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: errorMessage != null
          ? _buildErrorState(theme)
          : _buildResultState(theme),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Row(
      children: [
        Icon(
          Icons.error_outline,
          color: theme.colorScheme.error,
          size: compact ? 20 : 24,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              errorMessage!,
              style:
                  (compact
                          ? theme.textTheme.bodyMedium
                          : theme.textTheme.bodyLarge)
                      ?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w500,
                      ),
              maxLines: 1,
              overflow: TextOverflow.visible,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultState(ThemeData theme) {
    final formattedBase = Formatters.formatCurrency(baseAmount, baseCurrency);
    final formattedResult = convertedAmount != null
        ? Formatters.formatCurrency(convertedAmount!, targetCurrency)
        : '—';

    if (compact) {
      return IntrinsicHeight(
        child: Row(
          children: [
            // Base amount - flexible sizing
            Expanded(
              flex: 3,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  formattedBase,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                ),
              ),
            ),

            // Arrow - fixed size, centered
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(
                Icons.arrow_forward,
                size: 16,
                color: theme.colorScheme.primary,
              ),
            ),

            // Result amount - flexible sizing
            Expanded(
              flex: 3,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  formattedResult,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main conversion display
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Base amount - flexible
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          formattedBase,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.visible,
                        ),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          baseCurrency,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.hintColor,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.visible,
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow - fixed in center
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.arrow_forward,
                    color: theme.colorScheme.onPrimary,
                    size: 20,
                  ),
                ),

                // Target amount - flexible
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          formattedResult,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                          textAlign: TextAlign.end,
                          maxLines: 1,
                          overflow: TextOverflow.visible,
                        ),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          targetCurrency,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.hintColor,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.visible,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Exchange rate info - flexible
        if (convertedAmount != null && baseAmount > 0) ...[
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Exchange Rate',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                ),
              ),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    '1 $baseCurrency = ${Formatters.formatCurrency(convertedAmount! / baseAmount, targetCurrency)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                  ),
                ),
              ),
            ],
          ),
        ],

        // Last updated - flexible
        if (lastUpdated != null) ...[
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              'Updated ${_formatLastUpdated(lastUpdated!)}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.hintColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.visible,
            ),
          ),
        ],
      ],
    );
  }

  String _formatLastUpdated(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
