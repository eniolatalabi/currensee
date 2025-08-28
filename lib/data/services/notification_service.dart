// lib/data/services/notification_service_enhanced.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_notification_model.dart';
import '../models/conversion_history_model.dart';
import 'currency_service.dart';

class NotificationServiceEnhanced {
  static final NotificationServiceEnhanced _instance =
      NotificationServiceEnhanced._internal();
  factory NotificationServiceEnhanced() => _instance;
  NotificationServiceEnhanced._internal();

  static NotificationServiceEnhanced get instance => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static const String _collection = 'notifications';

  bool _initialized = false;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize local notifications
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
  }

  /// Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    if (kDebugMode) {
      debugPrint(
        '[NotificationService] Notification tapped: ${response.payload}',
      );
    }
    // TODO: Add navigation logic based on notification type
  }

  /// Create notification for successful conversion
  Future<void> createConversionSuccessNotification({
    required String userId,
    required ConversionHistory conversion,
  }) async {
    final notification = AppNotification.conversionSuccess(
      userId: userId,
      fromCurrency: conversion.baseCurrency,
      toCurrency: conversion.targetCurrency,
      amount: conversion.baseAmount,
      convertedAmount: conversion.convertedAmount,
      rate: conversion.rate,
    );

    await _saveNotification(notification);
    await _showLocalNotification(notification);
  }

  /// Create notification for base currency change
  Future<void> createBaseCurrencyChangeNotification({
    required String userId,
    required String oldCurrency,
    required String newCurrency,
  }) async {
    final notification = AppNotification.baseCurrencyChanged(
      userId: userId,
      oldCurrency: oldCurrency,
      newCurrency: newCurrency,
    );

    await _saveNotification(notification);
    await _showLocalNotification(notification);
  }

  /// Create notification for currency rate changes
  Future<void> createRateChangeNotification({
    required String userId,
    required String baseCurrency,
    required String targetCurrency,
    required double oldRate,
    required double newRate,
  }) async {
    // Only notify for significant changes (>1%)
    final changePercent = ((newRate - oldRate) / oldRate * 100).abs();
    if (changePercent < 1.0) return;

    final notification = AppNotification.currencyRateChange(
      userId: userId,
      baseCurrency: baseCurrency,
      targetCurrency: targetCurrency,
      oldRate: oldRate,
      newRate: newRate,
    );

    await _saveNotification(notification);
    await _showLocalNotification(notification);
  }

  /// Create welcome notification for new users
  Future<void> createWelcomeNotification({
    required String userId,
    String? userName,
  }) async {
    final notification = AppNotification.welcomeMessage(
      userId: userId,
      userName: userName,
    );

    await _saveNotification(notification);
    await _showLocalNotification(notification);
  }

  /// Create achievement notification
  Future<void> createAchievementNotification({
    required String userId,
    required String achievement,
    required String description,
  }) async {
    final notification = AppNotification.achievementUnlocked(
      userId: userId,
      achievement: achievement,
      description: description,
    );

    await _saveNotification(notification);
    await _showLocalNotification(notification);
  }

  /// Create system update notification
  Future<void> createSystemNotification({
    required String userId,
    required String title,
    required String message,
    bool isUrgent = false,
  }) async {
    final notification = AppNotification.systemUpdate(
      userId: userId,
      updateTitle: title,
      updateMessage: message,
      isUrgent: isUrgent,
    );

    await _saveNotification(notification);
    if (isUrgent) {
      await _showLocalNotification(notification);
    }
  }

  /// Save notification to Firestore
  Future<String> _saveNotification(AppNotification notification) async {
    try {
      final docRef = await _firestore
          .collection(_collection)
          .add(notification.toFirestore());

      if (kDebugMode) {
        debugPrint('[NotificationService] Saved notification: ${docRef.id}');
      }

      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NotificationService] Error saving notification: $e');
      }
      rethrow;
    }
  }

  /// Show local push notification
  Future<void> _showLocalNotification(AppNotification notification) async {
    if (!await _areNotificationsEnabled()) return;
    if (await _isQuietHours()) return;

    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'app_notifications',
      'App Notifications',
      channelDescription: 'CurrenSee app notifications',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.message,
      details,
      payload: 'notification_${notification.id}',
    );
  }

  /// Get notifications for a user (paginated)
  Future<List<AppNotification>> getUserNotifications(
    String userId, {
    int limit = 20,
    DocumentSnapshot? lastDoc,
    bool unreadOnly = false,
  }) async {
    try {
      Query query = _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true);

      if (unreadOnly) {
        query = query.where('isRead', isEqualTo: false);
      }

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      query = query.limit(limit);

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => AppNotification.fromFirestore(doc))
          .where((notification) => !notification.isExpired)
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NotificationService] Error fetching notifications: $e');
      }
      return [];
    }
  }

  /// Get unread notification count
  Future<int> getUnreadCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NotificationService] Error getting unread count: $e');
      }
      return 0;
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection(_collection).doc(notificationId).update({
        'isRead': true,
        'readAt': Timestamp.now(),
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NotificationService] Error marking as read: $e');
      }
    }
  }

  /// Mark all notifications as read for user
  Future<void> markAllAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': Timestamp.now(),
        });
      }

      await batch.commit();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NotificationService] Error marking all as read: $e');
      }
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection(_collection).doc(notificationId).delete();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NotificationService] Error deleting notification: $e');
      }
    }
  }

  /// Stream of user notifications (real-time)
  Stream<List<AppNotification>> streamUserNotifications(
    String userId, {
    int limit = 20,
  }) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AppNotification.fromFirestore(doc))
              .where((notification) => !notification.isExpired)
              .toList(),
        );
  }

  /// Stream of unread count (real-time)
  Stream<int> streamUnreadCount(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Check achievements and create notifications
  Future<void> checkAchievements(String userId) async {
    // TODO: Implement achievement logic
    // Examples:
    // - First conversion
    // - 10 conversions milestone
    // - Using 5 different currencies
    // - Converting large amounts
    // - Daily streak
  }

  /// Clean up expired notifications
  Future<void> cleanupExpiredNotifications() async {
    try {
      final cutoff = DateTime.now();
      final snapshot = await _firestore
          .collection(_collection)
          .where('expiresAt', isLessThan: Timestamp.fromDate(cutoff))
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      if (kDebugMode) {
        debugPrint(
          '[NotificationService] Cleaned up ${snapshot.docs.length} expired notifications',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[NotificationService] Error cleaning up expired notifications: $e',
        );
      }
    }
  }

  /// Notification settings
  Future<bool> _areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications_enabled') ?? true;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', enabled);
  }

  Future<bool> _isQuietHours() async {
    final prefs = await SharedPreferences.getInstance();
    final quietEnabled = prefs.getBool('quiet_hours_enabled') ?? true;
    if (!quietEnabled) return false;

    final start = prefs.getInt('quiet_hours_start') ?? 22; // 10 PM
    final end = prefs.getInt('quiet_hours_end') ?? 8; // 8 AM
    final currentHour = DateTime.now().hour;

    if (start > end) {
      return currentHour >= start || currentHour < end;
    } else {
      return currentHour >= start && currentHour < end;
    }
  }

  /// Auto-generate contextual notifications
  Future<void> generateContextualNotifications(String userId) async {
    // Check for significant rate changes in user's frequently used currencies
    await _checkFrequentCurrencyRates(userId);

    // Check for milestones
    await checkAchievements(userId);

    // Clean up old notifications
    await cleanupExpiredNotifications();
  }

  Future<void> _checkFrequentCurrencyRates(String userId) async {
    // TODOImplement logic to check rates for user's most used currency pairs
    // This would analyze conversion history and monitor rates for significant changes
  }
}
