// lib/features/profile/presentation/widgets/faq_item.dart
import 'package:flutter/material.dart';
import '../../../../core/constants.dart';
import '../controller/faq_controller.dart';

class FAQItemWidget extends StatelessWidget {
  final FAQItem faqItem;
  final VoidCallback onTap;
  final int index;

  const FAQItemWidget({
    super.key,
    required this.faqItem,
    required this.onTap,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: AppConstants.paddingSmall),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radius),
        side: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppConstants.radius),
        child: Material(
          color: theme.colorScheme.surface,
          child: InkWell(
            onTap: onTap,
            child: AnimatedContainer(
              duration: AppConstants.fastAnim,
              curve: Curves.easeInOut,
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question Header
                  Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            'Q',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      AppConstants.hSpacingSmall,

                      Expanded(
                        child: Text(
                          faqItem.question,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),

                      AnimatedRotation(
                        turns: faqItem.isExpanded ? 0.5 : 0,
                        duration: AppConstants.fastAnim,
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),

                  // Answer (Expandable)
                  AnimatedCrossFade(
                    firstChild: const SizedBox.shrink(),
                    secondChild: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(
                        top: AppConstants.paddingMedium,
                      ),
                      padding: const EdgeInsets.only(left: 32),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondary.withOpacity(
                                0.1,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(
                              child: Text(
                                'A',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.secondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                          AppConstants.hSpacingSmall,

                          Expanded(
                            child: Text(
                              faqItem.answer,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.8,
                                ),
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    crossFadeState: faqItem.isExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: AppConstants.fastAnim,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
