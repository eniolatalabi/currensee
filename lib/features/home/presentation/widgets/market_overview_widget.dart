import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/constants.dart';
import '../../../../core/theme.dart';
import '../../../../data/services/currency_service.dart';

class MarketOverviewWidget extends StatefulWidget {
  final Function(String, String)? onMarketPairTap;

  const MarketOverviewWidget({super.key, this.onMarketPairTap});

  @override
  State<MarketOverviewWidget> createState() => _MarketOverviewWidgetState();
}

class _MarketOverviewWidgetState extends State<MarketOverviewWidget> {
  Timer? _refreshTimer;
  List<MarketPair> _marketPairs = [];
  List<MarketPair> _previousPairs = [];
  bool _isLoading = true;
  String? _error;
  int _currentPairIndex = 0;

  // Major currency pairs to cycle through
  final List<String> _majorCurrencies = [
    'USD',
    'GBP',
    'EUR',
    'CAD',
    'AUD',
    'JPY',
  ];
  final String _baseCurrency = 'NGN';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      _refreshMarketData();
    });
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

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
          _error = "Failed to load market data";
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshMarketData() async {
    try {
      _previousPairs = List.from(_marketPairs);
      final pairs = await _fetchMarketPairs();

      if (mounted) {
        setState(() {
          _marketPairs = pairs;
          _error = null;
        });
      }
    } catch (e) {
      // Silent fail on refresh - keep showing previous data
      debugPrint("Market refresh error: $e");
    }
  }

  Future<List<MarketPair>> _fetchMarketPairs() async {
    final List<MarketPair> pairs = [];

    // Get 2 different currency pairs to display (cycling through majors)
    final selectedCurrencies = _getNextCurrencyPair();

    for (final currency in selectedCurrencies) {
      try {
        final rate = await CurrencyService.instance.getRate(
          base: currency,
          target: _baseCurrency,
        );

        if (rate != null) {
          // Calculate mock change percentage (in real app, you'd compare with previous rate)
          final changePercent = _calculateChangePercent(currency, rate);
          final isPositive = changePercent >= 0;

          pairs.add(
            MarketPair(
              pair: "$currency/$_baseCurrency",
              rate: "₦${rate.toStringAsFixed(2)}",
              change:
                  "${isPositive ? '+' : ''}${changePercent.toStringAsFixed(1)}%",
              isPositive: isPositive,
            ),
          );
        }
      } catch (e) {
        debugPrint("Failed to fetch rate for $currency: $e");
      }
    }

    return pairs.isEmpty ? _getDefaultPairs() : pairs;
  }

  List<String> _getNextCurrencyPair() {
    final List<String> selected = [];

    // Always include USD as primary
    selected.add('USD');

    // Add second currency cycling through others
    final secondIndex = (_currentPairIndex % (_majorCurrencies.length - 1)) + 1;
    selected.add(_majorCurrencies[secondIndex]);

    _currentPairIndex++;
    return selected;
  }

  double _calculateChangePercent(String currency, double currentRate) {
    // Mock calculation - in real app, compare with previous stored rate
    final hash = currency.hashCode % 100;
    final baseChange = (hash - 50) / 10.0; // Range: -5.0 to +4.9
    return double.parse(baseChange.toStringAsFixed(1));
  }

  List<MarketPair> _getDefaultPairs() {
    return [
      MarketPair(
        pair: "USD/NGN",
        rate: "₦1,650.50",
        change: "+2.3%",
        isPositive: true,
      ),
      MarketPair(
        pair: "GBP/NGN",
        rate: "₦2,089.75",
        change: "-0.8%",
        isPositive: false,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingMedium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Market Overview",
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          _buildMarketContent(),
        ],
      ),
    );
  }

  Widget _buildMarketContent() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_error != null && _marketPairs.isEmpty) {
      return _buildErrorState();
    }

    return Row(
      children: _marketPairs.asMap().entries.map((entry) {
        final index = entry.key;
        final pair = entry.value;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(
              left: index > 0 ? 6 : 0,
              right: index < _marketPairs.length - 1 ? 6 : 0,
            ),
            child: _buildMarketCard(pair),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLoadingState() {
    return Row(
      children: [
        Expanded(child: _buildMarketCardSkeleton()),
        const SizedBox(width: 12),
        Expanded(child: _buildMarketCardSkeleton()),
      ],
    );
  }

  Widget _buildMarketCardSkeleton() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketCard(MarketPair pair) {
    return GestureDetector(
      onTap: () {
        final currencies = pair.pair.split('/');
        if (currencies.length == 2) {
          widget.onMarketPairTap?.call(currencies[0], currencies[1]);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  pair.pair,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                Icon(
                  pair.isPositive ? Icons.trending_up : Icons.trending_down,
                  size: 16,
                  color: pair.isPositive
                      ? AppTheme.successColor
                      : AppTheme.errorColor,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              pair.rate,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              pair.change,
              style: TextStyle(
                color: pair.isPositive
                    ? AppTheme.successColor
                    : AppTheme.errorColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Data model for market pairs
class MarketPair {
  final String pair;
  final String rate;
  final String change;
  final bool isPositive;

  MarketPair({
    required this.pair,
    required this.rate,
    required this.change,
    required this.isPositive,
  });
}
