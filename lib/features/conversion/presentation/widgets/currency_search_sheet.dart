// lib/features/conversion/presentation/widgets/currency_search_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../data/services/currency_service.dart';
import '../../controller/conversion_controller.dart';
import '../../../../core/constants.dart';

class CurrencySearchSheet extends StatefulWidget {
  final bool isBaseCurrency;
  final ConversionController controller;
  final String currentSelection;

  const CurrencySearchSheet({
    super.key,
    required this.isBaseCurrency,
    required this.controller,
    required this.currentSelection,
  });

  @override
  State<CurrencySearchSheet> createState() => _CurrencySearchSheetState();
}

class _CurrencySearchSheetState extends State<CurrencySearchSheet>
    with TickerProviderStateMixin {
  late final TextEditingController _searchController;
  late final FocusNode _searchFocus;
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  String _searchQuery = '';
  String _selectedRegion = 'All';

  // Mock recent data
  final Set<String> _recentCurrencies = {'USD', 'EUR', 'GBP', 'NGN', 'CAD'};

  // Regional groupings
  static const Map<String, List<String>> _regions = {
    'All': [],
    'Popular': ['USD', 'EUR', 'GBP', 'JPY', 'CAD', 'AUD', 'CHF', 'NGN'],
    'Africa': ['NGN', 'ZAR', 'GHS', 'KES'],
    'Europe': ['EUR', 'GBP', 'CHF', 'SEK', 'NOK', 'DKK'],
    'Asia': ['JPY', 'CNY', 'INR', 'AED', 'SAR'],
    'Americas': ['USD', 'CAD', 'AUD'],
  };

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocus = FocusNode();
    _animationController = AnimationController(
      duration: AppConstants.normalAnim,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();

    Future.delayed(const Duration(milliseconds: 150), () {
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

    // Search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      currencies = currencies.where((code) {
        final name = CurrencyService.supportedCurrencyNames[code] ?? '';
        return code.toLowerCase().contains(query) ||
            name.toLowerCase().contains(query);
      }).toList();
    }

    // Sorting: selection first → recent → alphabetical
    currencies.sort((a, b) {
      if (a == widget.currentSelection) return -1;
      if (b == widget.currentSelection) return 1;

      final aIsRecent = _recentCurrencies.contains(a);
      final bIsRecent = _recentCurrencies.contains(b);
      if (aIsRecent != bIsRecent) {
        return aIsRecent ? -1 : 1;
      }

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
          height: mediaQuery.size.height * 0.9,
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppConstants.radius * 1.5),
            ),
          ),
          child: Column(
            children: [
              _buildHandle(theme),
              _buildHeader(theme),
              _buildSearchBar(theme),
              _buildRegionChips(theme),
              Expanded(child: _buildCurrencyList(theme, safePadding)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHandle(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(top: AppConstants.paddingMedium),
      width: 48,
      height: 4,
      decoration: BoxDecoration(
        color: theme.colorScheme.outline.withOpacity(0.4),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isBaseCurrency
                      ? 'Select Base Currency'
                      : 'Select Target Currency',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${CurrencyService.supportedCodes.length} currencies available',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(AppConstants.radius),
            ),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                Icons.close_rounded,
                color: theme.colorScheme.onSurface,
              ),
              tooltip: 'Close',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingLarge,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(AppConstants.radius),
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
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: 'Search by code or name...',
            hintStyle: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: theme.colorScheme.primary,
              size: 24,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                    icon: Icon(
                      Icons.clear_rounded,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                    tooltip: 'Clear search',
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingMedium,
              vertical: AppConstants.paddingMedium,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegionChips(ThemeData theme) {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingLarge,
        ),
        itemCount: _regions.keys.length,
        itemBuilder: (context, index) {
          final region = _regions.keys.elementAt(index);
          final isSelected = region == _selectedRegion;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(region),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedRegion = selected ? region : 'All');
                HapticFeedback.lightImpact();
              },
              backgroundColor: theme.colorScheme.surface,
              selectedColor: theme.colorScheme.primary.withOpacity(0.15),
              checkmarkColor: theme.colorScheme.primary,
              side: BorderSide(
                color: isSelected
                    ? theme.colorScheme.primary.withOpacity(0.3)
                    : theme.colorScheme.outline.withOpacity(0.2),
              ),
              labelStyle: TextStyle(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrencyList(ThemeData theme, EdgeInsets safePadding) {
    final filteredCurrencies = _filteredCurrencies;

    if (filteredCurrencies.isEmpty) {
      return _buildEmptyState(theme);
    }

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        AppConstants.paddingLarge,
        AppConstants.paddingSmall,
        AppConstants.paddingLarge,
        safePadding.bottom + AppConstants.paddingMedium,
      ),
      itemCount: filteredCurrencies.length,
      separatorBuilder: (context, index) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final code = filteredCurrencies[index];
        return _buildCurrencyTile(theme, code, index);
      },
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            Text(
              'No currencies found',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: AppConstants.paddingSmall),
            Text(
              'Try adjusting your search terms or filters',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyTile(ThemeData theme, String code, int index) {
    final name = CurrencyService.supportedCurrencyNames[code] ?? code;
    final isSelected = code == widget.currentSelection;
    final isRecent = _recentCurrencies.contains(code);

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 100 + (index * 50).clamp(0, 500)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, (1 - value) * 10),
          child: Opacity(
            opacity: value,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _selectCurrency(code),
                borderRadius: BorderRadius.circular(AppConstants.radius),
                child: Container(
                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary.withOpacity(0.08)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppConstants.radius),
                    border: isSelected
                        ? Border.all(
                            color: theme.colorScheme.primary.withOpacity(0.3),
                            width: 1,
                          )
                        : null,
                  ),
                  child: Row(
                    children: [
                      // Symbol avatar
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.colorScheme.primary.withOpacity(0.15)
                              : theme.colorScheme.surfaceVariant.withOpacity(
                                  0.5,
                                ),
                          borderRadius: BorderRadius.circular(
                            AppConstants.radius,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _getCurrencySymbol(code),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppConstants.paddingMedium),

                      // Name + code
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    name,
                                    style: theme.textTheme.bodyLarge?.copyWith(
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
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.secondary
                                          .withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Recent',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: theme.colorScheme.secondary,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 11,
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
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.7,
                                ),
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Right icon
                      Icon(
                        isSelected
                            ? Icons.check_circle_rounded
                            : Icons.arrow_forward_ios_rounded,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface.withOpacity(0.4),
                        size: isSelected ? 20 : 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _selectCurrency(String code) {
    HapticFeedback.selectionClick();
    if (widget.isBaseCurrency) {
      widget.controller.updateBaseCurrency(code);
    } else {
      widget.controller.updateTargetCurrency(code);
    }
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) Navigator.pop(context);
    });
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
    return symbols[code] ?? code.substring(0, 2);
  }
}
