

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants.dart';

// Use prefix for controller import
import '../../home/controller/home_controller.dart' as home_controller;

// Prefix widget imports to avoid name conflicts
import 'widgets/quick_conversion.dart';
import 'widgets/market_overview_widget.dart' as market_widget;
import 'widgets/popular_pairs_widget.dart' as popular_widget;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late home_controller.HomeController _homeController;

  @override
  void initState() {
    super.initState();
    _homeController = context.read<home_controller.HomeController>();

    // Initialize home data after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _homeController.initializeHomeData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _homeController.refreshHomeData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppConstants.paddingMedium),

            // ✅ Hero Section
            const QuickConversion(),
            const SizedBox(height: AppConstants.paddingMedium),

            // Market Overview - Now using widget with API integration
            market_widget.MarketOverviewWidget(
              onMarketPairTap: (baseCurrency, targetCurrency) {
                _homeController.onMarketPairTap(
                  home_controller.MarketPair(
                    pair: "$baseCurrency/$targetCurrency",
                    rate: "",
                    change: "",
                    isPositive: true,
                  ),
                );
              },
            ),
            const SizedBox(height: AppConstants.paddingMedium),

            // Popular Pairs - Now using widget with API integration
            popular_widget.PopularPairsWidget(
              onPopularPairTap: (fromCurrency, toCurrency) {
                _homeController.onPopularPairTap(
                  home_controller.PopularPair(
                    from: fromCurrency,
                    to: toCurrency,
                    rate: "",
                  ),
                );
              },
            ),
            const SizedBox(height: AppConstants.paddingMedium),

            // Conversion History - Kept as is (Phase 5 implementation)
            _buildConversionHistory(context),
            const SizedBox(height: AppConstants.paddingLarge),
          ],
        ),
      ),
    );
  }

  // ------------------ Conversion History ------------------
  Widget _buildConversionHistory(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingMedium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            context,
            "Conversion History",
            onViewAll: context
                .read<home_controller.HomeController>()
                .onViewAllHistoryTap,
          ),
          const SizedBox(height: 12),
          Consumer<home_controller.HomeController>(
            builder: (context, homeController, child) {
              if (homeController.isLoadingActivities) {
                return Column(
                  children: List.generate(
                    3,
                    (index) => _buildHistoryItemSkeleton(context),
                  ),
                );
              }
              return Column(
                children: homeController.recentActivities
                    .where(
                      (a) => a.type == home_controller.ActivityType.conversion,
                    )
                    .map((a) => _buildHistoryItem(context, a))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItemSkeleton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      height: 68,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _buildHistoryItem(
    BuildContext context,
    home_controller.RecentActivity activity,
  ) {
    return GestureDetector(
      onTap: () => context
          .read<home_controller.HomeController>()
          .onRecentActivityTap(activity),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  activity.title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  activity.timeAgo,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  _getSourceAmount(activity.title),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  activity.amount,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ------------------ Helpers ------------------
  Widget _buildSectionHeader(
    BuildContext context,
    String title, {
    VoidCallback? onViewAll,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        if (onViewAll != null)
          TextButton(
            onPressed: onViewAll,
            child: Text(
              "View All",
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 14,
              ),
            ),
          ),
      ],
    );
  }

  String _getSourceAmount(String title) {
    if (title.contains("USD")) return "\$50.00";
    if (title.contains("GBP")) return "£75.00";
    if (title.contains("EUR")) return "€60.00";
    return "\$0.00";
  }
}
