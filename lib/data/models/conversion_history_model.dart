// lib/data/models/conversion_history_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ConversionHistory {
  final String? id; // String for Firestore document IDs
  final String? userId; // Added userId field
  final String baseCurrency;
  final String targetCurrency;
  final double baseAmount;
  final double convertedAmount;
  final double rate;
  final DateTime timestamp;

  const ConversionHistory({
    this.id,
    this.userId,
    required this.baseCurrency,
    required this.targetCurrency,
    required this.baseAmount,
    required this.convertedAmount,
    required this.rate,
    required this.timestamp,
  });

  // Copy with method for creating modified copies
  ConversionHistory copyWith({
    String? id,
    String? userId,
    String? baseCurrency,
    String? targetCurrency,
    double? baseAmount,
    double? convertedAmount,
    double? rate,
    DateTime? timestamp,
  }) {
    return ConversionHistory(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      baseCurrency: baseCurrency ?? this.baseCurrency,
      targetCurrency: targetCurrency ?? this.targetCurrency,
      baseAmount: baseAmount ?? this.baseAmount,
      convertedAmount: convertedAmount ?? this.convertedAmount,
      rate: rate ?? this.rate,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'baseCurrency': baseCurrency,
      'targetCurrency': targetCurrency,
      'baseAmount': baseAmount,
      'convertedAmount': convertedAmount,
      'rate': rate,
      'timestamp': Timestamp.fromDate(timestamp),
      'createdAt': Timestamp.now(),
    };
  }

  // Create from Firestore document - FIXED: Keep ID as String
  factory ConversionHistory.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ConversionHistory(
      id: doc.id, // Keep as String, don't convert to hashCode
      userId: data['userId'] as String?,
      baseCurrency: data['baseCurrency'] as String,
      targetCurrency: data['targetCurrency'] as String,
      baseAmount: (data['baseAmount'] as num).toDouble(),
      convertedAmount: (data['convertedAmount'] as num).toDouble(),
      rate: (data['rate'] as num).toDouble(),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  // Legacy support methods (for SQLite compatibility)
  factory ConversionHistory.fromMap(Map<String, dynamic> map) {
    return ConversionHistory(
      id: map['id']?.toString(), // Convert int to String if needed
      userId: map['userId'] as String?,
      baseCurrency: map['baseCurrency'] as String,
      targetCurrency: map['targetCurrency'] as String,
      baseAmount: (map['baseAmount'] as num).toDouble(),
      convertedAmount: (map['convertedAmount'] as num).toDouble(),
      rate: (map['rate'] as num).toDouble(),
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'baseCurrency': baseCurrency,
      'targetCurrency': targetCurrency,
      'baseAmount': baseAmount,
      'convertedAmount': convertedAmount,
      'rate': rate,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // API compatibility methods
  factory ConversionHistory.fromJson(Map<String, dynamic> json) {
    return ConversionHistory(
      id: json['id']?.toString(),
      userId: json['user_id'] as String?,
      baseCurrency: json['base_currency'] as String,
      targetCurrency: json['target_currency'] as String,
      baseAmount: (json['base_amount'] as num).toDouble(),
      convertedAmount: (json['converted_amount'] as num).toDouble(),
      rate: (json['exchange_rate'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'base_currency': baseCurrency,
      'target_currency': targetCurrency,
      'base_amount': baseAmount,
      'converted_amount': convertedAmount,
      'exchange_rate': rate,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // Helper methods remain the same
  String get displayAmount {
    return '${baseAmount.toStringAsFixed(2)} $baseCurrency → ${convertedAmount.toStringAsFixed(2)} $targetCurrency';
  }

  String get displayRate {
    return '1 $baseCurrency = ${rate.toStringAsFixed(4)} $targetCurrency';
  }

  String get currencyPair {
    return '$baseCurrency/$targetCurrency';
  }

  String get formattedTimestamp {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final month = months[timestamp.month - 1];
    final day = timestamp.day.toString().padLeft(2, '0');
    final year = timestamp.year;
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');

    return '$month $day, $year at $hour:$minute';
  }

  String get relativeTime {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return minutes <= 1 ? 'Just now' : '$minutes minutes ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return hours == 1 ? '1 hour ago' : '$hours hours ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return days == 1 ? 'Yesterday' : '$days days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return months == 1 ? '1 month ago' : '$months months ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return years == 1 ? '1 year ago' : '$years years ago';
    }
  }

  String get shareText {
    return '''Currency Conversion:
${baseAmount.toStringAsFixed(2)} $baseCurrency = ${convertedAmount.toStringAsFixed(2)} $targetCurrency
Rate: 1 $baseCurrency = ${rate.toStringAsFixed(4)} $targetCurrency
Date: $formattedTimestamp

Converted using CurrenSee''';
  }

  bool get isToday {
    final now = DateTime.now();
    return timestamp.year == now.year &&
        timestamp.month == now.month &&
        timestamp.day == now.day;
  }

  bool get isThisWeek {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    return timestamp.isAfter(startOfWeek) &&
        timestamp.isBefore(now.add(const Duration(days: 1)));
  }

  @override
  String toString() {
    return 'ConversionHistory('
        'id: $id, '
        'userId: $userId, '
        'baseCurrency: $baseCurrency, '
        'targetCurrency: $targetCurrency, '
        'baseAmount: $baseAmount, '
        'convertedAmount: $convertedAmount, '
        'rate: $rate, '
        'timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConversionHistory &&
        other.id == id &&
        other.userId == userId &&
        other.baseCurrency == baseCurrency &&
        other.targetCurrency == targetCurrency &&
        other.baseAmount == baseAmount &&
        other.convertedAmount == convertedAmount &&
        other.rate == rate &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        baseCurrency.hashCode ^
        targetCurrency.hashCode ^
        baseAmount.hashCode ^
        convertedAmount.hashCode ^
        rate.hashCode ^
        timestamp.hashCode;
  }
}
