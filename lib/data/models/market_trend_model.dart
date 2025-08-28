// lib/data/models/market_trend_model.dart
class MarketPoint {
  final DateTime timestamp;
  final double value;

  const MarketPoint({required this.timestamp, required this.value});

  factory MarketPoint.fromJson(Map<String, dynamic> json) {
    return MarketPoint(
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      value: (json['value'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'timestamp': timestamp.toIso8601String(), 'value': value};
  }
}

class MarketTrend {
  final String symbol;
  final List<MarketPoint> points;
  final int timeframeDays;
  final double changePercent;
  final double lastPrice;

  const MarketTrend({
    required this.symbol,
    required this.points,
    required this.timeframeDays,
    required this.changePercent,
    required this.lastPrice,
  });

  factory MarketTrend.fromJson(Map<String, dynamic> json) {
    final pointsList =
        (json['points'] as List?)
            ?.map((p) => MarketPoint.fromJson(p))
            .toList() ??
        <MarketPoint>[];

    return MarketTrend(
      symbol: json['symbol'] ?? '',
      points: pointsList,
      timeframeDays: json['timeframeDays'] ?? 7,
      changePercent: (json['changePercent'] ?? 0).toDouble(),
      lastPrice: (json['lastPrice'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'points': points.map((p) => p.toJson()).toList(),
      'timeframeDays': timeframeDays,
      'changePercent': changePercent,
      'lastPrice': lastPrice,
    };
  }

  bool get isPositive => changePercent >= 0;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MarketTrend && other.symbol == symbol;
  }

  @override
  int get hashCode => symbol.hashCode;
}
