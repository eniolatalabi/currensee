// lib/features/conversion/presentation/widgets/target_selector.dart
import 'package:flutter/material.dart';
import '../../../conversion/controller/conversion_controller.dart';
import '../../../../core/constants.dart';

class TargetCurrencySelector extends StatelessWidget {
  final ConversionController controller;
  final bool compact;

  const TargetCurrencySelector({
    super.key,
    required this.controller,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!compact) ...[
          Row(
            children: [
              Text(
                'To',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (controller.loading)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingSmall),
        ],
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppConstants.paddingMedium,
            vertical: compact ? 12 : AppConstants.paddingMedium,
          ),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(AppConstants.radius),
            border: Border.all(color: theme.dividerColor),
            boxShadow: AppConstants.boxShadow,
          ),
          child: Row(
            children: [
              Expanded(
                child: DropdownButton<String>(
                  value: controller.targetCurrency,
                  isExpanded: true,
                  underline: const SizedBox.shrink(),
                  icon: Icon(
                    Icons.keyboard_arrow_down,
                    color: theme.colorScheme.primary,
                  ),
                  style: compact
                      ? theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        )
                      : theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  dropdownColor: theme.cardColor,
                  menuMaxHeight: 300,
                  items: controller.supportedCurrencyNames.entries.map((entry) {
                    return DropdownMenuItem<String>(
                      value: entry.key,
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondary.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                entry.key.substring(0, 2),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.secondary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  entry.key,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (!compact)
                                  Text(
                                    entry.value,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.hintColor,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (code) {
                    if (code != null) {
                      controller.updateTargetCurrency(code);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
