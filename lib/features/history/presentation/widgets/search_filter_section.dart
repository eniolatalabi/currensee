// lib/features/history/presentation/widgets/search_filter_section.dart
import 'package:flutter/material.dart';
import '../../../../data/services/currency_service.dart';
import '../../controller/history_controller.dart';

class SearchFilterSection extends StatefulWidget {
  final HistoryController controller;

  const SearchFilterSection({super.key, required this.controller});

  @override
  State<SearchFilterSection> createState() => _SearchFilterSectionState();
}

class _SearchFilterSectionState extends State<SearchFilterSection>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _filterAnimationController;
  late Animation<double> _filterAnimation;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _filterAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _filterAnimation = CurvedAnimation(
      parent: _filterAnimationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _filterAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          // Search bar with filter toggle
          Row(
            children: [
              Expanded(child: _buildSearchBar(context)),
              const SizedBox(width: 8),
              _buildFilterToggle(context),
            ],
          ),

          // Animated filter section
          SizeTransition(
            sizeFactor: _filterAnimation,
            child: _showFilters
                ? _buildFiltersContent(context)
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: widget.controller.setSearchQuery,
        decoration: InputDecoration(
          hintText: 'Search conversions...',
          hintStyle: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
            size: 20,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    widget.controller.setSearchQuery('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        style: theme.textTheme.bodyMedium,
      ),
    );
  }

  Widget _buildFilterToggle(BuildContext context) {
    final theme = Theme.of(context);
    final hasActiveFilters = widget.controller.hasFilters;

    return GestureDetector(
      onTap: () {
        setState(() {
          _showFilters = !_showFilters;
          if (_showFilters) {
            _filterAnimationController.forward();
          } else {
            _filterAnimationController.reverse();
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _showFilters || hasActiveFilters
              ? theme.colorScheme.primary.withOpacity(0.1)
              : theme.colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _showFilters || hasActiveFilters
                ? theme.colorScheme.primary.withOpacity(0.3)
                : theme.colorScheme.outline.withOpacity(0.1),
          ),
        ),
        child: Stack(
          children: [
            Icon(
              _showFilters ? Icons.tune_outlined : Icons.tune,
              color: _showFilters || hasActiveFilters
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withOpacity(0.6),
              size: 20,
            ),
            if (hasActiveFilters && !_showFilters)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersContent(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter header
          Row(
            children: [
              Icon(
                Icons.filter_list,
                color: theme.colorScheme.primary,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                'Filters',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
              const Spacer(),
              if (widget.controller.hasFilters)
                TextButton(
                  onPressed: widget.controller.clearFilters,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                  ),
                  child: Text(
                    'Clear',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Filter chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildCurrencyFilterChip(
                context,
                'From',
                widget.controller.selectedBaseCurrency,
                widget.controller.setBaseCurrencyFilter,
              ),
              _buildCurrencyFilterChip(
                context,
                'To',
                widget.controller.selectedTargetCurrency,
                widget.controller.setTargetCurrencyFilter,
              ),
              _buildDateRangeChip(context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyFilterChip(
    BuildContext context,
    String label,
    String? selectedCurrency,
    Function(String?) onChanged,
  ) {
    final theme = Theme.of(context);
    final isSelected = selectedCurrency != null;

    return GestureDetector(
      onTap: () =>
          _showCurrencyPicker(context, label, selectedCurrency, onChanged),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer.withOpacity(0.5)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary.withOpacity(0.5)
                : theme.colorScheme.outline.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label: ${selectedCurrency ?? 'Any'}',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              isSelected ? Icons.close : Icons.keyboard_arrow_down,
              size: 14,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeChip(BuildContext context) {
    final theme = Theme.of(context);
    final hasDateFilter =
        widget.controller.fromDate != null || widget.controller.toDate != null;

    return GestureDetector(
      onTap: () => _showDateRangePicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: hasDateFilter
              ? theme.colorScheme.primaryContainer.withOpacity(0.5)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasDateFilter
                ? theme.colorScheme.primary.withOpacity(0.5)
                : theme.colorScheme.outline.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Date: ${_getDateRangeText()}',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: hasDateFilter
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              hasDateFilter ? Icons.close : Icons.date_range,
              size: 14,
              color: hasDateFilter
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ],
        ),
      ),
    );
  }

  void _showCurrencyPicker(
    BuildContext context,
    String label,
    String? current,
    Function(String?) onChanged,
  ) {
    final currencies = CurrencyService.supportedCodes;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.8,
          builder: (context, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Select $label Currency',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: currencies.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return ListTile(
                          title: const Text('Any Currency'),
                          selected: current == null,
                          onTap: () {
                            onChanged(null);
                            Navigator.pop(context);
                          },
                        );
                      }

                      final currency = currencies[index - 1];
                      final name =
                          CurrencyService.supportedCurrencyNames[currency] ??
                          currency;

                      return ListTile(
                        title: Text('$currency - $name'),
                        selected: currency == current,
                        onTap: () {
                          onChanged(currency);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showDateRangePicker(BuildContext context) {
    showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange:
          widget.controller.fromDate != null && widget.controller.toDate != null
          ? DateTimeRange(
              start: widget.controller.fromDate!,
              end: widget.controller.toDate!,
            )
          : null,
    ).then((range) {
      if (range != null) {
        widget.controller.setDateRangeFilter(range.start, range.end);
      } else {
        widget.controller.setDateRangeFilter(null, null);
      }
    });
  }

  String _getDateRangeText() {
    if (widget.controller.fromDate == null &&
        widget.controller.toDate == null) {
      return 'Any';
    }

    final formatter = (DateTime date) =>
        '${date.day}/${date.month}/${date.year}';

    if (widget.controller.fromDate != null &&
        widget.controller.toDate != null) {
      return '${formatter(widget.controller.fromDate!)} - ${formatter(widget.controller.toDate!)}';
    } else if (widget.controller.fromDate != null) {
      return 'From ${formatter(widget.controller.fromDate!)}';
    } else {
      return 'Until ${formatter(widget.controller.toDate!)}';
    }
  }
}
