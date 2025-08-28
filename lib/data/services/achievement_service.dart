// lib/data/services/achievement_service.dart
import 'package:flutter/foundation.dart';
import '../models/conversion_history_model.dart';
import '../../features/history/service/conversion_history_service.dart';
import 'notification_service.dart';

class AchievementService {
  static final AchievementService _instance = AchievementService._internal();
  factory AchievementService() => _instance;
  AchievementService._internal();

  static AchievementService get instance => _instance;

  final NotificationServiceEnhanced _notificationService = NotificationServiceEnhanced.instance;

  /// Check achievements for a user after a conversion
  Future<void> checkAchievements(
    String userId,
    ConversionHistoryService historyService,
  ) async {
    try {
      if (kDebugMode) {
        debugPrint('[AchievementService] Checking achievements for user: $userId');
      }

      // Get user's conversion history
      final conversions = await historyService.getAllConversions(userId: userId, limit: 1000);
      
      if (conversions.isEmpty) return;

      final stats = _calculateUserStats(conversions);

      // Check each achievement
      await _checkFirstConversionAchievement(userId, stats);
      await _checkConversionMilestones(userId, stats);
      await _checkCurrencyDiversityAchievement(userId, stats);
      await _checkVolumeAchievements(userId, stats);
      await _checkStreakAchievements(userId, stats);

    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AchievementService] Error checking achievements: $e');
      }
    }
  }

  /// Calculate comprehensive user statistics
  Map<String, dynamic> _calculateUserStats(List<ConversionHistory> conversions) {
    final stats = <String, dynamic>{};
    
    // Basic counts
    stats['totalConversions'] = conversions.length;
    stats['totalVolume'] = conversions.fold<double>(0, (sum, c) => sum + c.baseAmount);
    
    // Currency diversity
    final uniqueBaseCurrencies = conversions.map((c) => c.baseCurrency).toSet();
    final uniqueTargetCurrencies = conversions.map((c) => c.targetCurrency).toSet();
    final allUniqueCurrencies = {...uniqueBaseCurrencies, ...uniqueTargetCurrencies};
    stats['uniqueCurrencies'] = allUniqueCurrencies.length;
    
    // Time-based stats
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thisWeek = now.subtract(Duration(days: now.weekday - 1));
    final thisMonth = DateTime(now.year, now.month, 1);
    
    stats['todayConversions'] = conversions.where((c) => 
      c.timestamp.isAfter(today)).length;
    stats['thisWeekConversions'] = conversions.where((c) => 
      c.timestamp.isAfter(thisWeek)).length;
    stats['thisMonthConversions'] = conversions.where((c) => 
      c.timestamp.isAfter(thisMonth)).length;
    
    // Largest conversion
    if (conversions.isNotEmpty) {
      final largestConversion = conversions.reduce((a, b) => 
        a.baseAmount > b.baseAmount ? a : b);
      stats['largestConversion'] = largestConversion.baseAmount;
      stats['largestConversionCurrency'] = largestConversion.baseCurrency;
    }
    
    // Streak calculation
    stats['currentStreak'] = _calculateCurrentStreak(conversions);
    stats['longestStreak'] = _calculateLongestStreak(conversions);
    
    // Most active day/time
    final dayOfWeekCounts = <int, int>{};
    for (final conversion in conversions) {
      final dayOfWeek = conversion.timestamp.weekday;
      dayOfWeekCounts[dayOfWeek] = (dayOfWeekCounts[dayOfWeek] ?? 0) + 1;
    }
    stats['mostActiveDayOfWeek'] = dayOfWeekCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b).key;
    
    return stats;
  }

  /// Check first conversion achievement
  Future<void> _checkFirstConversionAchievement(
    String userId, 
    Map<String, dynamic> stats,
  ) async {
    if (stats['totalConversions'] == 1) {
      await _notificationService.createAchievementNotification(
        userId: userId,
        achievement: 'First Conversion',
        description: 'You completed your first currency conversion! Welcome to CurrenSee!',
      );
    }
  }

  /// Check conversion milestone achievements
  Future<void> _checkConversionMilestones(
    String userId, 
    Map<String, dynamic> stats,
  ) async {
    final totalConversions = stats['totalConversions'] as int;
    final milestones = [10, 50, 100, 250, 500, 1000];
    
    for (final milestone in milestones) {
      if (totalConversions == milestone) {
        await _notificationService.createAchievementNotification(
          userId: userId,
          achievement: '$milestone Conversions',
          description: 'Amazing! You\'ve completed $milestone currency conversions.',
        );
        break; // Only trigger one milestone at a time
      }
    }
  }

  /// Check currency diversity achievement
  Future<void> _checkCurrencyDiversityAchievement(
    String userId, 
    Map<String, dynamic> stats,
  ) async {
    final uniqueCurrencies = stats['uniqueCurrencies'] as int;
    final diversityMilestones = [5, 10, 20, 30];
    
    for (final milestone in diversityMilestones) {
      if (uniqueCurrencies == milestone) {
        await _notificationService.createAchievementNotification(
          userId: userId,
          achievement: 'Currency Explorer',
          description: 'You\'ve worked with $milestone different currencies! You\'re a true global citizen.',
        );
        break;
      }
    }
  }

  /// Check volume achievements (based on USD equivalent)
  Future<void> _checkVolumeAchievements(
    String userId, 
    Map<String, dynamic> stats,
  ) async {
    final totalVolume = stats['totalVolume'] as double;
    final largestConversion = stats['largestConversion'] as double?;
    
    // Total volume milestones (assuming approximate USD values)
    final volumeMilestones = [1000, 5000, 10000, 50000, 100000];
    
    for (final milestone in volumeMilestones) {
      if (totalVolume >= milestone && totalVolume < milestone * 1.1) { // Close to milestone
        await _notificationService.createAchievementNotification(
          userId: userId,
          achievement: 'High Roller',
          description: 'You\'ve converted over \$${_formatNumber(milestone as double)} worth of currency!',
        );
        break;
      }
    }
    
    // Large single conversion achievements
    if (largestConversion != null) {
      final singleConversionMilestones = [1000, 5000, 10000, 25000];
      
      for (final milestone in singleConversionMilestones) {
        if (largestConversion >= milestone && largestConversion < milestone * 1.2) {
          final currency = stats['largestConversionCurrency'] as String;
          await _notificationService.createAchievementNotification(
            userId: userId,
            achievement: 'Big Spender',
            description: 'Wow! You converted ${_formatNumber(largestConversion)} $currency in a single transaction!',
          );
          break;
        }
      }
    }
  }

  /// Check streak achievements
  Future<void> _checkStreakAchievements(
    String userId, 
    Map<String, dynamic> stats,
  ) async {
    final currentStreak = stats['currentStreak'] as int;
    final longestStreak = stats['longestStreak'] as int;
    
    final streakMilestones = [3, 7, 14, 30];
    
    // Current streak achievements
    for (final milestone in streakMilestones) {
      if (currentStreak == milestone) {
        await _notificationService.createAchievementNotification(
          userId: userId,
          achievement: 'On Fire!',
          description: 'You\'re on a $milestone-day conversion streak! Keep it up!',
        );
        break;
      }
    }
    
    // Longest streak achievements
    for (final milestone in streakMilestones) {
      if (longestStreak == milestone && currentStreak == longestStreak) {
        await _notificationService.createAchievementNotification(
          userId: userId,
          achievement: 'Streak Master',
          description: 'New personal record! Your longest conversion streak is now $milestone days!',
        );
        break;
      }
    }
  }

  /// Calculate current streak of consecutive days with conversions
  int _calculateCurrentStreak(List<ConversionHistory> conversions) {
    if (conversions.isEmpty) return 0;
    
    // Sort by date (most recent first)
    final sortedConversions = List<ConversionHistory>.from(conversions)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    
    // Get unique conversion dates
    final conversionDates = sortedConversions
        .map((c) => DateTime(c.timestamp.year, c.timestamp.month, c.timestamp.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a)); // Most recent first
    
    if (conversionDates.isEmpty) return 0;
    
    // Check if user converted today or yesterday (to account for ongoing streaks)
    final latestConversionDate = conversionDates.first;
    final daysSinceLatest = todayDate.difference(latestConversionDate).inDays;
    
    if (daysSinceLatest > 1) return 0; // Streak broken
    
    // Count consecutive days
    int streak = 1;
    for (int i = 1; i < conversionDates.length; i++) {
      final currentDate = conversionDates[i - 1];
      final previousDate = conversionDates[i];
      final dayDifference = currentDate.difference(previousDate).inDays;
      
      if (dayDifference == 1) {
        streak++;
      } else {
        break;
      }
    }
    
    return streak;
  }

  /// Calculate longest streak in user's history
  int _calculateLongestStreak(List<ConversionHistory> conversions) {
    if (conversions.isEmpty) return 0;
    
    // Get unique conversion dates
    final conversionDates = conversions
        .map((c) => DateTime(c.timestamp.year, c.timestamp.month, c.timestamp.day))
        .toSet()
        .toList()
      ..sort();
    
    if (conversionDates.isEmpty) return 0;
    
    int longestStreak = 1;
    int currentStreak = 1;
    
    for (int i = 1; i < conversionDates.length; i++) {
      final currentDate = conversionDates[i];
      final previousDate = conversionDates[i - 1];
      final dayDifference = currentDate.difference(previousDate).inDays;
      
      if (dayDifference == 1) {
        currentStreak++;
        longestStreak = longestStreak > currentStreak ? longestStreak : currentStreak;
      } else {
        currentStreak = 1;
      }
    }
    
    return longestStreak;
  }

  /// Format large numbers for display
  String _formatNumber(double number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(0)}K';
    } else {
      return number.toStringAsFixed(0);
    }
  }

  /// Get user statistics for display
  Future<Map<String, dynamic>> getUserStats(
    String userId,
    ConversionHistoryService historyService,
  ) async {
    try {
      final conversions = await historyService.getAllConversions(userId: userId, limit: 1000);
      return _calculateUserStats(conversions);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AchievementService] Error getting user stats: $e');
      }
      return {};
    }
  }

  /// Check for special milestone notifications (monthly summary, etc.)
  Future<void> checkSpecialMilestones(
    String userId,
    ConversionHistoryService historyService,
  ) async {
    try {
      final now = DateTime.now();
      final firstDayOfMonth = DateTime(now.year, now.month, 1);
      final lastMonth = DateTime(now.year, now.month - 1, 1);
      
      // Get last month's conversions
      final lastMonthConversions = await historyService.getAllConversions(
        userId: userId,
        from: lastMonth,
        to: firstDayOfMonth,
      );
      
      if (lastMonthConversions.isNotEmpty && now.day == 1) { // First day of new month
        final monthName = _getMonthName(lastMonth.month);
        await _notificationService.createSystemNotification(
          userId: userId,
          title: 'Monthly Summary',
          message: 'In $monthName, you made ${lastMonthConversions.length} conversions across ${_getUniqueCurrencies(lastMonthConversions)} currencies!',
        );
      }
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AchievementService] Error checking special milestones: $e');
      }
    }
  }

  String _getMonthName(int month) {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month];
  }

  int _getUniqueCurrencies(List<ConversionHistory> conversions) {
    final currencies = <String>{};
    for (final conversion in conversions) {
      currencies.add(conversion.baseCurrency);
      currencies.add(conversion.targetCurrency);
    }
    return currencies.length;
  }
}