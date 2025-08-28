// lib/features/profile/presentation/profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants.dart';
import '../../../core/app_router.dart';
import '../../../features/auth/controller/auth_controller.dart';
import '../widgets/profile_header.dart';
import '../widgets/preference_item.dart';
import 'preferences_screen.dart';
import 'faq_screen.dart';
import 'feedback_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Consumer<AuthController>(
        builder: (context, authController, _) {
          final user = authController.currentUser;

          return CustomScrollView(
            slivers: [
              // Profile Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                  child: ProfileHeader(
                    user: user,
                    onAvatarTap: user.isGuest
                        ? null
                        : () => _handleAvatarTap(context, authController),
                  ),
                ),
              ),

              // Settings Sections
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingMedium,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(context, 'Preferences'),
                      _buildPreferencesSection(context, user),

                      AppConstants.spacingLarge,

                      _buildSectionHeader(context, 'Help & Support'),
                      _buildHelpSection(context),

                      AppConstants.spacingLarge,

                      if (!user.isGuest) ...[
                        _buildSectionHeader(context, 'Account'),
                        _buildAccountSection(context, authController),
                        AppConstants.spacingLarge,
                      ],

                      _buildSectionHeader(context, 'About'),
                      _buildAboutSection(context),

                      AppConstants.spacingLarge,

                      // Log Out Button at the bottom (only for authenticated users)
                      if (!user.isGuest) ...[
                        _buildLogOutButton(context, authController),
                      ],

                      const SizedBox(height: 100), // bottom padding
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- UI Section Builders ---
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppConstants.paddingSmall,
        bottom: AppConstants.paddingSmall,
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildPreferencesSection(BuildContext context, user) {
    return _styledContainer(
      context,
      children: [
        PreferenceItem.navigation(
          title: 'Currency & Display',
          subtitle: 'Default currencies, theme settings',
          icon: Icons.settings_outlined,
          onTap: () => _navigateToPreferences(context),
        ),
        _divider(context),
        PreferenceItem.navigation(
          title: 'Notifications',
          subtitle: 'Alert preferences, push notifications',
          icon: Icons.notifications_outlined,
          onTap: () => _showComingSoon(context, 'Notification Settings'),
        ),
      ],
    );
  }

  Widget _buildHelpSection(BuildContext context) {
    return _styledContainer(
      context,
      children: [
        PreferenceItem.navigation(
          title: 'FAQ',
          subtitle: 'Frequently asked questions',
          icon: Icons.help_outline,
          onTap: () => _navigateToFAQ(context),
        ),
        _divider(context),
        PreferenceItem.navigation(
          title: 'Send Feedback',
          subtitle: 'Report issues, suggest improvements',
          icon: Icons.feedback_outlined,
          onTap: () => _navigateToFeedback(context),
        ),
        _divider(context),
        PreferenceItem.navigation(
          title: 'Live Chat',
          subtitle: 'Coming soon',
          icon: Icons.chat_outlined,
          onTap: () => _showComingSoon(context, 'Live Chat'),
          isEnabled: false,
        ),
      ],
    );
  }

  Widget _buildAccountSection(
    BuildContext context,
    AuthController authController,
  ) {
    return _styledContainer(
      context,
      children: [
        PreferenceItem.navigation(
          title: 'Account Settings',
          subtitle: 'Privacy, security, data management',
          icon: Icons.account_circle_outlined,
          onTap: () => _showComingSoon(context, 'Account Settings'),
        ),
      ],
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return _styledContainer(
      context,
      children: [
        PreferenceItem.navigation(
          title: 'Terms of Service',
          subtitle: 'Legal terms and conditions',
          icon: Icons.article_outlined,
          onTap: () => _showComingSoon(context, 'Terms of Service'),
        ),
        _divider(context),
        PreferenceItem.navigation(
          title: 'Privacy Policy',
          subtitle: 'How we handle your data',
          icon: Icons.privacy_tip_outlined,
          onTap: () => _showComingSoon(context, 'Privacy Policy'),
        ),
        _divider(context),
        PreferenceItem.navigation(
          title: 'Version',
          subtitle: '1.0.0 (Build 1)',
          icon: Icons.info_outline,
          onTap: () => _showAboutDialog(context),
        ),
      ],
    );
  }

  // EDITED: Refactored to a smaller, theme-aware Log Out button
  Widget _buildLogOutButton(
    BuildContext context,
    AuthController authController,
  ) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: authController.isLoading
            ? null
            : () => _handleLogOut(context, authController),
        icon: authController.isLoading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.primary,
                ),
              )
            : Icon(Icons.logout_rounded, size: 20),
        label: Text(authController.isLoading ? 'Logging Out...' : 'Log Out'),
        style: OutlinedButton.styleFrom(
          foregroundColor: theme.colorScheme.primary,
          side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radius),
          ),
          padding: const EdgeInsets.symmetric(
            vertical: AppConstants.paddingMedium,
          ),
        ),
      ),
    );
  }

  // --- Helpers ---
  Widget _styledContainer(
    BuildContext context, {
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.radius),
        boxShadow: AppConstants.boxShadow,
      ),
      child: Column(children: children),
    );
  }

  Widget _divider(BuildContext context) => Divider(
    height: 1,
    color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
  );

  // --- Actions ---
  // EDITED: Implemented avatar upload logic
  Future<void> _handleAvatarTap(
    BuildContext context,
    AuthController authController,
  ) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70, // Compress image
      maxWidth: 500, // Resize image
    );

    if (pickedFile != null && context.mounted) {
      final imageFile = File(pickedFile.path);
      final success = await authController.updateAvatar(imageFile);

      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Avatar updated successfully!')),
          );
        } else if (authController.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Upload failed: ${authController.errorMessage}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  void _navigateToPreferences(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PreferencesScreen(),
        settings: const RouteSettings(name: '/preferences'),
      ),
    );
  }

  void _navigateToFAQ(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const FAQScreen(),
        settings: const RouteSettings(name: '/faq'),
      ),
    );
  }

  void _navigateToFeedback(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const FeedbackScreen(),
        settings: const RouteSettings(name: '/feedback'),
      ),
    );
  }

  // EDITED: Updated to "Log Out" and theme-aware colors
  void _handleLogOut(BuildContext context, AuthController authController) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radius),
        ),
        title: Row(
          children: [
            Icon(
              Icons.logout_rounded,
              color: theme.colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text('Log Out'),
          ],
        ),
        content: const Text(
          'Are you sure you want to log out of your account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await authController.signOut(context: context);
              if (context.mounted) {
                context.go(AppRouter.authLogin);
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$feature is coming soon!')));
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AboutDialog(
        applicationName: AppConstants.appName,
        applicationVersion: '1.0.0',
        applicationIcon: Icon(
          Icons.monetization_on,
          size: 32,
          color: Theme.of(context).colorScheme.primary,
        ),
        children: const [
          Text(
            'A modern currency converter app with real-time rates, conversion history, and rate alerts.',
          ),
        ],
      ),
    );
  }
}
