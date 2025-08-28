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
/// ☁️ USER PROFILE DATA (Firestore):
/// - User Preferences: Default currency, app settings (Phase 8 - PreferencesService)
/// - Alert Settings: Active alerts configuration (Phase 6 - AlertsService)
///
/// NAVIGATION TARGETS BY PHASE:
/// - Phase 3: Conversion screen (market pairs, popular pairs)
/// - Phase 5: History screen (via tab navigation)
/// - Phase 6: Alerts screen (notifications, rate alerts)
/// - Phase 7: Market/News screen (view all market)
/// - Phase 8: Profile/Preferences screen (view profile)
///
/// NOTE: History/Recent Activity is now handled by HistoryController via RecentActivityWidget
class HomeController extends ChangeNotifier {
  // Tab navigation state
  int _currentTabIndex = 0;

  // Getters
  int get currentTabIndex => _currentTabIndex;

  /// Jump to specific tab (for navigation from widgets like RecentActivityWidget)
  void jumpToTab(int index) {
    _currentTabIndex = index;
    notifyListeners();
  }

  /// Initialize home data - Market and Popular data handled by their respective widgets
  Future<void> initializeHomeData() async {
    // Market Overview and Popular Pairs are now handled directly by their widgets
    // MarketOverviewWidget handles its own API calls and state management
    // PopularPairsWidget handles its own API calls and state management
    // This keeps the controller lightweight and focused on navigation
    debugPrint("Home data initialization - widgets handle their own data");
  }

  /// Refresh all data - delegated to widgets
  Future<void> refreshHomeData() async {
    // Widgets handle their own refresh logic via their internal state
    // This maintains better separation of concerns
    debugPrint("Home data refresh - widgets handle their own refresh");
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

  /// Handle market pair tap - receives data from MarketOverviewWidget
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

  /// Handle popular pair tap - receives data from PopularPairsWidget
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
}

// Data models for home screen - kept for compatibility with widget callbacks
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
