// lib/features/home/presentation/widgets/quick_conversion.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../conversion/controller/conversion_controller.dart';
import '../../../conversion/presentation/widgets/amount_input.dart';
import '../../../conversion/presentation/widgets/conversion_result.dart';
import '../../../conversion/presentation/widgets/currency_search_sheet.dart'
    as search_sheet;
import '../../../../core/constants.dart';
import '../../../../data/services/currency_service.dart';

class QuickConversion extends StatefulWidget {
  const QuickConversion({super.key});

  @override
  State<QuickConversion> createState() => _QuickConversionState();
}

class _QuickConversionState extends State<QuickConversion>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
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
    final theme = Theme.of(context);

    return Consumer<ConversionController>(
      builder: (context, controller, _) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            margin: const EdgeInsets.all(AppConstants.paddingMedium),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildHeader(context, controller),
                _buildContent(context, controller),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, ConversionController controller) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.08),
            theme.colorScheme.primaryContainer.withOpacity(0.04),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outline.withOpacity(0.1)),
        ),
      ),
      child: Row(
        children: [
          // Left side - Title with icon
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Icon(
                  Icons.flash_on,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Quick Convert',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),

          // Right side - Currency pair
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${controller.baseCurrency} → ${controller.targetCurrency}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, ConversionController controller) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildCurrencySection(context, controller),
          const SizedBox(height: 16),
          _buildAmountSection(context, controller),
          const SizedBox(height: 16),
          _buildConvertButton(context, controller),
          _buildResultSection(context, controller),
        ],
      ),
    );
  }

  Widget _buildCurrencySection(
    BuildContext context,
    ConversionController controller,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildCurrencySelector(
            context,
            'From',
            controller.baseCurrency,
            () => _showCurrencySearch(context, true, controller),
            true,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: _buildSwapButton(context, controller),
        ),
        Expanded(
          child: _buildCurrencySelector(
            context,
            'To',
            controller.targetCurrency,
            () => _showCurrencySearch(context, false, controller),
            false,
          ),
        ),
      ],
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
              ? theme.colorScheme.primaryContainer.withOpacity(0.1)
              : theme.colorScheme.secondaryContainer.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isPrimary
                ? theme.colorScheme.primary.withOpacity(0.2)
                : theme.colorScheme.secondary.withOpacity(0.2),
          ),
        ),
        child: Column(
          children: [
            // Currency symbol
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isPrimary
                    ? theme.colorScheme.primary.withOpacity(0.1)
                    : theme.colorScheme.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  _getCurrencySymbol(currency),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isPrimary
                        ? theme.colorScheme.primary
                        : theme.colorScheme.secondary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Label
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),

            // Currency code
            Text(
              currency,
              style: theme.textTheme.labelMedium?.copyWith(
                color: isPrimary
                    ? theme.colorScheme.primary
                    : theme.colorScheme.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),

            // Arrow indicator
            Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
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
      borderRadius: BorderRadius.circular(10),
      elevation: 2,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          controller.swapCurrencies();
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 36,
          height: 36,
          child: Icon(
            Icons.swap_horiz,
            color: theme.colorScheme.onPrimary,
            size: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildAmountSection(
    BuildContext context,
    ConversionController controller,
  ) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          // Section header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.calculate,
                  color: theme.colorScheme.primary,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'Amount',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          // Amount input
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: AmountInput(controller: controller, compact: true),
          ),
        ],
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
      height: canConvert ? 48 : 0,
      margin: EdgeInsets.only(bottom: canConvert ? 16 : 0),
      child: canConvert
          ? Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
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
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: controller.loading
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.onPrimary,
                        ),
                      )
                    : Icon(Icons.currency_exchange, size: 16),
                label: Text(
                  controller.loading ? 'Converting...' : 'Convert',
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
    if (controller.amount <= 0 && controller.errorMessage == null) {
      return const SizedBox.shrink();
    }

    return ConversionResult(
      baseAmount: controller.amount,
      baseCurrency: controller.baseCurrency,
      targetCurrency: controller.targetCurrency,
      convertedAmount: controller.conversionResult,
      lastUpdated: controller.lastUpdated,
      errorMessage: controller.errorMessage,
      compact: true,
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
      builder: (_) => search_sheet.CurrencySearchSheet(
        isBaseCurrency: isBaseCurrency,
        controller: controller,
        currentSelection: isBaseCurrency
            ? controller.baseCurrency
            : controller.targetCurrency,
      ),
    );
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
