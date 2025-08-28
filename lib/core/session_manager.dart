// lib/core/user_session_manager.dart
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../features/profile/controller/preferences_controller.dart';
import '../features/conversion/controller/conversion_controller.dart';
import '../features/alerts/controller/notification_controller.dart';
import '../data/services/notification_service.dart';

class UserSessionManager {
  static UserSessionManager? _instance;
  static UserSessionManager get instance {
    _instance ??= UserSessionManager._internal();
    return _instance!;
  }

  UserSessionManager._internal();

  String? _currentUserId;
  String? get currentUserId => _currentUserId;

  /// Set the current user ID and update all relevant controllers
  Future<void> setCurrentUser(String userId, context) async {
    if (_currentUserId == userId) return; // No change needed

    _currentUserId = userId;

    try {
      // Get controllers from context
      final preferencesController = context.read<PreferencesController>();
      final conversionController = context.read<ConversionController>();
      final notificationController = context.read<NotificationController>();

      // Set user ID in all controllers
      preferencesController.setCurrentUserId(userId);
      conversionController.setCurrentUserId(userId);

      // Initialize notifications for the user
      await notificationController.initialize(userId);

      // Generate contextual notifications for the user
      await NotificationServiceEnhanced.instance
          .generateContextualNotifications(userId);

      if (kDebugMode) {
        debugPrint(
          '[UserSessionManager] User session initialized for: $userId',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[UserSessionManager] Error setting user session: $e');
      }
      rethrow;
    }
  }

  /// Clear the current user session
  Future<void> clearCurrentUser(context) async {
    if (_currentUserId == null) return;

    try {
      // Get controllers from context
      final preferencesController = context.read<PreferencesController>();
      final conversionController = context.read<ConversionController>();
      final notificationController = context.read<NotificationController>();

      // Clear user ID from all controllers
      preferencesController.setCurrentUserId(null);
      conversionController.setCurrentUserId(null);

      // Clear notifications
      notificationController.clear();

      if (kDebugMode) {
        debugPrint(
          '[UserSessionManager] User session cleared for: $_currentUserId',
        );
      }

      _currentUserId = null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[UserSessionManager] Error clearing user session: $e');
      }
      // Don't rethrow here as we're clearing session anyway
    }
  }

  /// Check if a user is currently logged in
  bool get isLoggedIn => _currentUserId != null;
}
