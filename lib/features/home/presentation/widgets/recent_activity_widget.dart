// lib/features/home/presentation/widgets/recent_activity_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants.dart';
import '../../../../core/navigation_controller.dart';
import '../../../../utils/formatters.dart';
import '../../../history/controller/history_controller.dart';
import '../../../history/presentation/history_detail_sheet.dart';
import '../../../../data/models/conversion_history_model.dart';

class RecentActivityWidget extends StatefulWidget {
  const RecentActivityWidget({super.key});

  @override
  State<RecentActivityWidget> createState() => _RecentActivityWidgetState();
}

class _RecentActivityWidgetState extends State<RecentActivityWidget> {
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    // Load recent conversions when widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRecentData();
    });
  }

  void _loadRecentData() {
    if (!_hasInitialized && mounted) {
      try {
        final historyController = context.read<HistoryController>();
        historyController.loadRecent(limit: 5);
        _hasInitialized = true;
        debugPrint('[RecentActivityWidget] Initialized and loaded recent data');
      } catch (e) {
        debugPrint(
          '[RecentActivityWidget] Error accessing HistoryController: $e',
        );
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Try to load data again if not initialized
    if (!_hasInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadRecentData();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingMedium,
      ),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: [_buildHeader(context), _buildContent(context)]),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
          Icon(Icons.history, color: theme.colorScheme.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Recent Activity',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          Consumer<HistoryController>(
            builder: (context, controller, _) {
              if (controller.history.isNotEmpty) {
                return TextButton(
                  onPressed: () => _navigateToHistoryScreen(context),
                  child: Text(
                    'View All',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Consumer<HistoryController>(
      builder: (context, controller, _) {
        debugPrint(
          '[RecentActivityWidget] Building content - Loading: ${controller.isLoading}, Error: ${controller.error}, History count: ${controller.history.length}',
        );

        if (controller.isLoading) {
          return _buildLoadingState(context);
        }

        if (controller.error != null) {
          return _buildErrorState(context, controller);
        }

        if (controller.history.isEmpty) {
          return _buildEmptyState(context);
        }

        return _buildHistoryList(context, controller);
      },
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(32),
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorState(BuildContext context, HistoryController controller) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.error, size: 32),
          const SizedBox(height: 8),
          Text(
            'Failed to load recent activity',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            controller.error!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              controller.loadRecent(limit: 5);
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(
            Icons.history_outlined,
            color: theme.colorScheme.onSurface.withOpacity(0.4),
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            'No recent conversions',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Start converting currencies to see your activity here',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(BuildContext context, HistoryController controller) {
    // Show up to 5 recent conversions
    final recentConversions = controller.history.take(5).toList();

    debugPrint(
      '[RecentActivityWidget] Displaying ${recentConversions.length} recent conversions',
    );

    return Column(
      children: [
        ...recentConversions.asMap().entries.map((entry) {
          final index = entry.key;
          final conversion = entry.value;
          final isLast = index == recentConversions.length - 1;

          return Column(
            children: [
              _buildHistoryItem(context, conversion),
              if (!isLast) const Divider(height: 1),
            ],
          );
        }).toList(),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildHistoryItem(BuildContext context, ConversionHistory conversion) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => _showConversionDetails(context, conversion),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Currency symbols
            _buildCurrencySymbols(context, conversion),
            const SizedBox(width: 12),

            // Conversion details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        conversion.baseCurrency,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward,
                        size: 14,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                      Text(
                        conversion.targetCurrency,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${Formatters.formatCurrency(conversion.baseAmount, conversion.baseCurrency)} → ${Formatters.formatCurrency(conversion.convertedAmount, conversion.targetCurrency)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),

            // Timestamp
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatRelativeTime(conversion.timestamp),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Icon(
                  Icons.keyboard_arrow_right,
                  size: 16,
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencySymbols(
    BuildContext context,
    ConversionHistory conversion,
  ) {
    final theme = Theme.of(context);

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer.withOpacity(0.3),
            theme.colorScheme.secondaryContainer.withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _getCurrencySymbol(conversion.baseCurrency),
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
              fontSize: 8,
            ),
          ),
          Icon(
            Icons.arrow_downward,
            size: 8,
            color: theme.colorScheme.primary.withOpacity(0.7),
          ),
          Text(
            _getCurrencySymbol(conversion.targetCurrency),
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.secondary,
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }

  void _showConversionDetails(
    BuildContext context,
    ConversionHistory conversion,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HistoryDetailSheet(item: conversion),
    );
  }

  void _navigateToHistoryScreen(BuildContext context) {
    // Use the NavigationController to switch to the history tab
    NavigationController.instance.navigateToHistory();
  }

  String _formatRelativeTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';

    return '${timestamp.day}/${timestamp.month}';
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
