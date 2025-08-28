// lib/features/conversion/presentation/widgets/enhanced_currency_search_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../data/services/currency_service.dart';
import '../../controller/conversion_controller.dart';

class EnhancedCurrencySearchSheet extends StatefulWidget {
  final bool isBaseCurrency;
  final ConversionController controller;
  final String currentSelection;

  const EnhancedCurrencySearchSheet({
    super.key,
    required this.isBaseCurrency,
    required this.controller,
    required this.currentSelection,
  });

  @override
  State<EnhancedCurrencySearchSheet> createState() =>
      _EnhancedCurrencySearchSheetState();
}

class _EnhancedCurrencySearchSheetState
    extends State<EnhancedCurrencySearchSheet>
    with TickerProviderStateMixin {
  late final TextEditingController _searchController;
  late final FocusNode _searchFocus;
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  String _searchQuery = '';
  String _selectedRegion = 'All';

  // Enhanced recent currencies with more intelligent tracking
  final Set<String> _recentCurrencies = {
    'USD',
    'EUR',
    'GBP',
    'NGN',
    'CAD',
    'AUD',
  };

  // More comprehensive regional groupings
  static const Map<String, List<String>> _regions = {
    'All': [],
    'Popular': ['USD', 'EUR', 'GBP', 'JPY', 'CAD', 'AUD', 'CHF', 'NGN'],
    'Africa': ['NGN', 'ZAR', 'GHS', 'KES'],
    'Europe': ['EUR', 'GBP', 'CHF', 'SEK', 'NOK', 'DKK'],
    'Asia': ['JPY', 'CNY', 'INR', 'AED', 'SAR'],
    'Americas': ['USD', 'CAD', 'AUD'],
  };

  // Enhanced currency symbols with more coverage
  static const Map<String, String> _currencySymbols = {
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

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocus = FocusNode();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();

    // Delayed focus for smoother animation
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _searchFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _animationController.dispose();
    super.dispose();
  }

  List<String> get _filteredCurrencies {
    List<String> currencies = List.from(CurrencyService.supportedCodes);

    // Region filter
    if (_selectedRegion != 'All') {
      final regionCurrencies = _regions[_selectedRegion] ?? [];
      currencies = currencies
          .where((code) => regionCurrencies.contains(code))
          .toList();
    }

    // Enhanced search with fuzzy matching
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      currencies = currencies.where((code) {
        final name =
            CurrencyService.supportedCurrencyNames[code]?.toLowerCase() ?? '';
        final symbol = _currencySymbols[code]?.toLowerCase() ?? '';
        return code.toLowerCase().contains(query) ||
            name.contains(query) ||
            symbol.contains(query) ||
            name.split(' ').any((word) => word.startsWith(query));
      }).toList();
    }

    // Enhanced sorting logic
    currencies.sort((a, b) {
      // Current selection first
      if (a == widget.currentSelection) return -1;
      if (b == widget.currentSelection) return 1;

      // Recent currencies second
      final aIsRecent = _recentCurrencies.contains(a);
      final bIsRecent = _recentCurrencies.contains(b);
      if (aIsRecent != bIsRecent) return aIsRecent ? -1 : 1;

      // Search relevance third (if searching)
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final aStarts = a.toLowerCase().startsWith(query);
        final bStarts = b.toLowerCase().startsWith(query);
        if (aStarts != bStarts) return aStarts ? -1 : 1;
      }

      // Alphabetical last
      return a.compareTo(b);
    });

    return currencies;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final safePadding = mediaQuery.padding;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          height: mediaQuery.size.height * 0.85, // Slightly more compact
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20), // Slightly more rounded
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildCompactHeader(theme),
              _buildEnhancedSearchBar(theme),
              _buildCompactRegionChips(theme),
              Expanded(child: _buildEnhancedCurrencyList(theme, safePadding)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
      child: Row(
        children: [
          // Handle indicator
          Container(
            width: 32,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outline.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Spacer(),
          // Title
          Text(
            widget.isBaseCurrency ? 'Select Base' : 'Select Target',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          // Close button
          Material(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 40,
                height: 40,
                child: Icon(
                  Icons.close_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedSearchBar(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _searchFocus.hasFocus
              ? theme.colorScheme.primary.withOpacity(0.5)
              : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocus,
        onChanged: (value) => setState(() => _searchQuery = value),
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: 'Search currency...',
          hintStyle: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
          prefixIcon: Container(
            padding: const EdgeInsets.all(12),
            child: Icon(
              Icons.search_rounded,
              color: theme.colorScheme.primary,
              size: 22,
            ),
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                      _searchFocus.requestFocus();
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      child: Icon(
                        Icons.clear_rounded,
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                    ),
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildCompactRegionChips(ThemeData theme) {
    return Container(
      height: 44, // More compact
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _regions.keys.length,
        itemBuilder: (context, index) {
          final region = _regions.keys.elementAt(index);
          final isSelected = region == _selectedRegion;

          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: Material(
              color: isSelected
                  ? theme.colorScheme.primary.withOpacity(0.12)
                  : theme.colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () {
                  setState(() => _selectedRegion = isSelected ? 'All' : region);
                  HapticFeedback.lightImpact();
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    region,
                    style: TextStyle(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEnhancedCurrencyList(ThemeData theme, EdgeInsets safePadding) {
    final filteredCurrencies = _filteredCurrencies;

    if (filteredCurrencies.isEmpty) {
      return _buildEmptyState(theme);
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16, 8, 16, safePadding.bottom + 16),
      itemCount: filteredCurrencies.length,
      itemBuilder: (context, index) {
        final code = filteredCurrencies[index];
        return _buildEnhancedCurrencyTile(theme, code, index);
      },
    );
  }

  Widget _buildEnhancedCurrencyTile(ThemeData theme, String code, int index) {
    final name = CurrencyService.supportedCurrencyNames[code] ?? code;
    final isSelected = code == widget.currentSelection;
    final isRecent = _recentCurrencies.contains(code);
    final symbol = _currencySymbols[code] ?? code.substring(0, 2);

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 100 + (index * 30).clamp(0, 300)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, (1 - value) * 8),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 4),
              child: Material(
                color: isSelected
                    ? theme.colorScheme.primary.withOpacity(0.08)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: () => _selectCurrency(code),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: isSelected
                          ? Border.all(
                              color: theme.colorScheme.primary.withOpacity(0.3),
                              width: 1.5,
                            )
                          : null,
                    ),
                    child: Row(
                      children: [
                        // Enhanced symbol avatar
                        Hero(
                          tag: 'currency_$code',
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isSelected
                                    ? [
                                        theme.colorScheme.primary.withOpacity(
                                          0.2,
                                        ),
                                        theme.colorScheme.primary.withOpacity(
                                          0.1,
                                        ),
                                      ]
                                    : [
                                        theme.colorScheme.surfaceVariant
                                            .withOpacity(0.5),
                                        theme.colorScheme.surfaceVariant
                                            .withOpacity(0.3),
                                      ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                symbol,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Currency info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: theme.textTheme.bodyLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: isSelected
                                                ? theme.colorScheme.primary
                                                : theme.colorScheme.onSurface,
                                          ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isRecent) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.secondary
                                            .withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Recent',
                                        style: TextStyle(
                                          color: theme.colorScheme.secondary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                code,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Selection indicator
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            isSelected
                                ? Icons.check_circle_rounded
                                : Icons.chevron_right_rounded,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant
                                      .withOpacity(0.4),
                            size: isSelected ? 22 : 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 40,
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No currencies found',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _selectCurrency(String code) {
    HapticFeedback.selectionClick();

    // Update controller
    if (widget.isBaseCurrency) {
      widget.controller.updateBaseCurrency(code);
    } else {
      widget.controller.updateTargetCurrency(code);
    }

    // Add to recent currencies (simulate usage tracking)
    _recentCurrencies.add(code);
    if (_recentCurrencies.length > 6) {
      _recentCurrencies.remove(_recentCurrencies.first);
    }

    // Smooth close with slight delay
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) Navigator.pop(context);
    });
  }
}
