import 'package:flutter/foundation.dart';

/// HomeController handles all business logic for the Home screen
/// Following our Phase structure and separation of concerns
///
/// DATA SOURCES & PHASE DEPENDENCIES:
///
/// 📊 API-GENERATED DATA (External APIs):
/// - Market Overview: Real-time exchange rates (Phase 3 - CurrencyService)
/// - Popular Pairs: Current rates + currency metadata (Phase 3 - CurrencyService)
///
/// 💾 USER-GENERATED DATA (Local Storage):
/// - Recent Activity: Conversion history from SQLite (Phase 5 - HistoryService)
/// - Alert History: Triggered alerts from SQLite (Phase 6 - AlertsService)
///
/// ☁️ USER PROFILE DATA (Firestore):
/// - User Preferences: Default currency, app settings (Phase 8 - PreferencesService)
/// - Alert Settings: Active alerts configuration (Phase 6 - AlertsService)
///
/// NAVIGATION TARGETS BY PHASE:
/// - Phase 3: Conversion screen (market pairs, popular pairs)
/// - Phase 5: History screen (recent activity, view all history)
/// - Phase 6: Alerts screen (notifications, rate alerts)
/// - Phase 7: Market/News screen (view all market)
/// - Phase 8: Profile/Preferences screen (view profile)
class HomeController extends ChangeNotifier {
  // Market data state
  List<MarketPair> _marketPairs = [];
  bool _isLoadingMarket = false;
  String? _marketError;

  // Popular pairs state
  List<PopularPair> _popularPairs = [];
  bool _isLoadingPopular = false;

  // Recent activity state
  List<RecentActivity> _recentActivities = [];
  bool _isLoadingActivities = false;

  // Getters
  List<MarketPair> get marketPairs => _marketPairs;
  bool get isLoadingMarket => _isLoadingMarket;
  String? get marketError => _marketError;

  List<PopularPair> get popularPairs => _popularPairs;
  bool get isLoadingPopular => _isLoadingPopular;

  List<RecentActivity> get recentActivities => _recentActivities;
  bool get isLoadingActivities => _isLoadingActivities;

  // Initialize home data
  Future<void> initializeHomeData() async {
    await Future.wait([
      _loadMarketOverview(),
      _loadPopularPairs(),
      _loadRecentActivity(),
    ]);
  }

  // Refresh all data
  Future<void> refreshHomeData() async {
    await initializeHomeData();
  }

  /// Load market overview data (Phase 3)
  Future<void> _loadMarketOverview() async {
    _isLoadingMarket = true;
    _marketError = null;
    notifyListeners();

    try {
      // TODO: PHASE 3 - Replace with actual CurrencyService.getMarketOverview()
      // Should fetch real-time exchange rates from API (ExchangeRate-API, Fixer.io, etc.)
      // This data is API-GENERATED and should include:
      // - Current rates for major NGN pairs (USD/NGN, GBP/NGN, EUR/NGN)
      // - 24h change percentage and direction
      // - Last updated timestamp
      // Example: final rates = await _currencyService.getMarketOverview(['USD', 'GBP'], 'NGN');
      await Future.delayed(
        const Duration(milliseconds: 800),
      ); // Remove this mock delay

      _marketPairs = [
        MarketPair(
          pair: "USD/NGN",
          rate: "₦1,650.50",
          change: "+2.3%",
          isPositive: true,
        ),
        MarketPair(
          pair: "GBP/NGN",
          rate: "₦2,089.75",
          change: "-0.8%",
          isPositive: false,
        ),
      ];
    } catch (e) {
      _marketError = "Failed to load market data";
      debugPrint("Market data error: $e");
    } finally {
      _isLoadingMarket = false;
      notifyListeners();
    }
  }

  /// Load popular currency pairs (Phase 3)
  Future<void> _loadPopularPairs() async {
    _isLoadingPopular = true;
    notifyListeners();

    try {
      // TODO: PHASE 3 - Replace with actual CurrencyService.getPopularPairs()
      // Should fetch from CurrencyService which provides:
      // - List of supported currencies with metadata
      // - Current exchange rates for popular pairs
      // - User's preferred/recently used currencies (from Phase 8 preferences)
      // This combines API-GENERATED rates + USER PREFERENCE data
      // Example: final pairs = await _currencyService.getPopularPairs(baseCurrency: 'NGN', limit: 4);
      await Future.delayed(
        const Duration(milliseconds: 600),
      ); // Remove this mock delay

      _popularPairs = [
        PopularPair(from: "USD", to: "NGN", rate: "1,650.50"),
        PopularPair(from: "GBP", to: "NGN", rate: "2,089.75"),
        PopularPair(from: "EUR", to: "NGN", rate: "1,789.25"),
        PopularPair(from: "CAD", to: "NGN", rate: "1,210.80"),
      ];
    } catch (e) {
      debugPrint("Popular pairs error: $e");
    } finally {
      _isLoadingPopular = false;
      notifyListeners();
    }
  }

