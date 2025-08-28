// lib/features/news/controller/news_controller.dart
import 'package:flutter/material.dart';
import '../../../core/config.dart';
import '../../../data/services/market_service.dart';
import '../../../data/models/news_model.dart';
import '../../../data/models/market_trend_model.dart';

class NewsController with ChangeNotifier {
  final MarketService _service;

  List<NewsArticle> headlines = [];
  List<MarketTrend> trends = [];
  bool isLoading = false;
  String? error;
  int page = 1;
  bool hasMore = true;

  NewsController(this._service);

  /// Load initial news and trends data
  Future<void> loadInitial() async {
    if (isLoading) return;

    _setLoading(true);
    _clearError();

    if (AppConfig.logApiRequests) {
      print('NewsController: Loading initial data...');
    }

    try {
      // Load news first
      final newsResult = await _service.getMarketNews(page: 1, pageSize: 20);
      headlines = newsResult;
      page = 1;
      hasMore = newsResult.length >= 20;

      if (AppConfig.logApiRequests) {
        print('NewsController: Loaded ${headlines.length} news articles');
      }

      // Then load trends for popular pairs
      await _loadTrendsForPopularPairs();

      if (AppConfig.logApiRequests) {
        print('NewsController: Loaded ${trends.length} market trends');
      }
    } catch (e) {
      final errorMessage = 'Failed to load data: ${e.toString()}';
      _setError(errorMessage);

      if (AppConfig.logApiRequests) {
        print('NewsController Error: $errorMessage');
      }

      // Even if there's an error, try to load some mock data so the UI isn't empty
      try {
        headlines = await _service.getMarketNews(page: 1, pageSize: 10);
        trends = [
          await _loadSingleTrend('EURUSD', 7),
        ].where((t) => t != null).cast<MarketTrend>().toList();
      } catch (fallbackError) {
        if (AppConfig.logApiRequests) {
          print('NewsController: Even fallback failed: $fallbackError');
        }
      }
    } finally {
      _setLoading(false);
    }
  }

  /// Load trends for popular currency pairs
  Future<void> _loadTrendsForPopularPairs() async {
    trends.clear();

    for (final symbol in popularPairs) {
      try {
        final trend = await _loadSingleTrend(symbol, 7);
        if (trend != null) {
          trends.add(trend);
        }
      } catch (e) {
        if (AppConfig.logApiRequests) {
          print('NewsController: Failed to load trend for $symbol: $e');
        }
        // Continue with other symbols even if one fails
      }
    }
  }

  /// Load a single market trend
  Future<MarketTrend?> _loadSingleTrend(String symbol, int days) async {
    try {
      final trendResults = await _service.getMarketTrends(
        symbol: symbol,
        days: days,
      );
      return trendResults.isNotEmpty ? trendResults.first : null;
    } catch (e) {
      if (AppConfig.logApiRequests) {
        print('NewsController: Failed to load trend for $symbol: $e');
      }
      return null;
    }
  }

  /// Load more news articles (pagination)
  Future<void> loadMore() async {
    if (isLoading || !hasMore) return;

    _setLoading(true);
    _clearError();

    if (AppConfig.logApiRequests) {
      print('NewsController: Loading more articles, page ${page + 1}...');
    }

    try {
      final nextPage = page + 1;
      final newArticles = await _service.getMarketNews(
        page: nextPage,
        pageSize: 20,
      );

      if (newArticles.isNotEmpty) {
        // Filter out duplicates
        final existingIds = headlines.map((a) => a.id).toSet();
        final uniqueNewArticles = newArticles
            .where((a) => !existingIds.contains(a.id))
            .toList();

        headlines.addAll(uniqueNewArticles);
        page = nextPage;
        hasMore = newArticles.length >= 20;

        if (AppConfig.logApiRequests) {
          print(
            'NewsController: Loaded ${uniqueNewArticles.length} new articles (${newArticles.length} total returned)',
          );
        }
      } else {
        hasMore = false;
        if (AppConfig.logApiRequests) {
          print('NewsController: No more articles available');
        }
      }
    } catch (e) {
      final errorMessage = 'Failed to load more news: ${e.toString()}';
      _setError(errorMessage);

      if (AppConfig.logApiRequests) {
        print('NewsController Error: $errorMessage');
      }
    } finally {
      _setLoading(false);
    }
  }

