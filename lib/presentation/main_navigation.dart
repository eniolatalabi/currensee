import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../core/theme.dart';
import '../features/auth/controller/auth_controller.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/conversion/presentation/conversion_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const HomeScreen(),
      const ConversionScreen(),
      // const HistoryScreen(),
      // const HelpScreen(),
      // const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final user = authController.currentUser;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildStaticTopBar(context, user), // ✅ Global Top Bar
            Expanded(child: _screens[_currentIndex]), // ✅ Feature Content
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(), // ✅ Global Bottom Nav
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
          IconButton(
            icon: Icon(
              Icons.notifications_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            tooltip: "Notifications",
            onPressed: _handleNotificationTap,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _currentIndex,
      onTap: (index) => setState(() => _currentIndex = index),
      selectedItemColor: Theme.of(context).colorScheme.primary,
      unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 8,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
        BottomNavigationBarItem(icon: Icon(Icons.swap_horiz), label: "Convert"),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),
        BottomNavigationBarItem(icon: Icon(Icons.help_outline), label: "Help"),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: "Profile",
        ),
      ],
    );
  }

  void _handleNotificationTap() {
    // TODO: Implement NotificationPanel in Phase 6
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Notifications coming soon")));
  }
}
