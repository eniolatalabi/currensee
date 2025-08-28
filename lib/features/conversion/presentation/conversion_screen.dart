// lib/features/conversion/presentation/conversion_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants.dart';
import '../../../data/services/currency_service.dart';
import '../controller/conversion_controller.dart';
import 'widgets/amount_input.dart';
import '../presentation/widgets/conversion_result.dart';
import 'widgets/currency_search_sheet.dart';

class ConversionScreen extends StatelessWidget {
  const ConversionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Use existing ConversionController from provider instead of creating new one
    return const _ConversionView();
  }
}

class _ConversionView extends StatefulWidget {
  const _ConversionView();

  @override
  State<_ConversionView> createState() => _ConversionViewState();
}

class _ConversionViewState extends State<_ConversionView>
    with TickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Consumer<ConversionController>(
          builder: (context, controller, _) => FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                child: Column(
                  children: [
                    _buildCompactHeader(context, controller),
                    AppConstants.spacingMedium,
                    _buildCurrencySection(context, controller),
                    AppConstants.spacingMedium,
                    _buildAmountSection(context, controller),
                    AppConstants.spacingMedium,
                    _buildConvertButton(context, controller),
                    AppConstants.spacingMedium,
                    _buildResultSection(context, controller),
                    if (controller.conversionResult != null)
                      _buildQuickActions(context, controller),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactHeader(
    BuildContext context,
    ConversionController controller,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.1),
            theme.colorScheme.primaryContainer.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          // Left side - Title only (no icon)
          Expanded(
            flex: 2,
            child: Text(
              'Currency Converter',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Right side - Currency pair and update info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(
                      alpha: 0.3,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${controller.baseCurrency} → ${controller.targetCurrency}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (controller.lastUpdated != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Updated ${_formatLastUpdated(controller.lastUpdated!)}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencySection(
    BuildContext context,
    ConversionController controller,
  ) {
    return _buildSection(
      context,
      title: 'Currency Pair',
      icon: Icons.swap_horiz,
      child: Column(
        children: [
          _buildCurrencySelector(
            context,
            'From',
            controller.baseCurrency,
            () => _showCurrencySearch(context, true, controller),
            true,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: _buildSwapButton(context, controller),
          ),
          _buildCurrencySelector(
            context,
            'To',
            controller.targetCurrency,
            () => _showCurrencySearch(context, false, controller),
            false,
          ),
        ],
      ),
    );
  }

  Widget _buildAmountSection(
    BuildContext context,
    ConversionController controller,
  ) {
    return _buildSection(
      context,
      title: 'Amount',
      icon: Icons.calculate,
      child: AmountInput(controller: controller),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Compact header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.3,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }

  Widget _buildCurrencySelector(
    BuildContext context,
    String label,
    String currency,
    VoidCallback onTap,
    bool isPrimary,
  ) {
    final theme = Theme.of(context);
    final currencyName =
        CurrencyService.supportedCurrencyNames[currency] ?? currency;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isPrimary
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.1)
              : theme.colorScheme.secondaryContainer.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isPrimary
                ? theme.colorScheme.primary.withValues(alpha: 0.2)
                : theme.colorScheme.secondary.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            // Currency symbol
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isPrimary
                    ? theme.colorScheme.primary.withValues(alpha: 0.1)
                    : theme.colorScheme.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  _getCurrencySymbol(currency),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isPrimary
                        ? theme.colorScheme.primary
                        : theme.colorScheme.secondary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Currency info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    currencyName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    currency,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: isPrimary
                          ? theme.colorScheme.primary
                          : theme.colorScheme.secondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            Icon(
              Icons.keyboard_arrow_right,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwapButton(
    BuildContext context,
    ConversionController controller,
  ) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.primary,
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          controller.swapCurrencies();
        },
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            Icons.swap_vert,
            color: theme.colorScheme.onPrimary,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildConvertButton(
    BuildContext context,
    ConversionController controller,
  ) {
    final theme = Theme.of(context);
    final canConvert = controller.amount > 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: canConvert ? 56 : 0,
      child: canConvert
          ? Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: controller.loading ? null : controller.manualConvert,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: controller.loading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.onPrimary,
                        ),
                      )
                    : const SizedBox.shrink(),
                label: Text(
                  controller.loading ? 'Converting...' : 'Convert Now',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildResultSection(
    BuildContext context,
    ConversionController controller,
  ) {
    return ConversionResult(
      baseAmount: controller.amount,
      convertedAmount: controller.conversionResult,
      baseCurrency: controller.baseCurrency,
      targetCurrency: controller.targetCurrency,
      lastUpdated: controller.lastUpdated,
      errorMessage: controller.errorMessage,
    );
  }

  Widget _buildQuickActions(
    BuildContext context,
    ConversionController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: AppConstants.paddingMedium),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              context,
              Icons.content_copy,
              'Copy',
              () => _copyResult(context, controller),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              context,
              Icons.share,
              'Share',
              () => _shareResult(context, controller),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.3,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCurrencySearch(
    BuildContext context,
    bool isBaseCurrency,
    ConversionController controller,
  ) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EnhancedCurrencySearchSheet(
        isBaseCurrency: isBaseCurrency,
        controller: controller,
        currentSelection: isBaseCurrency
            ? controller.baseCurrency
            : controller.targetCurrency,
      ),
    );
  }

  void _copyResult(BuildContext context, ConversionController controller) {
    if (controller.conversionResult == null) return;

    final result =
        '${controller.formattedAmount} = ${controller.formattedResult}';
    Clipboard.setData(ClipboardData(text: result));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text('Copied to clipboard'),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  void _shareResult(BuildContext context, ConversionController controller) {
    if (controller.conversionResult == null) return;

    final result =
        '${controller.formattedAmount} = ${controller.formattedResult}';
    final shareText =
        'Currency Conversion:\n$result\n\nConverted using Currency Converter';

    Share.share(shareText, subject: 'Currency Conversion Result');
  }

  String _formatLastUpdated(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 30) return 'just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
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
    return symbols[code] ?? code.substring(0, 2);
  }
}
