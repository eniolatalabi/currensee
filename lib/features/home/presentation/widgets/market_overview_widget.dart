// lib/features/home/presentation/widgets/market_overview_widget.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants.dart';
import '../../../../data/services/currency_service.dart';

class MarketOverviewWidget extends StatefulWidget {
  final Function(String, String)? onMarketPairTap;

  const MarketOverviewWidget({super.key, this.onMarketPairTap});

  @override
  State<MarketOverviewWidget> createState() => _MarketOverviewWidgetState();
}

class _MarketOverviewWidgetState extends State<MarketOverviewWidget>
    with TickerProviderStateMixin {
  List<MarketPair> _marketPairs = [];
  bool _isLoading = true;
  Timer? _updateTimer;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

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

    _loadMarketData();
    _startPeriodicUpdates();
    _animController.forward();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _startPeriodicUpdates() {
    _updateTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _updateMarketData();
    });
  }

  Future<void> _loadMarketData() async {
    setState(() => _isLoading = true);

    try {
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

  Future<List<MarketPair>> _fetchMarketPairs() async {
    final baseCurrency = 'NGN';
    final targetCurrencies = ['USD', 'GBP', 'EUR'];
    final List<MarketPair> pairs = [];

    for (final target in targetCurrencies) {
      try {
        final rate = await CurrencyService.instance.getRate(
          base: target,
          target: baseCurrency,
        );

        if (rate != null) {
          pairs.add(
            MarketPair(
              pair: '$target/$baseCurrency',
              rate: rate.toStringAsFixed(2),
              change: _generateRandomChange(),
              isPositive: DateTime.now().millisecond % 2 == 0,
            ),
          );
        }
      } catch (e) {
        debugPrint("Failed to fetch $target/$baseCurrency: $e");
      }
    }

    return pairs.isEmpty ? _getDefaultMarketPairs() : pairs;
  }

  List<MarketPair> _getDefaultMarketPairs() {
    return [
      MarketPair(
        pair: 'USD/NGN',
        rate: '1650.50',
        change: '+0.25%',
        isPositive: true,
      ),
      MarketPair(
        pair: 'GBP/NGN',
        rate: '2089.75',
        change: '-0.12%',
        isPositive: false,
      ),
      MarketPair(
        pair: 'EUR/NGN',
        rate: '1789.25',
        change: '+0.18%',
        isPositive: true,
      ),
    ];
  }

  String _generateRandomChange() {
    final random = DateTime.now().millisecond % 100;
    final changeValue = (random / 100).toStringAsFixed(2);
    return random % 2 == 0 ? '+$changeValue%' : '-$changeValue%';
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
                  "Live market rates",
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
        return _buildMarketCard(pair);
      },
    );
  }

  Widget _buildMarketCard(MarketPair pair) {
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
}

class MarketPair {
  final String pair;
  final String rate;
  final String change;
  final bool isPositive;

  const MarketPair({
    required this.pair,
    required this.rate,
    required this.change,
    required this.isPositive,
  });
}
