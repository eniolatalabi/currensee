import 'package:flutter/material.dart';
import '../../../../utils/validators.dart';
import '../../../../core/theme.dart';

/// Professional password strength indicator with compact design
/// Shows strength bar + compact requirements on focus
class PasswordStrengthIndicator extends StatelessWidget {
  final String password;
  final bool showRequirements;
  final bool isCompact; // New: for even more minimal display

  const PasswordStrengthIndicator({
    super.key,
    required this.password,
    this.showRequirements = true,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final strength = Validators.getPasswordStrength(password);

    // Don't show anything if password is empty
    if (password.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.outline.withValues(alpha: 0.15), 
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Strength Bar with Label (always visible)
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Password strength: ${strength.label}',
                      style: TextStyle(
                        color: strength.color,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: strength.progress,
                      backgroundColor: Colors.grey.withValues(alpha: 0.15), // 
                      valueColor: AlwaysStoppedAnimation(strength.color),
                      minHeight: 3,
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ],
                ),
              ),
              if (!isCompact) ...[
                const SizedBox(width: 12),
                _buildStrengthIcon(strength),
              ],
            ],
          ),

          // Compact Requirements (only show if not strong and showRequirements is true)
          if (showRequirements &&
              strength != PasswordStrength.strong &&
              !isCompact) ...[
            const SizedBox(height: 8),
            _buildCompactRequirements(context, password), 
          ],
        ],
      ),
    );
  }

  Widget _buildStrengthIcon(PasswordStrength strength) {
    IconData icon;
    switch (strength) {
      case PasswordStrength.weak:
        icon = Icons.warning_rounded;
        break;
      case PasswordStrength.medium:
        icon = Icons.info_rounded;
        break;
      case PasswordStrength.strong:
        icon = Icons.check_circle_rounded;
        break;
      default:
        icon = Icons.remove_circle_rounded;
    }

    return Icon(icon, size: 16, color: strength.color);
  }

  Widget _buildCompactRequirements(BuildContext context, String password) {
    final requirements = _getRequirements(password);
    final metCount = requirements.where((req) => req.isValid).length;
    final totalCount = requirements.length;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest 
            .withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          // Progress summary
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Requirements met:',
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$metCount/$totalCount',
                style: TextStyle(
                  fontSize: 10,
                  color: metCount == totalCount
                      ? AppTheme.successColor
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Compact requirement dots
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: requirements
                .map((req) => _buildRequirementDot(req))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementDot(RequirementData req) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: req.isValid
            ? AppTheme.successColor.withValues(alpha: 0.1) // 
            : Colors.grey.withValues(alpha: 0.1), // 
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: req.isValid
              ? AppTheme.successColor.withValues(alpha: 0.3) // 
              : Colors.grey.withValues(alpha: 0.2), // 
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            req.isValid ? Icons.check : Icons.close,
            size: 10,
            color: req.isValid ? AppTheme.successColor : Colors.grey.shade600,
          ),
          const SizedBox(width: 3),
          Text(
            req.shortText,
            style: TextStyle(
              fontSize: 9,
              color: req.isValid ? AppTheme.successColor : Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  List<RequirementData> _getRequirements(String password) {
    return [
      RequirementData(
        text: 'At least 8 characters',
        shortText: '8+ chars',
        isValid: password.length >= 8,
      ),
      RequirementData(
        text: 'Contains uppercase letter',
        shortText: 'A-Z',
        isValid: RegExp(r'[A-Z]').hasMatch(password),
      ),
      RequirementData(
        text: 'Contains lowercase letter',
        shortText: 'a-z',
        isValid: RegExp(r'[a-z]').hasMatch(password),
      ),
      RequirementData(
        text: 'Contains number',
        shortText: '0-9',
        isValid: RegExp(r'[0-9]').hasMatch(password),
      ),
      RequirementData(
        text: 'Contains special character',
        shortText: '!@#',
        isValid: RegExp(
          r'[!@#$%^&*()_+\-=\[\]{};:"\\|,.<>\/?~`]',
        ).hasMatch(password),
      ),
    ];
  }
}

class RequirementData {
  final String text;
  final String shortText;
  final bool isValid;

  RequirementData({
    required this.text,
    required this.shortText,
    required this.isValid,
  });
}

/// Alternative: Ultra-minimal inline indicator for tight spaces
class InlinePasswordStrength extends StatelessWidget {
  final String password;

  const InlinePasswordStrength({super.key, required this.password});

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();

    final strength = Validators.getPasswordStrength(password);

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Expanded(
            child: LinearProgressIndicator(
              value: strength.progress,
              backgroundColor: Colors.grey.withValues(alpha: 0.2), // ✅
              valueColor: AlwaysStoppedAnimation(strength.color),
              minHeight: 2,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            strength.label,
            style: TextStyle(
              color: strength.color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