  /// Load recent activity (Phase 5)
  Future<void> _loadRecentActivity() async {
    _isLoadingActivities = true;
    notifyListeners();

    try {
      // TODO: PHASE 5 - Replace with actual HistoryService.getRecentActivity()
      // This is USER-GENERATED data from SQLite local database
      // Should fetch from LocalDbService/HistoryService:
      // - Recent conversions (last 5-10 items)
      // - Recent rate alerts triggered (from Phase 6)
      // - Sort by timestamp descending
      // Example: final activities = await _historyService.getRecentActivities(limit: 5);
      //
      // PHASE 6 DEPENDENCY: Rate alerts data will come from AlertsService
      // For now, only show conversion history until Phase 6 is implemented
      await Future.delayed(
        const Duration(milliseconds: 400),
      ); // Remove this mock delay

      _recentActivities = [
        RecentActivity(
          type: ActivityType.conversion,
          title: "USD to NGN",
          amount: "₦825,000",
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        RecentActivity(
          type: ActivityType.conversion,
          title: "GBP to NGN",
          amount: "₦156,750",
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
        ),
        // TODO: PHASE 6 - This alert type will be available after alerts implementation
        RecentActivity(
          type: ActivityType.alert,
          title: "Rate Alert",
          amount: "USD/NGN reached ₦1,650",
          timestamp: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ];
    } catch (e) {
      debugPrint("Recent activity error: $e");
    } finally {
      _isLoadingActivities = false;
      notifyListeners();
    }
  }

  /// Get appropriate greeting based on time
  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "morning";
    if (hour < 17) return "afternoon";
    return "evening";
  }

  /// Handle notification icon tap
  void onNotificationTap() {
    // TODO: PHASE 6 - Navigate to notifications/alerts screen
    // Will navigate to AlertsScreen showing:
    // - Active rate alerts
    // - Alert history/notifications
    // - Alert settings
    // Example: Navigator.pushNamed(context, '/alerts');
    debugPrint("Notification tapped - navigate to alerts");
  }

  /// Handle view profile tap
  void onViewProfileTap() {
    // TODO: PHASE 8 - Navigate to profile/preferences screen
    // Will navigate to ProfileScreen/PreferencesScreen showing:
    // - User profile info (name, email)
    // - App preferences (default currency, theme, etc.)
    // - Account settings
    // Example: Navigator.pushNamed(context, '/profile');
    debugPrint("View profile tapped");
  }

  /// Handle market pair tap
  void onMarketPairTap(MarketPair pair) {
    // TODO: PHASE 3 - Navigate to conversion screen with pre-filled data
    // Should navigate to ConversionScreen with:
    // - Base currency = first part of pair (e.g., USD from USD/NGN)
    // - Target currency = second part of pair (e.g., NGN from USD/NGN)
    // - Current rate pre-populated
    // Example: Navigator.pushNamed(context, '/conversion', arguments: ConversionArgs(
    //   baseCurrency: pair.pair.split('/')[0],
    //   targetCurrency: pair.pair.split('/')[1],
    // ));
    debugPrint("Market pair tapped: ${pair.pair}");
  }

  /// Handle popular pair tap
  void onPopularPairTap(PopularPair pair) {
    // TODO: PHASE 3 - Navigate to conversion screen with pre-filled currencies
    // Same as onMarketPairTap but with PopularPair data structure
    // Should pre-fill conversion screen with selected currency pair
    // Example: Navigator.pushNamed(context, '/conversion', arguments: ConversionArgs(
    //   baseCurrency: pair.from,
    //   targetCurrency: pair.to,
    // ));
    debugPrint("Popular pair tapped: ${pair.from}/${pair.to}");
  }

  /// Handle recent activity tap
  void onRecentActivityTap(RecentActivity activity) {
    // TODO: PHASE 5 - Navigate to activity details or history screen
    // Behavior depends on activity type:
    // - For conversions: Navigate to ConversionDetailScreen or HistoryScreen
    // - For alerts (Phase 6): Navigate to AlertDetailScreen
    // Example:
    // if (activity.type == ActivityType.conversion) {
    //   Navigator.pushNamed(context, '/history', arguments: activity.id);
    // } else if (activity.type == ActivityType.alert) {
    //   Navigator.pushNamed(context, '/alerts', arguments: activity.id);
    // }
    debugPrint("Recent activity tapped: ${activity.title}");
  }

  /// Handle view all market tap
  void onViewAllMarketTap() {
    // TODO: PHASE 7 - Navigate to full market overview screen
    // Will show comprehensive market data:
    // - Extended currency pairs list
    // - Market trends and charts
    // - News feed integration
    // This might be part of a dedicated MarketScreen or NewsScreen
    // Example: Navigator.pushNamed(context, '/market');
    debugPrint("View all market tapped");
  }

  /// Handle view all history tap
  void onViewAllHistoryTap() {
    // TODO: PHASE 5 - Navigate to full conversion history screen
    // Will navigate to HistoryScreen showing:
    // - Complete conversion history
    // - Search and filter options
    // - Export functionality
    // - Detailed view for each conversion
    // Example: Navigator.pushNamed(context, '/history');
    debugPrint("View all history tapped");
  }
}

// Data models for home screen
class MarketPair {
  final String pair;
  final String rate;
  final String change;
  final bool isPositive;

  MarketPair({
    required this.pair,
    required this.rate,
    required this.change,
    required this.isPositive,
  });
}

class PopularPair {
  final String from;
  final String to;
  final String rate;

  PopularPair({required this.from, required this.to, required this.rate});
}

class RecentActivity {
  final ActivityType type;
  final String title;
  final String amount;
  final DateTime timestamp;

  RecentActivity({
    required this.type,
    required this.title,
    required this.amount,
    required this.timestamp,
  });

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return "${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago";
    } else if (difference.inHours > 0) {
      return "${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago";
    } else {
      return "Just now";
    }
  }
}

enum ActivityType { conversion, alert, notification }
