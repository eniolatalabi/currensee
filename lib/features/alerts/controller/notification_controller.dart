// lib/features/notifications/controller/notification_controller.dart
import 'package:flutter/foundation.dart';
import '../../../data/models/app_notification_model.dart';
import '../../../data/models/conversion_history_model.dart';
import '../../../data/services/notification_service.dart';

class NotificationController extends ChangeNotifier {
  final NotificationServiceEnhanced _notificationService;

  NotificationController(this._notificationService);

  // State
  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  // Pagination
  bool _hasMoreNotifications = true;
  bool _isLoadingMore = false;

  // Getters
  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  bool get isInitialized => _isInitialized;
  bool get hasMoreNotifications => _hasMoreNotifications;

  // Filtered getters
  List<AppNotification> get unreadNotifications =>
      _notifications.where((n) => !n.isRead).toList();

  List<AppNotification> get todayNotifications {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    return _notifications
        .where((n) => n.createdAt.isAfter(startOfDay))
        .toList();
  }

  List<AppNotification> get thisWeekNotifications {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfDay = DateTime(
      startOfWeek.year,
      startOfWeek.month,
      startOfWeek.day,
    );
    return _notifications
        .where((n) => n.createdAt.isAfter(startOfDay))
        .toList();
  }

  /// Initialize notifications for a user
  Future<void> initialize(String userId) async {
    if (_isInitialized && !_isLoading) {
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      await Future.wait([
        loadNotifications(userId),
        _updateUnreadCount(userId),
      ]);
      _isInitialized = true;
    } catch (e) {
      _setError('Failed to initialize notifications: ${e.toString()}');
      debugPrint('[NotificationController] Initialization error: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load notifications for user
  Future<void> loadNotifications(String userId, {bool refresh = false}) async {
    if (refresh) {
      _notifications.clear();
      _hasMoreNotifications = true;
      notifyListeners();
    }

    if (!refresh && !_hasMoreNotifications) return;

    _setLoading(!refresh);

    try {
      final newNotifications = await _notificationService.getUserNotifications(
        userId,
        limit: 20,
      );

      if (refresh) {
        _notifications = newNotifications;
      } else {
        _notifications.addAll(newNotifications);
      }

      _hasMoreNotifications = newNotifications.length == 20;
      notifyListeners();
    } catch (e) {
      _setError('Failed to load notifications: ${e.toString()}');
      debugPrint('[NotificationController] Load notifications error: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load more notifications (pagination)
  Future<void> loadMoreNotifications(String userId) async {
    if (_isLoadingMore || !_hasMoreNotifications) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      // Implementation would use lastDoc for pagination
      final moreNotifications = await _notificationService.getUserNotifications(
        userId,
        limit: 20,
      );

      _notifications.addAll(moreNotifications);
      _hasMoreNotifications = moreNotifications.length == 20;
      notifyListeners();
    } catch (e) {
      debugPrint('[NotificationController] Load more notifications error: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Update unread count
  Future<void> _updateUnreadCount(String userId) async {
    try {
      final count = await _notificationService.getUnreadCount(userId);
      _unreadCount = count;
      notifyListeners();
    } catch (e) {
      debugPrint('[NotificationController] Failed to update unread count: $e');
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(AppNotification notification, String userId) async {
    if (notification.isRead) return;

    try {
      // Optimistic update
      final index = _notifications.indexWhere((n) => n.id == notification.id);
      if (index != -1) {
        _notifications[index] = notification.copyWith(
          isRead: true,
          readAt: DateTime.now(),
        );
        _unreadCount = (_unreadCount - 1).clamp(0, _unreadCount);
        notifyListeners();
      }

      // Update on server
      await _notificationService.markAsRead(notification.id);
    } catch (e) {
      // Revert optimistic update
      final index = _notifications.indexWhere((n) => n.id == notification.id);
      if (index != -1) {
        _notifications[index] = notification;
        _unreadCount += 1;
        notifyListeners();
      }
      debugPrint('[NotificationController] Mark as read error: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    if (_unreadCount == 0) return;

    try {
      // Optimistic update
      for (int i = 0; i < _notifications.length; i++) {
        if (!_notifications[i].isRead) {
          _notifications[i] = _notifications[i].copyWith(
            isRead: true,
            readAt: DateTime.now(),
          );
        }
      }
      _unreadCount = 0;
      notifyListeners();

      // Update on server
      await _notificationService.markAllAsRead(userId);
    } catch (e) {
      // Reload to get correct state
      await loadNotifications(userId, refresh: true);
      await _updateUnreadCount(userId);
      debugPrint('[NotificationController] Mark all as read error: $e');
    }
  }

  /// Delete notification
  Future<void> deleteNotification(
    AppNotification notification,
    String userId,
  ) async {
    try {
      // Optimistic update
      _notifications.removeWhere((n) => n.id == notification.id);
      if (!notification.isRead) {
        _unreadCount = (_unreadCount - 1).clamp(0, _unreadCount);
      }
      notifyListeners();

      // Delete on server
      await _notificationService.deleteNotification(notification.id);
    } catch (e) {
      // Revert optimistic update
      _notifications.add(notification);
      _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (!notification.isRead) {
        _unreadCount += 1;
      }
      notifyListeners();
      debugPrint('[NotificationController] Delete notification error: $e');
    }
  }

  /// Refresh notifications
  Future<void> refresh(String userId) async {
    await loadNotifications(userId, refresh: true);
    await _updateUnreadCount(userId);
  }

  /// Get notifications by type
  List<AppNotification> getNotificationsByType(NotificationType type) {
    return _notifications.where((n) => n.type == type).toList();
  }

  /// Get notifications by priority
  List<AppNotification> getNotificationsByPriority(
    NotificationPriority priority,
  ) {
    return _notifications.where((n) => n.priority == priority).toList();
  }

  /// Get high priority notifications
  List<AppNotification> get highPriorityNotifications =>
      _notifications.where((n) => n.isHigh || n.isUrgent).toList();

  /// Check if there are unread high priority notifications
  bool get hasUnreadHighPriority =>
      _notifications.any((n) => !n.isRead && (n.isHigh || n.isUrgent));

  /// Get notification statistics
  Map<String, int> get notificationStats {
    final stats = <String, int>{
      'total': _notifications.length,
      'unread': _unreadCount,
      'today': todayNotifications.length,
      'thisWeek': thisWeekNotifications.length,
    };

    // Count by type
    for (final type in NotificationType.values) {
      final typeNotifications = getNotificationsByType(type);
      stats[type.name] = typeNotifications.length;
    }

    // Count by priority
    for (final priority in NotificationPriority.values) {
      final priorityNotifications = getNotificationsByPriority(priority);
      stats['${priority.name}Priority'] = priorityNotifications.length;
    }

    return stats;
  }

  /// Clear all notifications (for user logout/reset)
  void clear() {
    _notifications.clear();
    _unreadCount = 0;
    _isInitialized = false;
    _hasMoreNotifications = true;
    _clearError();
    notifyListeners();
  }

  /// Test method to create sample notifications for debugging
  Future<void> testNotifications(String userId) async {
    if (kDebugMode) {
      debugPrint('[NotificationController] Testing notifications...');

      try {
        // Test conversion success notification
        // FIXED: Use String ID and add userId
        final dummyConversion = ConversionHistory(
          id: DateTime.now().millisecondsSinceEpoch
              .toString(), // Convert int to String
          userId: userId, // Add userId parameter
          baseCurrency: 'USD',
          targetCurrency: 'EUR',
          baseAmount: 100.0,
          convertedAmount: 85.0,
          rate: 0.85,
          timestamp: DateTime.now(),
        );
        await _notificationService.createConversionSuccessNotification(
          userId: userId,
          conversion: dummyConversion,
        );

        // Test base currency change notification
        await _notificationService.createBaseCurrencyChangeNotification(
          userId: userId,
          oldCurrency: 'USD',
          newCurrency: 'NGN',
        );

        // Test currency rate change notification
        await _notificationService.createRateChangeNotification(
          userId: userId,
          baseCurrency: 'USD',
          targetCurrency: 'EUR',
          oldRate: 0.90,
          newRate: 0.85,
        );

        // Test welcome message notification
        await _notificationService.createWelcomeNotification(
          userId: userId,
          userName: 'Test User',
        );

        // Test achievement notification
        await _notificationService.createAchievementNotification(
          userId: userId,
          achievement: 'First Conversion',
          description: 'You completed your first currency conversion!',
        );

        // Test system update notification
        await _notificationService.createSystemNotification(
          userId: userId,
          title: 'App Updated',
          message: 'New features and improvements are now available.',
          isUrgent: false,
        );

        debugPrint(
          '[NotificationController] Test notifications created successfully',
        );

        // Refresh to show new notifications
        await refresh(userId);
      } catch (e) {
        debugPrint(
          '[NotificationController] Error creating test notifications: $e',
        );
        _setError('Failed to create test notifications: ${e.toString()}');
      }
    }
  }

  /// Set loading state
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  /// Set error message
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  /// Clear error
  void _clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  /// Subscribe to real-time updates
  Stream<List<AppNotification>> subscribeToNotifications(String userId) {
    return _notificationService.streamUserNotifications(userId);
  }

  /// Subscribe to real-time unread count
  Stream<int> subscribeToUnreadCount(String userId) {
    return _notificationService.streamUnreadCount(userId);
  }

  @override
  void dispose() {
    // Clean up any resources if needed
    super.dispose();
  }
}
