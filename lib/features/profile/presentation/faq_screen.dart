// lib/features/profile/presentation/faq_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants.dart';
import '../widgets/faq_item.dart';
import '../controller/faq_controller.dart';

class FAQScreen extends StatefulWidget {
  const FAQScreen({super.key});

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  late FAQController _faqController;
  late TextEditingController _searchController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _faqController = FAQController();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _faqController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('FAQ'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'expand_all':
                  _faqController.expandAll();
                  break;
                case 'collapse_all':
                  _faqController.collapseAll();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'expand_all',
                child: Row(
                  children: [
                    Icon(Icons.expand_more),
                    SizedBox(width: 8),
                    Text('Expand All'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'collapse_all',
                child: Row(
                  children: [
                    Icon(Icons.expand_less),
                    SizedBox(width: 8),
                    Text('Collapse All'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: ChangeNotifierProvider.value(
        value: _faqController,
        child: Consumer<FAQController>(
          builder: (context, controller, _) {
            final displayedFAQs = _searchQuery.isEmpty
                ? controller.faqItems
                : controller.searchFAQ(_searchQuery);

            return CustomScrollView(
              slivers: [
                // Header section with search
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.paddingMedium),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Frequently Asked Questions',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Find answers to common questions about CurrenSee',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        AppConstants.spacingMedium,
                        _buildSearchBar(theme),
                        AppConstants.spacingMedium,
                        _buildStatsRow(theme, controller, displayedFAQs),
                      ],
                    ),
                  ),
                ),

                // FAQ List
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.paddingMedium,
                    ),
                    child: displayedFAQs.isEmpty
                        ? _buildEmptyState(theme)
                        : Column(
                            children: displayedFAQs.asMap().entries.map((
                              entry,
                            ) {
                              final index = entry.key;
                              final originalIndex = controller.faqItems.indexOf(
                                entry.value,
                              );
                              final faqItem = entry.value;

                              return FAQItemWidget(
                                faqItem: faqItem,
                                index: index,
                                onTap: () =>
                                    controller.toggleExpansion(originalIndex),
                              );
                            }).toList(),
                          ),
                  ),
                ),

                // Bottom padding
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppConstants.radius),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Search FAQ...',
          hintStyle: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
          prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                  icon: Icon(
                    Icons.clear,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingMedium,
            vertical: AppConstants.paddingMedium,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(
    ThemeData theme,
    FAQController controller,
    List<dynamic> displayedFAQs,
  ) {
    return Row(
      children: [
        _buildStatChip(
          theme,
          '${displayedFAQs.length} Questions',
          Icons.help_outline,
        ),
        const SizedBox(width: 8),
        if (_searchQuery.isEmpty)
          _buildStatChip(
            theme,
            '${controller.expandedFAQs} Expanded',
            Icons.expand_more,
          ),
      ],
    );
  }

  Widget _buildStatChip(ThemeData theme, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.4),
          ),
          AppConstants.spacingMedium,
          Text(
            'No results found',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try different keywords or browse all questions',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          AppConstants.spacingMedium,
          TextButton.icon(
            onPressed: () {
              _searchController.clear();
              setState(() => _searchQuery = '');
            },
            icon: const Icon(Icons.clear_all),
            label: const Text('Clear Search'),
          ),
        ],
      ),
    );
  }
}
