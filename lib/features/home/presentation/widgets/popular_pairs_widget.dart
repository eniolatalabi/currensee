// lib/features/home/presentation/widgets/popular_pairs_widget.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants.dart';
import '../../../../data/services/currency_service.dart';
import '../../../../data/services/preferences_service.dart';
import '../../../profile/controller/preferences_controller.dart';

// PopularPair model class
class PopularPair {
  final String from;
  final String to;
  final String rate;

  const PopularPair({required this.from, required this.to, required this.rate});
}

class EnhancedPopularPairsWidget extends StatefulWidget {
  final Function(String, String)? onPopularPairTap;

  const EnhancedPopularPairsWidget({super.key, this.onPopularPairTap});

  @override
  State<EnhancedPopularPairsWidget> createState() =>
      _EnhancedPopularPairsWidgetState();
}

class _EnhancedPopularPairsWidgetState extends State<EnhancedPopularPairsWidget>
    with TickerProviderStateMixin {
  Timer? _priceUpdateTimer;
  List<PopularPair> _popularPairs = [];
  bool _isLoading = true;
  String? _error;
  String _userBaseCurrency = 'NGN';
  String? _lastBaseCurrency;

  // Animation controllers
  late final AnimationController _pulseController;
  late final AnimationController _shimmerController;
  late final AnimationController _cardController;
  late final AnimationController _floatingController;

  // Animations
  late final Animation<double> _pulseAnimation;
  late final Animation<double> _shimmerAnimation;
  late final Animation<double> _cardScaleAnimation;
  late final Animation<double> _floatingAnimation;

  // Primary popular currencies (ordered by global usage)
  static const List<String> _primaryCurrencies = ['USD', 'EUR', 'GBP', 'JPY'];

  // Secondary currencies used when user's base currency conflicts
  static const List<String> _secondaryCurrencies = ['CAD', 'AUD', 'CHF', 'CNY'];

  // Color palette for cards
  final List<List<Color>> _cardGradients = [
    [Color(0xFF667eea), Color(0xFF764ba2)], // Purple-blue
    [Color(0xFF11998e), Color(0xFF38ef7d)], // Teal-green
    [Color(0xFFfc4a1a), Color(0xFFf7b733)], // Orange-yellow
    [Color(0xFF4facfe), Color(0xFF00f2fe)], // Blue-cyan
  ];

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _cardController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    // Setup animations
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _shimmerAnimation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    _cardScaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.elasticOut),
    );

    _floatingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );

    _loadUserPreferences();

    // Start continuous animations
    _shimmerController.repeat(reverse: true);
    _floatingController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _priceUpdateTimer?.cancel();
    _pulseController.dispose();
    _shimmerController.dispose();
    _cardController.dispose();
    _floatingController.dispose();
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

      _lastBaseCurrency = _userBaseCurrency;
      await _loadPopularPairs();
      _startPriceUpdates();
    } catch (e) {
      debugPrint('Error loading user preferences: $e');
      _userBaseCurrency = 'NGN'; // fallback
      _lastBaseCurrency = _userBaseCurrency;
      await _loadPopularPairs();
      _startPriceUpdates();
    }
  }

  void _startPriceUpdates() {
    _priceUpdateTimer = Timer.periodic(const Duration(seconds: 35), (_) {
      _updatePrices();
    });
  }

  /// Get popular currencies excluding user's base currency
  List<String> _getPopularCurrencies() {
    List<String> currencies = [];

    // Start with primary currencies, excluding user's base currency
    for (String currency in _primaryCurrencies) {
      if (currency != _userBaseCurrency) {
        currencies.add(currency);
      }
    }

    // If we need more currencies (user's base was in primary list), add from secondary
    if (currencies.length < 4) {
      for (String currency in _secondaryCurrencies) {
        if (currency != _userBaseCurrency && !currencies.contains(currency)) {
          currencies.add(currency);
          if (currencies.length >= 4) break;
        }
      }
    }

    // Take only first 4 currencies
    return currencies.take(4).toList();
  }

  Future<void> _loadPopularPairs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    // Update user base currency if it changed
    if (mounted) {
      try {
        final prefsController = context.read<PreferencesController>();
        _userBaseCurrency = prefsController.preferences.defaultBaseCurrency;
      } catch (e) {
        // Keep existing value if preferences not available
      }
    }

    // Simulate loading for better UX
    await Future.delayed(const Duration(milliseconds: 1000));

    try {
      final pairs = await _fetchPopularPairs();
      if (mounted) {
        setState(() {
          _popularPairs = pairs;
          _isLoading = false;
        });

        // Trigger card entrance animation
        _cardController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Failed to load currency pairs";
          _isLoading = false;
          _popularPairs = _getDefaultPairs();
        });
        _cardController.forward();
      }
    }
  }

  Future<void> _updatePrices() async {
    if (_popularPairs.isEmpty || !mounted) return;

    // Subtle pulse animation during update
    _pulseController.forward().then((_) {
      if (mounted) _pulseController.reverse();
    });

    // Add haptic feedback
    HapticFeedback.lightImpact();

    try {
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
      debugPrint("Price update error: $e");
    }
  }

  Future<List<PopularPair>> _fetchPopularPairs() async {
    final popularCurrencies = _getPopularCurrencies();
    final List<PopularPair> pairs = [];

    for (final currency in popularCurrencies) {
      try {
        final rate = await CurrencyService.instance.getRate(
          base: currency,
          target: _userBaseCurrency,
        );

        if (rate != null) {
          pairs.add(
            PopularPair(
              from: currency,
              to: _userBaseCurrency,
              rate: rate.toStringAsFixed(2),
            ),
          );
        }
      } catch (e) {
        debugPrint("Failed to fetch rate for $currency/$_userBaseCurrency: $e");
      }
    }

    return pairs.isEmpty ? _getDefaultPairs() : pairs;
  }

  List<PopularPair> _getDefaultPairs() {
    final popularCurrencies = _getPopularCurrencies();
    final List<PopularPair> defaultPairs = [];

    // Default rates based on common exchange rates (adjust as needed)
    final Map<String, String> defaultRates = {
      'USD': '1650.50',
      'EUR': '1789.25',
      'GBP': '2089.75',
      'JPY': '11.50',
      'CAD': '1210.80',
      'AUD': '1089.25',
      'CHF': '1825.40',
      'CNY': '228.75',
    };

    for (int i = 0; i < popularCurrencies.length && i < 4; i++) {
      final currency = popularCurrencies[i];
      defaultPairs.add(
        PopularPair(
          from: currency,
          to: _userBaseCurrency,
          rate: defaultRates[currency] ?? '1000.00',
        ),
      );
    }

    return defaultPairs;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PreferencesController>(
      builder: (context, prefsController, child) {
        final currentBaseCurrency =
            prefsController.preferences.defaultBaseCurrency;

        // Check if base currency changed
        if (_lastBaseCurrency != currentBaseCurrency) {
          // Base currency changed, reload pairs
          _userBaseCurrency = currentBaseCurrency;
          _lastBaseCurrency = currentBaseCurrency;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _loadPopularPairs();
            }
          });
        }

        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingMedium,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAdvancedHeader(context),
              const SizedBox(height: 16),
              _isLoading
                  ? _buildAdvancedSkeleton(context)
                  : _buildPopularPairsContent(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAdvancedHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.secondaryContainer.withValues(alpha: 0.15),
            theme.colorScheme.secondaryContainer.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.secondary.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.secondary.withValues(alpha: 0.2),
                  theme.colorScheme.secondary.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.currency_exchange_rounded,
              color: theme.colorScheme.secondary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Popular Currency Pairs",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.secondary,
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

  Widget _buildAdvancedSkeleton(BuildContext context) {
    final theme = Theme.of(context);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.6,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.3,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

  Widget _buildPopularPairsContent() {
    return ScaleTransition(
      scale: _cardScaleAnimation,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.6,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _popularPairs.length,
        itemBuilder: (context, index) {
          final pair = _popularPairs[index];
          return _buildEnhancedPairCard(pair, index);
        },
      ),
    );
  }

  Widget _buildEnhancedPairCard(PopularPair pair, int index) {
    final theme = Theme.of(context);
    final gradientColors = _cardGradients[index % _cardGradients.length];

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onPopularPairTap?.call(pair.from, pair.to);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors
                  .map((c) => c.withValues(alpha: 0.1))
                  .toList(),
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: gradientColors.first.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      pair.from,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: gradientColors.first,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      pair.to,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: gradientColors.last,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  pair.rate,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "1 ${pair.from} = ${pair.rate} ${pair.to}",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
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
