// lib/presentation/main_navigation.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/constants.dart';
import '../core/theme.dart';
import '../core/navigation_controller.dart';
import '../features/auth/controller/auth_controller.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/conversion/presentation/conversion_screen.dart';
import '../features/history/presentation/history_screen.dart';
import '../features/alerts/presentation/notification_screen.dart';
import '../features/news/presentation/news_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/alerts/presentation/widget/notification_badge.dart';
import '../features/alerts/controller/notification_controller.dart';
import '../features/conversion/controller/conversion_controller.dart';
import '../features/history/controller/history_controller.dart';
import '../features/profile/controller/preferences_controller.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late final List<Widget> _screens;
  final NavigationController _navigationController =
      NavigationController.instance;

  @override
  void initState() {
    super.initState();

    _screens = const [
      HomeScreen(),
      ConversionScreen(),
      HistoryScreen(),
      NewsScreen(),
      ProfileScreen(),
    ];

    // Initialize user session and controllers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeUserSession();
      // ISSUE 2 FIX: Connect preferences and conversion controllers
      _connectPreferencesAndConversion();
    });
  }

  /// ISSUE 2 FIX: Connect PreferencesController with ConversionController for auto-convert
  void _connectPreferencesAndConversion() {
    try {
      final preferencesController = context.read<PreferencesController>();
      final conversionController = context.read<ConversionController>();

      // Set up callback from preferences to conversion controller
      preferencesController.setAutoConvertCallback((bool enabled) {
        conversionController.updateAutoConvertSetting(enabled);
        debugPrint('[MainNavigation] Auto-convert setting updated: $enabled');
      });

      // Load preferences to initialize the auto-convert setting
      preferencesController.loadPreferences();

      debugPrint('✅ Preferences and Conversion controllers connected');
    } catch (e) {
      debugPrint('❌ Error connecting controllers: $e');
    }
  }

  /// Initialize user session and set user IDs in all controllers
  void _initializeUserSession() {
    final authController = context.read<AuthController>();
    final user = authController.currentUser;

    debugPrint('=== USER SESSION INITIALIZATION ===');
    debugPrint('AuthController user: ${user?.uid}');
    debugPrint('User is guest: ${user?.isGuest}');
    debugPrint('Firebase Auth user: ${FirebaseAuth.instance.currentUser?.uid}');
    debugPrint(
      'Firebase Auth isAnonymous: ${FirebaseAuth.instance.currentUser?.isAnonymous}',
    );
    debugPrint('====================================');

    if (user != null && !user.isGuest) {
      final userId = user.uid;

      // Set user ID in all relevant controllers
      context.read<ConversionController>().setCurrentUserId(userId);
      context.read<HistoryController>().setCurrentUserId(userId);
      context.read<PreferencesController>().setCurrentUserId(userId);

      // Initialize notifications
      context.read<NotificationController>().initialize(userId);

      debugPrint('✅ User session initialized for: $userId');
    } else {
      debugPrint('❌ Skipping session initialization - no valid user');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final user = authController.currentUser;

    return ChangeNotifierProvider.value(
      value: _navigationController,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              _buildStaticTopBar(context, user),
              Expanded(
                child: Consumer<NavigationController>(
                  builder: (context, navController, _) =>
                      _screens[navController.currentIndex],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }

  Widget _buildStaticTopBar(BuildContext context, user) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingMedium,
        vertical: AppConstants.paddingSmall,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
            Colors.transparent,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          AppTheme.logo(size: 32),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              "CurrenSee",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
                color: const Color(0xFF2196F3),
              ),
            ),
          ),
          NotificationBadgeIcon(
            iconColor: Theme.of(context).colorScheme.primary,
            onTap: _handleNotificationTap,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Consumer<NavigationController>(
      builder: (context, navController, _) {
        return BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: navController.currentIndex,
          onTap: (index) => navController.navigateToTab(index),
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 8,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.swap_horiz_outlined),
              activeIcon: Icon(Icons.swap_horiz),
              label: "Convert",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_outlined),
              activeIcon: Icon(Icons.history),
              label: "History",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.article_outlined),
              activeIcon: Icon(Icons.article),
              label: "News",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: "Profile",
            ),
          ],
        );
      },
    );
  }

  void _handleNotificationTap() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const NotificationsScreen(),
        settings: const RouteSettings(name: '/notifications'),
      ),
    );
  }
}