  /// Refresh all data
  Future<void> refresh() async {
    if (AppConfig.logApiRequests) {
      print('NewsController: Refreshing all data...');
    }

    // Clear cache to ensure fresh data
    _service.clearCache();

    page = 1;
    hasMore = true;
    headlines.clear();
    trends.clear();

    // Notify listeners immediately to show loading state
    notifyListeners();

    await loadInitial();
  }

  /// Load chart data for a specific symbol and timeframe
  Future<List<MarketTrend>> loadChartData(String symbol, int days) async {
    if (AppConfig.logApiRequests) {
      print('NewsController: Loading chart data for $symbol, $days days...');
    }

    try {
      final results = await _service.getMarketTrends(
        symbol: symbol,
        days: days,
      );

      if (AppConfig.logApiRequests) {
        print(
          'NewsController: Chart data loaded for $symbol: ${results.length} trends',
        );
      }

      return results;
    } catch (e) {
      if (AppConfig.logApiRequests) {
        print('NewsController: Failed to load chart data for $symbol: $e');
      }
      return [];
    }
  }

  /// Search for news with a specific query
  Future<void> searchNews(String query) async {
    if (isLoading) return;

    _setLoading(true);
    _clearError();

    headlines.clear();
    page = 1;
    hasMore = true;

    if (AppConfig.logApiRequests) {
      print('NewsController: Searching news for: "$query"');
    }

    try {
      final results = await _service.getMarketNews(
        query: query,
        page: 1,
        pageSize: 20,
      );

      headlines = results;
      hasMore = results.length >= 20;

      if (AppConfig.logApiRequests) {
        print(
          'NewsController: Found ${headlines.length} articles for "$query"',
        );
      }
    } catch (e) {
      final errorMessage = 'Failed to search news: ${e.toString()}';
      _setError(errorMessage);

      if (AppConfig.logApiRequests) {
        print('NewsController Error: $errorMessage');
      }
    } finally {
      _setLoading(false);
    }
  }

  /// Get popular currency pairs for highlights
  List<String> get popularPairs => ['EURUSD', 'GBPUSD', 'USDJPY', 'AUDUSD'];

  /// Get trending symbols from current news
  List<String> get trendingSymbols {
    final symbols = <String>{};
    for (final article in headlines.take(10)) {
      symbols.addAll(article.symbols);
    }
    return symbols.toList();
  }

  /// Get current data status for debugging
  Map<String, dynamic> get debugStatus => {
    'headlines_count': headlines.length,
    'trends_count': trends.length,
    'current_page': page,
    'has_more': hasMore,
    'is_loading': isLoading,
    'error': error,
    'cache_status': _service.getCacheStatus(),
  };

  /// Quick API test method
  Future<void> testAPIs() async {
    print('=== TESTING APIs ===');

    // Test News API
    try {
      print('Testing NewsAPI...');
      final news = await _service.getMarketNews(page: 1, pageSize: 5);
      print('✅ NewsAPI Success: ${news.length} articles loaded');
      if (news.isNotEmpty) {
        print('   First article: ${news.first.title}');
      }
    } catch (e) {
      print('❌ NewsAPI Failed: $e');
    }

    // Test Market API
    try {
      print('Testing Market API...');
      final trends = await _service.getMarketTrends(symbol: 'EURUSD', days: 7);
      print('✅ Market API Success: ${trends.length} trends loaded');
      if (trends.isNotEmpty) {
        print('   EURUSD rate: ${trends.first.lastPrice}');
      }
    } catch (e) {
      print('❌ Market API Failed: $e');
    }

    print('=== TEST COMPLETE ===');
  }

  /// Check if we have any data at all
  bool get hasAnyData => headlines.isNotEmpty || trends.isNotEmpty;

  /// Check if we should show empty state
  bool get shouldShowEmptyState =>
      !isLoading && headlines.isEmpty && error == null;

  /// Check if we should show error state
  bool get shouldShowErrorState =>
      !isLoading && headlines.isEmpty && error != null;

  void _setLoading(bool loading) {
    if (isLoading != loading) {
      isLoading = loading;
      notifyListeners();
    }
  }

  void _setError(String? errorMessage) {
    if (error != errorMessage) {
      error = errorMessage;
      notifyListeners();
    }
  }

  void _clearError() {
    _setError(null);
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}
