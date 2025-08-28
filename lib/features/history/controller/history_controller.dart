// lib/features/history/controller/history_controller.dart
import 'package:flutter/foundation.dart';
import '../../../data/models/conversion_history_model.dart';
import '../service/conversion_history_service.dart';

class HistoryController extends ChangeNotifier {
  final ConversionHistoryService _service;

  HistoryController(this._service);

  // State variables
  List<ConversionHistory> _history = [];
  List<ConversionHistory> _filteredHistory = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String? _currentUserId; // NEW: Track current user

  // Filter variables
  String? _selectedBaseCurrency;
  String? _selectedTargetCurrency;
  DateTime? _fromDate;
  DateTime? _toDate;

  // Getters
  List<ConversionHistory> get history =>
      _searchQuery.isEmpty ? _history : _filteredHistory;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String? get selectedBaseCurrency => _selectedBaseCurrency;
  String? get selectedTargetCurrency => _selectedTargetCurrency;
  DateTime? get fromDate => _fromDate;
  DateTime? get toDate => _toDate;
  bool get hasFilters =>
      _selectedBaseCurrency != null ||
      _selectedTargetCurrency != null ||
      _fromDate != null ||
      _toDate != null;

  /// NEW: Set current user ID
  void setCurrentUserId(String? userId) {
    if (_currentUserId != userId) {
      _currentUserId = userId;
      // Clear existing data when user changes
      _history.clear();
      _filteredHistory.clear();
      _clearFilters();
      notifyListeners();
    }
  }

  /// Load all conversions for current user
  Future<void> loadAll() async {
    if (_currentUserId == null) {
      _setError('No user logged in');
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final conversions = await _service.getAllConversions(
        userId: _currentUserId!,
        baseCurrency: _selectedBaseCurrency,
        targetCurrency: _selectedTargetCurrency,
        from: _fromDate,
        to: _toDate,
      );

      _history = conversions;
      _applyFilters();

      if (kDebugMode) {
        debugPrint(
          '[HistoryController] ✅ Loaded ${_history.length} conversions for user $_currentUserId',
        );
      }
    } catch (e) {
      _setError('Failed to load history: ${e.toString()}');
      if (kDebugMode) {
        debugPrint('[HistoryController] ❌ Error loading history: $e');
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Load recent conversions for current user
  Future<void> loadRecent({int limit = 10}) async {
    if (_currentUserId == null) {
      _setError('No user logged in');
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final recentConversions = await _service.getRecentConversions(
        userId: _currentUserId!,
        limit: limit,
      );

      // If we're not filtering, replace the full history
      if (!hasFilters && _searchQuery.isEmpty) {
        _history = recentConversions;
      }

      _applyFilters();

      if (kDebugMode) {
        debugPrint(
          '[HistoryController] ✅ Loaded ${recentConversions.length} recent conversions',
        );
      }
    } catch (e) {
      _setError('Failed to load recent history: ${e.toString()}');
      if (kDebugMode) {
        debugPrint('[HistoryController] ❌ Error loading recent history: $e');
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Refresh data
  Future<void> refresh() async {
    await loadAll();
  }

  /// Search functionality
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  /// Filter methods
  void setBaseCurrencyFilter(String? currency) {
    _selectedBaseCurrency = currency;
    loadAll();
  }

  void setTargetCurrencyFilter(String? currency) {
    _selectedTargetCurrency = currency;
    loadAll();
  }

  void setDateRangeFilter(DateTime? from, DateTime? to) {
    _fromDate = from;
    _toDate = to;
    loadAll();
  }

  void clearFilters() {
    _clearFilters();
    loadAll();
  }

  void _clearFilters() {
    _selectedBaseCurrency = null;
    _selectedTargetCurrency = null;
    _fromDate = null;
    _toDate = null;
  }

  /// Delete conversion - UPDATED for Firestore (String ID)
  Future<void> deleteConversion(String docId) async {
    try {
      await _service.deleteConversion(docId);
      _history.removeWhere((item) => item.id == docId);
      _applyFilters();
      notifyListeners();

      if (kDebugMode) {
        debugPrint('[HistoryController] ✅ Deleted conversion $docId');
      }
    } catch (e) {
      _setError('Failed to delete conversion: ${e.toString()}');
      if (kDebugMode) {
        debugPrint('[HistoryController] ❌ Error deleting conversion: $e');
      }
    }
  }

  /// Clear all history for current user
  Future<void> clearAllHistory() async {
    if (_currentUserId == null) {
      _setError('No user logged in');
      return;
    }

    try {
      await _service.clearAll(_currentUserId!);
      _history.clear();
      _filteredHistory.clear();
      notifyListeners();

      if (kDebugMode) {
        debugPrint('[HistoryController] ✅ Cleared all history');
      }
    } catch (e) {
      _setError('Failed to clear history: ${e.toString()}');
      if (kDebugMode) {
        debugPrint('[HistoryController] ❌ Error clearing history: $e');
      }
    }
  }

  /// Private method to apply search and filters
  void _applyFilters() {
    if (_searchQuery.isEmpty) {
      _filteredHistory = _history;
    } else {
      _filteredHistory = _history.where((conversion) {
        final query = _searchQuery.toLowerCase();
        return conversion.baseCurrency.toLowerCase().contains(query) ||
            conversion.targetCurrency.toLowerCase().contains(query);
      }).toList();
    }
  }

  /// Get statistics for current user
  Map<String, dynamic> getStatistics() {
    if (_history.isEmpty) {
      return {
        'totalConversions': 0,
        'totalAmount': 0.0,
        'averageAmount': 0.0,
        'mostUsedCurrency': 'None',
        'thisMonth': 0,
      };
    }

    final now = DateTime.now();
    var thisMonthCount = 0;
    var totalAmount = 0.0;
    final currencyCount = <String, int>{};

    for (final conversion in _history) {
      totalAmount += conversion.baseAmount;

      // Count currency usage
      currencyCount[conversion.baseCurrency] =
          (currencyCount[conversion.baseCurrency] ?? 0) + 1;

      // Count this month
      if (conversion.timestamp.year == now.year &&
          conversion.timestamp.month == now.month) {
        thisMonthCount++;
      }
    }

    // Find most used currency
    String mostUsedCurrency = 'None';
    if (currencyCount.isNotEmpty) {
      mostUsedCurrency = currencyCount.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
    }

    return {
      'totalConversions': _history.length,
      'totalAmount': totalAmount,
      'averageAmount': totalAmount / _history.length,
      'mostUsedCurrency': mostUsedCurrency,
      'thisMonth': thisMonthCount,
    };
  }

  /// Clear state when user logs out
  void clear() {
    _history.clear();
    _filteredHistory.clear();
    _currentUserId = null;
    _clearFilters();
    _clearError();
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}
