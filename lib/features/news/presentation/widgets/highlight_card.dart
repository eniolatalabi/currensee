import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants.dart';
import '../../../../core/theme.dart';
import '../../../../data/models/market_trend_model.dart';
import '../../controller/news_controller.dart';
import '../widgets/market_chart.dart';

class HighlightCard extends StatefulWidget {
  final String symbol;

  const HighlightCard({
    super.key,
    required this.symbol,
  });

  @override
  State<HighlightCard> createState() => _HighlightCardState();
}

class _HighlightCardState extends State<HighlightCard> {
  MarketTrend? _trend;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrendData();
  }

  Future<void> _loadTrendData() async {
    try {
      final controller = context.read<NewsController>();
      final trends = await controller.loadChartData(widget.symbol, 7);
      
      if (mounted && trends.isNotEmpty) {
        setState(() {
          _trend = trends.first;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.radius),
        boxShadow: AppConstants.boxShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: _isLoading ? _buildLoadingState() : _buildContent(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Symbol placeholder
        Container(
          width: 60,
          height: 16,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        AppConstants.spacingSmall,
        
        // Price placeholders
        Container(
          width: 80,
          height: 20,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 50,
          height: 14,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        
        AppConstants.spacingSmall,
        
        // Chart placeholder
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_trend == null) {
      return _buildErrorState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Symbol and price info
        Text(
          widget.symbol,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        AppConstants.spacingSmall,
        
        Text(
          _trend!.lastPrice.toStringAsFixed(4),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        
        Row(
          children: [
            Icon(
              _trend!.isPositive ? Icons.trending_up : Icons.trending_down,
              size: 14,
              color: _trend!.isPositive ? AppTheme.successColor : AppTheme.errorColor,
            ),
            const SizedBox(width: 4),
            Text(
              '${_trend!.isPositive ? '+' : ''}${_trend!.changePercent.toStringAsFixed(2)}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: _trend!.isPositive ? AppTheme.successColor : AppTheme.errorColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        
        AppConstants.spacingSmall,
        
        // Mini sparkline chart
        Expanded(
          child: MarketChart(
            trend: _trend!,
            showTitle: false,
            isSparkline: true,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.symbol,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 24,
                  color: Theme.of(context).colorScheme.error.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 4),
                Text(
                  'No data',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}