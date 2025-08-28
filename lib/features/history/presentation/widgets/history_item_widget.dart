// lib/features/history/presentation/widgets/enhanced_history_item_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../data/models/conversion_history_model.dart';
import '../../../../utils/formatters.dart';

class EnhancedHistoryItemWidget extends StatefulWidget {
  final ConversionHistory item;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const EnhancedHistoryItemWidget({
    super.key,
    required this.item,
    this.onTap,
    this.onDelete,
  });

  @override
  State<EnhancedHistoryItemWidget> createState() =>
      _EnhancedHistoryItemWidgetState();
}

class _EnhancedHistoryItemWidgetState extends State<EnhancedHistoryItemWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<double>(begin: 0.0, end: -100.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _animationController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: const EdgeInsets.only(bottom: 1),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.08),
              ),
              boxShadow: [
                BoxShadow(
                  color: _isPressed
                      ? theme.colorScheme.primary.withOpacity(0.1)
                      : Colors.black.withOpacity(0.02),
                  blurRadius: _isPressed ? 8 : 4,
                  offset: Offset(0, _isPressed ? 2 : 1),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  widget.onTap?.call();
                },
                onTapDown: _handleTapDown,
                onTapUp: _handleTapUp,
                onTapCancel: _handleTapCancel,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _buildCurrencyIcon(context),
                      const SizedBox(width: 16),
                      Expanded(child: _buildConversionDetails(context)),
                      _buildTrailingSection(context),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCurrencyIcon(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer.withOpacity(0.4),
            theme.colorScheme.secondaryContainer.withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.15)),
      ),
      child: Stack(
        children: [
          // Base currency symbol
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  _getCurrencySymbol(widget.item.baseCurrency),
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          ),

          // Arrow
          Positioned(
            top: 16,
            left: 16,
            child: Icon(
              Icons.trending_flat,
              size: 12,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),

          // Target currency symbol
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  _getCurrencySymbol(widget.item.targetCurrency),
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.secondary,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversionDetails(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Currency pair with compact styling
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                widget.item.baseCurrency,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                  fontSize: 10,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.arrow_forward,
              size: 12,
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                widget.item.targetCurrency,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.secondary,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Amount conversion with improved formatting
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: Formatters.formatCurrency(
                  widget.item.baseAmount,
                  widget.item.baseCurrency,
                ),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              TextSpan(
                text: ' = ',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              TextSpan(
                text: Formatters.formatCurrency(
                  widget.item.convertedAmount,
                  widget.item.targetCurrency,
                ),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.secondary,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 4),

        // Rate with subtle styling
        Text(
          '1 ${widget.item.baseCurrency} = ${widget.item.rate.toStringAsFixed(4)} ${widget.item.targetCurrency}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildTrailingSection(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Timestamp
        Text(
          _formatTimestamp(widget.item.timestamp),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
            fontWeight: FontWeight.w500,
            fontSize: 11,
          ),
        ),

        const SizedBox(height: 8),

        // Action buttons
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.onDelete != null)
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _showDeleteConfirmation(context);
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: theme.colorScheme.error.withOpacity(0.2),
                    ),
                  ),
                  child: Icon(
                    Icons.delete_outline,
                    size: 16,
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            Icon(
              Icons.keyboard_arrow_right,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
              size: 16,
            ),
          ],
        ),
      ],
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.delete_outline,
              color: theme.colorScheme.error,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text('Delete Conversion'),
          ],
        ),
        content: Text(
          'Delete this ${widget.item.baseCurrency} to ${widget.item.targetCurrency} conversion?',
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              widget.onDelete?.call();
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    final isToday =
        now.day == timestamp.day &&
        now.month == timestamp.month &&
        now.year == timestamp.year;

    if (isToday) {
      if (difference.inMinutes < 1) return 'Now';
      if (difference.inMinutes < 60) return '${difference.inMinutes}m';
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }

  String _getCurrencySymbol(String code) {
    const symbols = {
      'USD': '\$',
      'NGN': '₦',
      'EUR': '€',
      'GBP': '£',
      'JPY': '¥',
      'CNY': '¥',
      'CAD': 'C\$',
      'AUD': 'A\$',
      'CHF': '₣',
      'ZAR': 'R',
      'GHS': '₵',
      'KES': 'Sh',
      'SEK': 'kr',
      'NOK': 'kr',
      'DKK': 'kr',
      'AED': 'د.إ',
      'SAR': '﷼',
      'INR': '₹',
    };
    return symbols[code] ?? code.substring(0, 1);
  }
}
