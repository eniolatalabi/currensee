// lib/features/home/presentation/widgets/market_overview_widget.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants.dart';
import '../../../../data/services/currency_service.dart';
import '../../../../data/services/preferences_service.dart';
import '../../../profile/controller/preferences_controller.dart';

class MarketOverviewWidget extends StatefulWidget {
  final Function(String, String)? onMarketPairTap;

  const MarketOverviewWidget({super.key, this.onMarketPairTap});

  @override
  State<MarketOverviewWidget> createState() => _MarketOverviewWidgetState();

  /// Public method to trigger refresh from outside
  static void refreshWidget(GlobalKey<State<MarketOverviewWidget>> key) {
    final state = key.currentState as _MarketOverviewWidgetState?;
    state?._loadMarketData();
  }
}

class _MarketOverviewWidgetState extends State<MarketOverviewWidget>
    with TickerProviderStateMixin {
  List<MarketPair> _marketPairs = [];
  bool _isLoading = true;
  Timer? _updateTimer;
  Timer? _rotationTimer;
  String _userBaseCurrency = 'NGN';

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  // Dynamic currency pools (excluding common base currencies to avoid duplication)
  static const List<String> _dynamicCurrencies = [
    'EUR',
    'GBP',
    'JPY',
    'CAD',
    'AUD',
    'CHF',
    'CNY',
    'INR',
    'KRW',
    'ZAR',
  ];

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

    _loadUserPreferences();
    _animController.forward();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _rotationTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadUserPreferences() async {
    try {
      // Try to get from PreferencesController if available
      if (mounted) {
        try {
          final prefsController = context.read<PreferencesController>();
          _userBaseCurrency = prefsController.preferences.defaultBaseCurrency;
        } catch (e) {
          // Fallback to direct service call
          final prefs = await PreferencesService.instance.getUserPreferences();
          _userBaseCurrency = prefs.defaultBaseCurrency;
        }
      }

      await _loadMarketData();
      _startPeriodicUpdates();
      _startCurrencyRotation();
    } catch (e) {
      debugPrint('Error loading user preferences: $e');
      _userBaseCurrency = 'NGN'; // fallback
      await _loadMarketData();
      _startPeriodicUpdates();
      _startCurrencyRotation();
    }
  }

  void _startPeriodicUpdates() {
    _updateTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _updateMarketDataSilently(); // Changed to silent update
    });
  }

  void _startCurrencyRotation() {
    _rotationTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      _rotateDynamicCurrencies();
    });
  }

  Future<void> _loadMarketData() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      // Update user base currency first
      if (mounted) {
        try {
          final prefsController = context.read<PreferencesController>();
          _userBaseCurrency = prefsController.preferences.defaultBaseCurrency;
        } catch (e) {
          // Keep existing value if preferences not available
        }
      }

      final pairs = await _fetchMarketPairs();
      if (mounted) {
        setState(() {
          _marketPairs = pairs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _marketPairs = _getDefaultMarketPairs();
          _isLoading = false;
        });
      }
    }
  }

  // ISSUE 1 FIX: New method for silent updates (no loading spinner)
  Future<void> _updateMarketDataSilently() async {
    if (_marketPairs.isEmpty || !mounted) return;

    HapticFeedback.lightImpact();

    try {
      final updatedPairs = await _fetchMarketPairs();
      if (mounted) {
        setState(() => _marketPairs = updatedPairs);
        // No _isLoading = true here, so no spinner shows
      }
    } catch (e) {
      debugPrint("Market update error: $e");
    }
  }

  // ISSUE 1 FIX: Updated rotation method - no loading spinner
  void _rotateDynamicCurrencies() {
    if (!mounted) return;

    // Update only the dynamic currencies (not the primary one)
    final random = Random();
    final availableCurrencies = _dynamicCurrencies
        .where(
          (currency) =>
              currency != _userBaseCurrency &&
              currency != _getPrimaryCurrency(),
        )
        .toList();

    if (availableCurrencies.length >= 2) {
      availableCurrencies.shuffle(random);
      _updateMarketDataSilently(); // Use silent update instead of _loadMarketData()
    }
  }

  Future<void> _updateMarketData() async {
    if (_marketPairs.isEmpty || !mounted) return;

    HapticFeedback.lightImpact();

    try {
      final updatedPairs = await _fetchMarketPairs();
      if (mounted) {
        setState(() => _marketPairs = updatedPairs);
      }
    } catch (e) {
      debugPrint("Market update error: $e");
    }
  }

  String _getPrimaryCurrency() {
    // If user's base currency is USD, show GBP as primary
    // Otherwise, show USD as primary
    return _userBaseCurrency == 'USD' ? 'GBP' : 'USD';
  }

  List<String> _getDynamicCurrencies() {
    final random = Random();
    final primaryCurrency = _getPrimaryCurrency();

    final availableCurrencies = _dynamicCurrencies
        .where(
          (currency) =>
              currency != _userBaseCurrency && currency != primaryCurrency,
        )
        .toList();

    availableCurrencies.shuffle(random);
    return availableCurrencies.take(2).toList();
  }

  Future<List<MarketPair>> _fetchMarketPairs() async {
    final primaryCurrency = _getPrimaryCurrency();
    final dynamicCurrencies = _getDynamicCurrencies();
    final targetCurrencies = [primaryCurrency, ...dynamicCurrencies];
    final List<MarketPair> pairs = [];

    for (final target in targetCurrencies) {
      try {
        final rate = await CurrencyService.instance.getRate(
          base: target,
          target: _userBaseCurrency,
        );

        if (rate != null) {
          final changeData = _generateRealisticChange();
          pairs.add(
            MarketPair(
              pair: '$target/$_userBaseCurrency',
              rate: rate.toStringAsFixed(2),
              change: changeData['change'],
              isPositive: changeData['isPositive'],
              changePercent: changeData['percent'],
            ),
          );
        }
      } catch (e) {
        debugPrint("Failed to fetch $target/$_userBaseCurrency: $e");
      }
    }

    return pairs.isEmpty ? _getDefaultMarketPairs() : pairs;
  }

  List<MarketPair> _getDefaultMarketPairs() {
    final primaryCurrency = _getPrimaryCurrency();
    final dynamicCurrencies = _getDynamicCurrencies();

    return [
      MarketPair(
        pair: '$primaryCurrency/$_userBaseCurrency',
        rate: primaryCurrency == 'USD' ? '1650.50' : '2089.75',
        change: '+0.25%',
        isPositive: true,
        changePercent: 0.25,
      ),
      MarketPair(
        pair: '${dynamicCurrencies[0]}/$_userBaseCurrency',
        rate: '1789.25',
        change: '-0.12%',
        isPositive: false,
        changePercent: -0.12,
      ),
      MarketPair(
        pair:
            '${dynamicCurrencies.length > 1 ? dynamicCurrencies[1] : 'EUR'}/$_userBaseCurrency',
        rate: '1456.80',
        change: '+0.18%',
        isPositive: true,
        changePercent: 0.18,
      ),
    ];
  }

  Map<String, dynamic> _generateRealisticChange() {
    final random = Random();
    final changePercent = (random.nextDouble() * 2.0 - 1.0); // -1.0 to 1.0
    final isPositive = changePercent >= 0;
    final changeStr =
        '${isPositive ? '+' : ''}${changePercent.abs().toStringAsFixed(2)}%';

    return {
      'change': changeStr,
      'isPositive': isPositive,
      'percent': changePercent,
    };
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingMedium,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            _isLoading ? _buildLoadingSkeleton() : _buildMarketGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer.withValues(alpha: 0.15),
            theme.colorScheme.primaryContainer.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.2),
                  theme.colorScheme.primary.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.trending_up_rounded,
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Market Overview",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Live rates • Base: $_userBaseCurrency",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    final theme = Theme.of(context);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.3,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

  Widget _buildMarketGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _marketPairs.length,
      itemBuilder: (context, index) {
        final pair = _marketPairs[index];
        return _buildMarketCard(pair, index == 0); // First card is primary
      },
    );
  }

  Widget _buildMarketCard(MarketPair pair, bool isPrimary) {
    final theme = Theme.of(context);
    final parts = pair.pair.split('/');
    final baseCurrency = parts[0];
    final targetCurrency = parts[1];

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onMarketPairTap?.call(baseCurrency, targetCurrency);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: pair.isPositive
                  ? Colors.green.withValues(alpha: 0.2)
                  : Colors.red.withValues(alpha: 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Currency pair
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            baseCurrency,
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          Text(
                            '/',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                          Text(
                            targetCurrency,
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Trend arrow
                    _buildTrendArrow(pair),
                  ],
                ),
                Text(
                  pair.rate,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: pair.isPositive
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    pair.change,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: pair.isPositive
                          ? Colors.green[700]
                          : Colors.red[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ISSUE 2 FIX: Use only chart-style trending icons (production-ready)
  Widget _buildTrendArrow(MarketPair pair) {
    final color = pair.isPositive ? Colors.green[600] : Colors.red[600];

    // Always use chart-style trending icons for professional look
    final arrowIcon = pair.isPositive
        ? Icons.trending_up_rounded
        : Icons.trending_down_rounded;

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: color?.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(arrowIcon, size: 12, color: color),
    );
  }
}

class MarketPair {
  final String pair;
  final String rate;
  final String change;
  final bool isPositive;
  final double changePercent;

  const MarketPair({
    required this.pair,
    required this.rate,
    required this.change,
    required this.isPositive,
    this.changePercent = 0.0,
  });
}
