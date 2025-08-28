// lib/features/home/presentation/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants.dart';
import '../../../data/services/currency_service.dart';
import '../../../features/auth/controller/auth_controller.dart';
import '../../../features/history/controller/history_controller.dart';
import '../../../features/history/service/conversion_history_service.dart';
import '../../../features/conversion/controller/conversion_controller.dart';
import '../../../features/profile/controller/preferences_controller.dart';
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
  final GlobalKey<State<market_widget.MarketOverviewWidget>>
  _marketOverviewKey = GlobalKey<State<market_widget.MarketOverviewWidget>>();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _homeController = context.read<home_controller.HomeController>();

    // Initialize home data after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _homeController.initializeHomeData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return RefreshIndicator(
      onRefresh: () async {
        await _homeController.refreshHomeData();
        // Refresh market overview using static method
        market_widget.MarketOverviewWidget.refreshWidget(_marketOverviewKey);
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

            // Market Overview with preference listening
            MarketOverviewProvider(
              marketOverviewKey: _marketOverviewKey,
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

/// New wrapper for MarketOverviewWidget that listens to preference changes
class MarketOverviewProvider extends StatefulWidget {
  final Function(String, String)? onMarketPairTap;
  final GlobalKey<State<market_widget.MarketOverviewWidget>> marketOverviewKey;

  const MarketOverviewProvider({
    super.key,
    this.onMarketPairTap,
    required this.marketOverviewKey,
  });

  @override
  State<MarketOverviewProvider> createState() => _MarketOverviewProviderState();
}

class _MarketOverviewProviderState extends State<MarketOverviewProvider> {
  String? _lastBaseCurrency;

  @override
  void initState() {
    super.initState();
    // Get initial base currency
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateLastBaseCurrency();
      }
    });
  }

  void _updateLastBaseCurrency() {
    try {
      final prefsController = context.read<PreferencesController>();
      _lastBaseCurrency = prefsController.preferences.defaultBaseCurrency;
    } catch (e) {
      _lastBaseCurrency = 'NGN'; // fallback
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PreferencesController>(
      builder: (context, prefsController, child) {
        final currentBaseCurrency =
            prefsController.preferences.defaultBaseCurrency;

        // Check if base currency changed
        if (_lastBaseCurrency != currentBaseCurrency) {
          // Base currency changed, refresh market data
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              market_widget.MarketOverviewWidget.refreshWidget(
                widget.marketOverviewKey,
              );
            }
          });
        }

        _lastBaseCurrency = currentBaseCurrency;

        return market_widget.MarketOverviewWidget(
          key: widget.marketOverviewKey,
          onMarketPairTap: widget.onMarketPairTap,
        );
      },
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
  ConversionController? _quickConversionController;

  @override
  void initState() {
    super.initState();

    // Create controller immediately with available dependencies
    _quickConversionController = ConversionController(
      CurrencyService.instance, // Assumes singleton instance
      context.read<ConversionHistoryService>(),
    );

    // Set up additional configurations after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _quickConversionController != null) {
        _initializeControllerSettings();
      }
    });
  }

  void _initializeControllerSettings() {
    if (_quickConversionController == null || !mounted) return;

    // Set user ID for this controller instance
    try {
      final authController = context.read<AuthController>();
      if (authController.currentUser != null &&
          !authController.currentUser.isGuest) {
        _quickConversionController!.setCurrentUserId(
          authController.currentUser.uid,
        );
      }
    } catch (e) {
      debugPrint('AuthController not available: $e');
    }

    // Set up the success callback to refresh history
    try {
      final historyController = context.read<HistoryController>();
      _quickConversionController!.setConversionSuccessCallback((message) {
        if (mounted) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              historyController.loadRecent(limit: 5);
            }
          });
        }
      });
    } catch (e) {
      debugPrint('HistoryController not available: $e');
    }

    // ISSUE 2 FIX: Set up auto-convert callback
    try {
      final prefsController = context.read<PreferencesController>();
      prefsController.setAutoConvertCallback(
        _quickConversionController!.updateAutoConvertSetting,
      );
    } catch (e) {
      // PreferencesController might not be available
      debugPrint('PreferencesController not available in QuickConversion: $e');
    }
  }

  @override
  void dispose() {
    _quickConversionController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Only provide the controller if it's been created
    if (_quickConversionController == null) {
      return const SizedBox.shrink();
    }

    // Provide the dedicated controller to the QuickConversion widget
    return ChangeNotifierProvider.value(
      value: _quickConversionController!,
      child: const QuickConversion(),
    );
  }
}
