// lib/features/news/presentation/widgets/Phase7 — market_chart.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/constants.dart';
import '../../../../core/theme.dart';
import '../../../../data/models/market_trend_model.dart';

class MarketChart extends StatelessWidget {
  final MarketTrend trend;
  final double height;
  final bool showTitle;
  final bool isSparkline;

  const MarketChart({
    super.key,
    required this.trend,
    this.height = 200,
    this.showTitle = true,
    this.isSparkline = false,
  });

  @override
  Widget build(BuildContext context) {
    if (trend.points.isEmpty) {
      return _buildEmptyChart(context);
    }

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.radius),
        boxShadow: isSparkline ? [] : AppConstants.boxShadow,
      ),
      child: Padding(
        padding: EdgeInsets.all(isSparkline ? 8 : AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showTitle && !isSparkline) _buildHeader(context),
            if (showTitle && !isSparkline) AppConstants.spacingSmall,
            Expanded(child: _buildChart(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          trend.symbol,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              trend.lastPrice.toStringAsFixed(4),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              '${trend.isPositive ? '+' : ''}${trend.changePercent.toStringAsFixed(2)}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: trend.isPositive
                    ? AppTheme.successColor
                    : AppTheme.errorColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChart(BuildContext context) {
    final spots = _createSpots();
    final lineColor = trend.isPositive
        ? AppTheme.successColor
        : AppTheme.errorColor;
    final gradientColors = [
      lineColor.withValues(alpha: 0.3),
      lineColor.withValues(alpha: 0.05),
    ];

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: !isSparkline,
          drawVerticalLine: false,
          horizontalInterval: _calculateHorizontalInterval(),
          getDrawingHorizontalLine: (value) => FlLine(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          show: !isSparkline,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) => Text(
                value.toStringAsFixed(3),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: _calculateBottomInterval(),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < trend.points.length) {
                  final point = trend.points[index];
                  return Text(
                    _formatDateLabel(point.timestamp),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: lineColor,
            barWidth: isSparkline ? 1.5 : 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: isSparkline ? false : spots.length <= 20,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(
                    radius: 3,
                    color: lineColor,
                    strokeWidth: 0,
                  ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          enabled: !isSparkline,
          touchTooltipData: LineTouchTooltipData(
            tooltipRoundedRadius: 8,
            tooltipPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final index = spot.x.toInt();
                if (index >= 0 && index < trend.points.length) {
                  final point = trend.points[index];
                  return LineTooltipItem(
                    '${point.value.toStringAsFixed(4)}\n${_formatTooltipDate(point.timestamp)}',
                    Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }
                return null;
              }).toList();
            },
          ),
        ),
      ),
      duration: AppConstants.normalAnim,
      curve: Curves.easeInOut,
    );
  }

  Widget _buildEmptyChart(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.radius),
        boxShadow: isSparkline ? [] : AppConstants.boxShadow,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart,
              size: 48,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.3),
            ),
            AppConstants.spacingSmall,
            Text(
              'No data available',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _createSpots() {
    return trend.points.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value);
    }).toList();
  }

  double _calculateHorizontalInterval() {
    if (trend.points.isEmpty) return 1.0;

    final values = trend.points.map((p) => p.value).toList();
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final range = max - min;

    return range / 4; // Show ~4 horizontal grid lines
  }

  double _calculateBottomInterval() {
    final pointCount = trend.points.length;
    if (pointCount <= 7) return 1.0;
    if (pointCount <= 30) return (pointCount / 5).ceilToDouble();
    return (pointCount / 6).ceilToDouble();
  }

  String _formatDateLabel(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference < 1) {
      return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference < 7) {
      return ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][date.weekday %
          7];
    } else {
      return '${date.month}/${date.day}';
    }
  }

  String _formatTooltipDate(DateTime date) {
    return '${date.month}/${date.day} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
