import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/constants.dart';
import '../../../../data/services/currency_service.dart';

class PopularPairsWidget extends StatefulWidget {
  final Function(String, String)? onPopularPairTap;

  const PopularPairsWidget({super.key, this.onPopularPairTap});

  @override
  State<PopularPairsWidget> createState() => _PopularPairsWidgetState();
}

class _PopularPairsWidgetState extends State<PopularPairsWidget> {
  Timer? _priceUpdateTimer;
  List<PopularPair> _popularPairs = [];
  bool _isLoading = true;
  String? _error;

  // Popular currency pairs - most commonly converted to NGN
  final List<String> _popularCurrencies = ['USD', 'GBP', 'EUR', 'CAD'];
  final String _baseCurrency = 'NGN';

  @override
  void initState() {
    super.initState();
    _loadPopularPairs();
    _startPriceUpdates();
  }

  @override
  void dispose() {
    _priceUpdateTimer?.cancel();
    super.dispose();
  }

  void _startPriceUpdates() {
    // Update prices every 30 seconds (less frequent than market overview)
    _priceUpdateTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _updatePrices();
    });
  }

  Future<void> _loadPopularPairs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final pairs = await _fetchPopularPairs();
      if (mounted) {
        setState(() {
          _popularPairs = pairs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Failed to load currency pairs";
          _isLoading = false;
        });
      }
      debugPrint("Popular pairs error: $e");
    }
  }

  Future<void> _updatePrices() async {
    if (_popularPairs.isEmpty) return;

    try {
      // Update prices without showing loading state
      for (int i = 0; i < _popularPairs.length; i++) {
        final pair = _popularPairs[i];
        final rate = await CurrencyService.instance.getRate(
          base: pair.from,
          target: pair.to,
        );

        if (rate != null && mounted) {
          setState(() {
            _popularPairs[i] = PopularPair(
              from: pair.from,
              to: pair.to,
              rate: rate.toStringAsFixed(2),
            );
          });
        }
      }
    } catch (e) {
      // Silent fail on price updates - keep showing previous data
      debugPrint("Price update error: $e");
    }
  }

  Future<List<PopularPair>> _fetchPopularPairs() async {
    final List<PopularPair> pairs = [];

    for (final currency in _popularCurrencies) {
      try {
        final rate = await CurrencyService.instance.getRate(
          base: currency,
          target: _baseCurrency,
        );

        if (rate != null) {
          pairs.add(
            PopularPair(
              from: currency,
              to: _baseCurrency,
              rate: rate.toStringAsFixed(2),
            ),
          );
        }
      } catch (e) {
        debugPrint("Failed to fetch rate for $currency/$_baseCurrency: $e");
      }
    }

    // Fallback to default pairs if API fails completely
    return pairs.isEmpty ? _getDefaultPairs() : pairs;
  }

  List<PopularPair> _getDefaultPairs() {
    return [
      PopularPair(from: "USD", to: "NGN", rate: "1650.50"),
      PopularPair(from: "GBP", to: "NGN", rate: "2089.75"),
      PopularPair(from: "EUR", to: "NGN", rate: "1789.25"),
      PopularPair(from: "CAD", to: "NGN", rate: "1210.80"),
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
            "Popular Currency Pairs",
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          _buildPopularPairsContent(),
        ],
      ),
    );
  }

  Widget _buildPopularPairsContent() {
    if (_isLoading) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null && _popularPairs.isEmpty) {
      return Container(
        height: 120,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _popularPairs.length,
        itemBuilder: (context, index) {
          final pair = _popularPairs[index];
          return _buildPopularPairCard(pair, index, _popularPairs.length);
        },
      ),
    );
  }

  Widget _buildPopularPairCard(PopularPair pair, int index, int total) {
    return GestureDetector(
      onTap: () => widget.onPopularPairTap?.call(pair.from, pair.to),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 140,
        margin: EdgeInsets.only(right: index < total - 1 ? 12 : 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.8),
              Theme.of(context).colorScheme.primary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                _buildCurrencyFlag(pair.from),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                _buildCurrencyFlag(pair.to),
              ],
            ),
            Text(
              "${pair.from}/${pair.to}",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            Text(
              "₦${pair.rate}",
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyFlag(String currency) {
    // Get currency symbol or abbreviation
    final displayText = _getCurrencySymbol(currency);

    return Container(
      width: 24,
      height: 16,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Center(
        child: Text(
          displayText,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 8,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _getCurrencySymbol(String currency) {
    switch (currency) {
      case 'USD':
        return '\$';
      case 'GBP':
        return '£';
      case 'EUR':
        return '€';
      case 'NGN':
        return '₦';
      case 'CAD':
        return 'C\$';
      case 'AUD':
        return 'A\$';
      case 'JPY':
        return '¥';
      case 'CHF':
        return 'Fr';
      default:
        return currency;
    }
  }
}

// Data model for popular pairs
class PopularPair {
  final String from;
  final String to;
  final String rate;

  PopularPair({required this.from, required this.to, required this.rate});
}
