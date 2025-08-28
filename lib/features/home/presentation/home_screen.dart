// lib/features/home/presentation/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants.dart';
import '../../../data/services/currency_service.dart';
import '../../../features/auth/controller/auth_controller.dart';
import '../../../features/history/controller/history_controller.dart';
import '../../../features/history/service/conversion_history_service.dart';
import '../../../features/conversion/controller/conversion_controller.dart';
// prefix for controller import
import '../controller/home_controller.dart' as home_controller;
// Prefix widget imports to avoid name conflicts
import 'widgets/quick_conversion.dart';
import 'widgets/market_overview_widget.dart' as market_widget;
import 'widgets/popular_pairs_widget.dart' as popular_widget;
import 'widgets/recent_activity_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  late home_controller.HomeController _homeController;

  @override
  bool get wantKeepAlive => true;

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
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return RefreshIndicator(
      onRefresh: () async {
        await _homeController.refreshHomeData();
        // Also refresh recent activity
        if (mounted) {
          context.read<HistoryController>().loadRecent(limit: 5);
        }
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppConstants.paddingMedium),

            // EDITED: Wrap QuickConversion in its own provider to isolate its state
            const QuickConversionProvider(),
            const SizedBox(height: AppConstants.paddingMedium),

            // Market Overview
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

            // Popular Pairs
            popular_widget.EnhancedPopularPairsWidget(
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

            // Recent Activity - Conversion History from SQLite
            const RecentActivityWidget(),
            const SizedBox(height: AppConstants.paddingLarge),
          ],
        ),
      ),
    );
  }
}

/// EDITED: New widget to provide an isolated ConversionController to QuickConversion
class QuickConversionProvider extends StatefulWidget {
  const QuickConversionProvider({super.key});

  @override
  State<QuickConversionProvider> createState() =>
      _QuickConversionProviderState();
}

class _QuickConversionProviderState extends State<QuickConversionProvider> {
  late final ConversionController _quickConversionController;

  @override
  void initState() {
    super.initState();
    // Create a dedicated controller instance for QuickConversion.
    _quickConversionController = ConversionController(
      CurrencyService.instance, // Assumes singleton instance
      context.read<ConversionHistoryService>(),
    );

    // Set user ID for this controller instance
    final authController = context.read<AuthController>();
    if (authController.currentUser != null &&
        !authController.currentUser.isGuest) {
      _quickConversionController.setCurrentUserId(
        authController.currentUser.uid,
      );
    }

    // Set up the success callback to refresh history
    final historyController = context.read<HistoryController>();
    _quickConversionController.setConversionSuccessCallback((message) {
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            historyController.loadRecent(limit: 5);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _quickConversionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Provide the dedicated controller to the QuickConversion widget
    return ChangeNotifierProvider.value(
      value: _quickConversionController,
      child: const QuickConversion(),
    );
  }
}
