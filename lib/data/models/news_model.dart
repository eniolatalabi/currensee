// lib/data/models/Phase7 — news_model.dart
class NewsArticle {
  final String id;
  final String title;
  final String sourceName;
  final String url;
  final String? imageUrl;
  final String excerpt;
  final DateTime publishedAt;
  final List<String> symbols;

  const NewsArticle({
    required this.id,
    required this.title,
    required this.sourceName,
    required this.url,
    this.imageUrl,
    required this.excerpt,
    required this.publishedAt,
    this.symbols = const [],
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      id:
          json['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title'] ?? '',
      sourceName: json['source']?['name'] ?? json['sourceName'] ?? 'Unknown',
      url: json['url'] ?? '',
      imageUrl: json['urlToImage'] ?? json['imageUrl'],
      excerpt: json['description'] ?? json['excerpt'] ?? '',
      publishedAt:
          DateTime.tryParse(json['publishedAt'] ?? '') ?? DateTime.now(),
      symbols: (json['symbols'] as List?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'sourceName': sourceName,
      'url': url,
      'imageUrl': imageUrl,
      'excerpt': excerpt,
      'publishedAt': publishedAt.toIso8601String(),
      'symbols': symbols,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NewsArticle && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
