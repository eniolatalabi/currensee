// lib/features/profile/presentation/widgets/preference_item.dart
import 'package:flutter/material.dart';
import '../../../../core/constants.dart';

class PreferenceItem extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isEnabled;

  const PreferenceItem({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    this.trailing,
    this.onTap,
    this.isEnabled = true,
  });

  /// Switch preference item factory constructor
  factory PreferenceItem.switchType({
    Key? key,
    required String title,
    String? subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool isEnabled = true,
  }) {
    return PreferenceItem(
      key: key,
      title: title,
      subtitle: subtitle,
      icon: icon,
      trailing: Switch(value: value, onChanged: isEnabled ? onChanged : null),
      isEnabled: isEnabled,
    );
  }

  /// Dropdown preference item factory constructor
  factory PreferenceItem.dropdown({
    Key? key,
    required String title,
    String? subtitle,
    required IconData icon,
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
    bool isEnabled = true,
  }) {
    return PreferenceItem(
      key: key,
      title: title,
      subtitle: subtitle,
      icon: icon,
      trailing: DropdownButton<String>(
        value: value,
        items: options.map((String option) {
          return DropdownMenuItem<String>(value: option, child: Text(option));
        }).toList(),
        onChanged: isEnabled ? onChanged : null,
        underline: const SizedBox.shrink(),
      ),
      isEnabled: isEnabled,
    );
  }

  /// Navigation preference item (shows arrow)
  const PreferenceItem.navigation({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.onTap,
    this.isEnabled = true,
  }) : trailing = const Icon(Icons.chevron_right);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppConstants.radius),
        child: Container(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Row(
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: isEnabled
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  size: 20,
                ),
              ),

              AppConstants.hSpacingMedium,

              // Title & Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: isEnabled
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurface.withValues(
                                alpha: 0.4,
                              ),
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isEnabled
                              ? theme.colorScheme.onSurface.withValues(
                                  alpha: 0.7,
                                )
                              : theme.colorScheme.onSurface.withValues(
                                  alpha: 0.4,
                                ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              AppConstants.hSpacingSmall,

              // Trailing widget
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}
