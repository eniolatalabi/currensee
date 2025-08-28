// lib/features/news/presentation/news_screen.dart - FIXED with API testing
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants.dart';
import '../../../core/theme.dart';
import '../controller/news_controller.dart';
import '../presentation/widgets/news_item_widget.dart';
import '../presentation/widgets/highlight_card.dart';
import '../presentation/widgets/market_chart.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final ScrollController _scrollController = ScrollController();
  int _selectedTimeframe = 7; // 7, 30, or 90 days

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Load initial data with API testing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<NewsController>();
      controller.testAPIs(); // Test APIs first
      controller.loadInitial(); // Then load data
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<NewsController>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => context.read<NewsController>().refresh(),
        child: Consumer<NewsController>(
          builder: (context, controller, child) {
            // Use regular scrollable instead of CustomScrollView to avoid sliver conflicts
            return SingleChildScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header section with highlights
                  Padding(
                    padding: const EdgeInsets.all(AppConstants.paddingMedium),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Market Highlights',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: AppConstants.paddingMedium),
                        _buildHighlights(controller),
                      ],
                    ),
                  ),

                  // Chart section
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.paddingMedium,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'EUR/USD Trend',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            _buildTimeframeSelector(),
                          ],
                        ),
                        const SizedBox(height: AppConstants.paddingSmall),
                        _buildChart(controller),
                        const SizedBox(height: AppConstants.paddingLarge),
                      ],
                    ),
                  ),

                  // News section header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.paddingMedium,
                    ),
                    child: Text(
                      'Latest News',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),

                  // Content based on state
                  _buildContent(controller),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(NewsController controller) {
    // Error state
    if (controller.error != null && controller.headlines.isEmpty) {
      return _buildErrorState(controller);
    }

    // Loading state
    if (controller.isLoading && controller.headlines.isEmpty) {
      return const _LoadingSkeleton();
    }

    // News list
    if (controller.headlines.isNotEmpty) {
      return Column(
        children: [
          // News items
          ...controller.headlines.map(
            (article) => NewsItemWidget(article: article),
          ),

          // Load more indicator
          if (controller.hasMore)
            const Padding(
              padding: EdgeInsets.all(AppConstants.paddingMedium),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      );
    }

    // Empty state
    return _buildEmptyState();
  }

  Widget _buildHighlights(NewsController controller) {
    if (controller.trends.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: controller.popularPairs.length,
        itemBuilder: (context, index) {
          final symbol = controller.popularPairs[index];
          return HighlightCard(symbol: symbol);
        },
      ),
    );
  }

  Widget _buildTimeframeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppConstants.radius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [7, 30, 90].map((days) {
          final isSelected = _selectedTimeframe == days;
          return GestureDetector(
            onTap: () => setState(() => _selectedTimeframe = days),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                borderRadius: BorderRadius.circular(AppConstants.radius),
              ),
              child: Text(
                '${days}D',
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : Theme.of(context).textTheme.bodyMedium?.color,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChart(NewsController controller) {
    if (controller.trends.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppConstants.radius),
          boxShadow: AppConstants.boxShadow,
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return MarketChart(trend: controller.trends.first, height: 200);
  }

  Widget _buildErrorState(NewsController controller) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppTheme.errorColor.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          Text(
            'Failed to load news',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppConstants.paddingSmall),
          Text(
            controller.error ?? 'Unknown error occurred',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          ElevatedButton(
            onPressed: () => controller.refresh(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.article_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          Text(
            'No news available',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppConstants.paddingSmall),
          Text(
            'Pull to refresh and try again',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(5, (index) {
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingMedium,
            vertical: AppConstants.paddingSmall,
          ),
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(AppConstants.radius),
            ),
          ),
        );
      }),
    );
  }
}
