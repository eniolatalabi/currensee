// lib/data/models/app_notification_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  conversionSuccess,
  currencyRateChange,
  welcomeMessage,
  achievementUnlocked,
  systemUpdate,
  baseCurrencyChanged, // NEW: Added this enum value
  settingsChanged, // ADDED: For profile and settings updates including avatar changes
}

enum NotificationPriority { low, normal, high, urgent }

class AppNotification {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String message;
  final Map<String, dynamic> data;
  final NotificationPriority priority;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;
  final DateTime? expiresAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.data = const {},
    this.priority = NotificationPriority.normal,
    this.isRead = false,
    required this.createdAt,
    this.readAt,
    this.expiresAt,
  });

  // Convenience getters
  bool get isHigh => priority == NotificationPriority.high;
  bool get isUrgent => priority == NotificationPriority.urgent;
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  // Factory constructors for different notification types

  /// Create a conversion success notification
  factory AppNotification.conversionSuccess({
    required String userId,
    required String fromCurrency,
    required String toCurrency,
    required double amount,
    required double convertedAmount,
    required double rate,
  }) {
    return AppNotification(
      id: '', // Will be set by Firestore
      userId: userId,
      type: NotificationType.conversionSuccess,
      title: 'Conversion Successful',
      message:
          'Converted $amount $fromCurrency to ${convertedAmount.toStringAsFixed(2)} $toCurrency',
      data: {
        'fromCurrency': fromCurrency,
        'toCurrency': toCurrency,
        'amount': amount,
        'convertedAmount': convertedAmount,
        'rate': rate,
      },
      priority: NotificationPriority.normal,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 7)),
    );
  }

  /// Create a base currency change notification
  factory AppNotification.baseCurrencyChanged({
    required String userId,
    required String oldCurrency,
    required String newCurrency,
  }) {
    return AppNotification(
      id: '', // Will be set by Firestore
      userId: userId,
      type: NotificationType.baseCurrencyChanged,
      title: 'Base Currency Updated',
      message:
          'Your default base currency has been changed from $oldCurrency to $newCurrency',
      data: {'oldCurrency': oldCurrency, 'newCurrency': newCurrency},
      priority: NotificationPriority.normal,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 3)),
    );
  }

  /// ADDED: Create a settings/profile change notification
  factory AppNotification.settingsChanged({
    required String userId,
    required String changeType, // 'avatar', 'profile', 'preferences', etc.
    required String changeDescription,
    Map<String, dynamic>? additionalData,
  }) {
    String title;
    String message;

    switch (changeType.toLowerCase()) {
      case 'avatar':
        title = 'Profile Photo Updated';
        message = 'Your profile photo has been successfully updated.';
        break;
      case 'profile':
        title = 'Profile Updated';
        message = changeDescription;
        break;
      case 'preferences':
        title = 'Preferences Updated';
        message = changeDescription;
        break;
      case 'theme':
        title = 'Theme Changed';
        message = changeDescription;
        break;
      default:
        title = 'Settings Updated';
        message = changeDescription;
    }

    return AppNotification(
      id: '', // Will be set by Firestore
      userId: userId,
      type: NotificationType.settingsChanged,
      title: title,
      message: message,
      data: {
        'changeType': changeType,
        'changeDescription': changeDescription,
        ...?additionalData,
      },
      priority: NotificationPriority
          .low, // Settings changes are typically low priority
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(
        const Duration(days: 3),
      ), // Shorter expiry for settings
    );
  }

  /// Create a currency rate change notification
  factory AppNotification.currencyRateChange({
    required String userId,
    required String baseCurrency,
    required String targetCurrency,
    required double oldRate,
    required double newRate,
  }) {
    final changePercent = ((newRate - oldRate) / oldRate * 100);
    final changeText = changePercent > 0 ? 'increased' : 'decreased';

    return AppNotification(
      id: '', // Will be set by Firestore
      userId: userId,
      type: NotificationType.currencyRateChange,
      title: 'Currency Rate Alert',
      message:
          '$baseCurrency to $targetCurrency has $changeText by ${changePercent.abs().toStringAsFixed(1)}%',
      data: {
        'baseCurrency': baseCurrency,
        'targetCurrency': targetCurrency,
        'oldRate': oldRate,
        'newRate': newRate,
        'changePercent': changePercent,
      },
      priority: changePercent.abs() > 5
          ? NotificationPriority.high
          : NotificationPriority.normal,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 1)),
    );
  }

  /// Create a welcome message notification
  factory AppNotification.welcomeMessage({
    required String userId,
    String? userName,
  }) {
    final greeting = userName != null
        ? 'Welcome, $userName!'
        : 'Welcome to CurrenSee!';

    return AppNotification(
      id: '', // Will be set by Firestore
      userId: userId,
      type: NotificationType.welcomeMessage,
      title: greeting,
      message:
          'Start converting currencies with real-time rates and track your conversion history.',
      data: {'userName': userName},
      priority: NotificationPriority.normal,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 30)),
    );
  }

  /// Create an achievement notification
  factory AppNotification.achievementUnlocked({
    required String userId,
    required String achievement,
    required String description,
  }) {
    return AppNotification(
      id: '', // Will be set by Firestore
      userId: userId,
      type: NotificationType.achievementUnlocked,
      title: 'Achievement Unlocked: $achievement',
      message: description,
      data: {'achievement': achievement, 'description': description},
      priority: NotificationPriority.high,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 30)),
    );
  }

  /// Create a system update notification
  factory AppNotification.systemUpdate({
    required String userId,
    required String updateTitle,
    required String updateMessage,
    bool isUrgent = false,
  }) {
    return AppNotification(
      id: '', // Will be set by Firestore
      userId: userId,
      type: NotificationType.systemUpdate,
      title: updateTitle,
      message: updateMessage,
      data: {
        'updateTitle': updateTitle,
        'updateMessage': updateMessage,
        'isUrgent': isUrgent,
      },
      priority: isUrgent
          ? NotificationPriority.urgent
          : NotificationPriority.normal,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 7)),
    );
  }

  /// Create a copy with updated fields
  AppNotification copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? message,
    Map<String, dynamic>? data,
    NotificationPriority? priority,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
    DateTime? expiresAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      data: data ?? this.data,
      priority: priority ?? this.priority,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type.name,
      'title': title,
      'message': message,
      'data': data,
      'priority': priority.name,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
    };
  }

  /// Create from Firestore document
  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return AppNotification(
      id: doc.id,
      userId: data['userId'] as String,
      type: NotificationType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => NotificationType.systemUpdate,
      ),
      title: data['title'] as String,
      message: data['message'] as String,
      data: Map<String, dynamic>.from(data['data'] ?? {}),
      priority: NotificationPriority.values.firstWhere(
        (e) => e.name == data['priority'],
        orElse: () => NotificationPriority.normal,
      ),
      isRead: data['isRead'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      readAt: data['readAt'] != null
          ? (data['readAt'] as Timestamp).toDate()
          : null,
      expiresAt: data['expiresAt'] != null
          ? (data['expiresAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type.name,
      'title': title,
      'message': message,
      'data': data,
      'priority': priority.name,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'AppNotification(id: $id, type: $type, title: $title, isRead: $isRead)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AppNotification &&
        other.id == id &&
        other.userId == userId &&
        other.type == type;
  }

  @override
  int get hashCode {
    return Object.hash(id, userId, type);
  }
}
