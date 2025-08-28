// lib/features/history/presentation/history_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants.dart';
import '../../../data/services/currency_service.dart';
import '../controller/history_controller.dart';
import 'widgets/history_item_widget.dart';
import 'widgets/animated_stat_card.dart';
import 'widgets/search_filter_section.dart';
import 'history_detail_sheet.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

// EDITED: Added AutomaticKeepAliveClientMixin to preserve state across tab switches
class _HistoryScreenState extends State<HistoryScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  late AnimationController _animationController;

  // EDITED: Added override for wantKeepAlive
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Load history when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryController>().loadAll();
    });

    // Listen to tab changes to trigger animations
    _tabController.addListener(() {
      if (_tabController.index == 1) {
        _animationController.reset();
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // EDITED: Added super.build(context) for AutomaticKeepAliveClientMixin
    super.build(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Consumer<HistoryController>(
        builder: (context, controller, _) {
          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              _buildSliverAppBar(context, controller, innerBoxIsScrolled),
            ],
            body: Column(
              children: [
                _buildCompactTabBar(context),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildHistoryTab(context, controller),
                      _buildStatsTab(context, controller),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar(
    BuildContext context,
    HistoryController controller,
    bool innerBoxIsScrolled,
  ) {
    final theme = Theme.of(context);

    return SliverAppBar(
      title: Text(
        'History',
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurface,
        ),
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      foregroundColor: theme.colorScheme.onSurface,
      elevation: 0,
      floating: true,
      snap: true,
      actions: [
        PopupMenuButton<String>(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.more_vert,
              color: theme.colorScheme.onSurface,
              size: 20,
            ),
          ),
          onSelected: (value) => _handleMenuAction(context, value, controller),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          itemBuilder: (context) => [
            if (controller.history.isNotEmpty) ...[
              PopupMenuItem(
                value: 'export',
                child: _buildMenuItem(Icons.download, 'Export Data'),
              ),
              PopupMenuItem(
                value: 'clear',
                child: _buildMenuItem(
                  Icons.delete_sweep,
                  'Clear All',
                  isDestructive: true,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(width: 8),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: SearchFilterSection(controller: controller),
      ),
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String text, {
    bool isDestructive = false,
  }) {
    final theme = Theme.of(context);
    final color = isDestructive
        ? theme.colorScheme.error
        : theme.colorScheme.onSurface;

    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 12),
        Text(text, style: TextStyle(color: color)),
      ],
    );
  }

  Widget _buildCompactTabBar(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: TabBar(
        controller: _tabController,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2.5),
        ),
        labelColor: theme.colorScheme.primary,
        unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.7),
        labelStyle: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        dividerColor: theme.colorScheme.outline.withOpacity(0.2),
        tabs: const [
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.history, size: 16),
                SizedBox(width: 6),
                Text('History'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.analytics, size: 16),
                SizedBox(width: 6),
                Text('Stats'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(BuildContext context, HistoryController controller) {
    if (controller.isLoading) {
      return _buildLoadingState(context);
    }

    if (controller.error != null) {
      return _buildErrorState(context, controller);
    }

    if (controller.history.isEmpty) {
      return _buildEmptyState(context);
    }

    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: CustomScrollView(
        slivers: [
          const SliverPadding(padding: EdgeInsets.only(top: 8)),
          SliverList.builder(
            itemCount: controller.history.length,
            itemBuilder: (context, index) {
              final item = controller.history[index];
              return Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  index == 0 ? 8 : 4,
                  16,
                  index == controller.history.length - 1 ? 16 : 4,
                ),
                child: EnhancedHistoryItemWidget(
                  item: item,
                  onTap: () => _showHistoryDetail(context, item),
                  onDelete: () => _confirmDelete(context, controller, item),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatsTab(BuildContext context, HistoryController controller) {
    if (controller.history.isEmpty) {
      return _buildEmptyState(context);
    }

    final stats = _calculateStats(controller.history);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 8),
          _buildStatsGrid(context, stats),
          const SizedBox(height: 20),
          _buildInsightsSection(context, stats),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, Map<String, dynamic> stats) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: [
        AnimatedStatCard(
          icon: Icons.swap_horiz,
          title: 'Total Conversions',
          value: stats['total'].toString(),
          animationController: _animationController,
          delay: const Duration(milliseconds: 0),
        ),
        AnimatedStatCard(
          icon: Icons.currency_exchange,
          title: 'This Month',
          value: stats['thisMonth'].toString(),
          animationController: _animationController,
          delay: const Duration(milliseconds: 200),
        ),
        AnimatedStatCard(
          icon: Icons.trending_up,
          title: 'Avg. Amount',
          value: stats['averageAmount'],
          animationController: _animationController,
          delay: const Duration(milliseconds: 400),
        ),
        AnimatedStatCard(
          icon: Icons.star,
          title: 'Top Currency',
          value: stats['mostUsedCurrency'],
          animationController: _animationController,
          delay: const Duration(milliseconds: 600),
          isNumeric: false,
        ),
      ],
    );
  }

  Widget _buildInsightsSection(
    BuildContext context,
    Map<String, dynamic> stats,
  ) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer.withOpacity(0.3),
            theme.colorScheme.secondaryContainer.withOpacity(0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Quick Insights',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInsightItem(
            context,
            'You\'ve made ${stats['total']} conversions total',
            Icons.info_outline,
          ),
          _buildInsightItem(
            context,
            'Most active currency: ${stats['mostUsedCurrency']}',
            Icons.trending_up,
          ),
          _buildInsightItem(
            context,
            '${stats['thisMonth']} conversions this month',
            Icons.calendar_today,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightItem(BuildContext context, String text, IconData icon) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            'Loading history...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, HistoryController controller) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                color: theme.colorScheme.error,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load history',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              controller.error!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => controller.loadAll(),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.history_outlined,
                color: theme.colorScheme.onSurface.withOpacity(0.4),
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No conversions yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your conversion history will appear here\nafter you make your first conversion',
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

  void _handleMenuAction(
    BuildContext context,
    String action,
    HistoryController controller,
  ) {
    switch (action) {
      case 'export':
        _exportData(context, controller);
        break;
      case 'clear':
        _confirmClearAll(context, controller);
        break;
    }
  }

  void _showHistoryDetail(BuildContext context, item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HistoryDetailSheet(item: item),
    );
  }

  void _confirmDelete(
    BuildContext context,
    HistoryController controller,
    item,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.delete_outline,
              color: Theme.of(context).colorScheme.error,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text('Delete Conversion'),
          ],
        ),
        content: const Text('This conversion will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              controller.deleteConversion(item.id!);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmClearAll(BuildContext context, HistoryController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.warning_outlined,
              color: Theme.of(context).colorScheme.error,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text('Clear All History'),
          ],
        ),
        content: const Text(
          'All conversion history will be permanently deleted. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              controller.clearAllHistory();
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _exportData(BuildContext context, HistoryController controller) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Theme.of(context).colorScheme.onInverseSurface,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text('Export feature coming soon'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Map<String, dynamic> _calculateStats(List items) {
    final currencyCount = <String, int>{};
    double totalAmount = 0;
    int thisMonthCount = 0;
    final now = DateTime.now();

    for (final item in items) {
      currencyCount[item.baseCurrency] =
          (currencyCount[item.baseCurrency] ?? 0) + 1;
      totalAmount += item.baseAmount;

      if (item.timestamp.month == now.month &&
          item.timestamp.year == now.year) {
        thisMonthCount++;
      }
    }

    String mostUsedCurrency = 'None';
    if (currencyCount.isNotEmpty) {
      mostUsedCurrency = currencyCount.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
    }

    return {
      'total': items.length,
      'mostUsedCurrency': mostUsedCurrency,
      'averageAmount': items.isNotEmpty
          ? (totalAmount / items.length).toStringAsFixed(0)
          : '0',
      'thisMonth': thisMonthCount,
    };
  }
}
