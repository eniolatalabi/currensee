// lib/features/profile/controller/faq_controller.dart
import 'package:flutter/foundation.dart';

class FAQItem {
  final String question;
  final String answer;
  bool isExpanded;

  FAQItem({
    required this.question,
    required this.answer,
    this.isExpanded = false,
  });
}

class FAQController extends ChangeNotifier {
  List<FAQItem> _faqItems = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<FAQItem> get faqItems => _faqItems;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  FAQController() {
    _initializeFAQ();
  }

  void _initializeFAQ() {
    _faqItems = [
      FAQItem(
        question: 'How do I convert currencies?',
        answer:
            'Go to the Convert tab, select your base currency (what you have) and target currency (what you want to convert to), enter the amount, and the conversion will happen automatically. You can also tap the swap button to quickly reverse the currencies.',
      ),
      FAQItem(
        question: 'Are the exchange rates real-time?',
        answer:
            'Yes, we use live exchange rates from reliable financial data providers. Rates are updated frequently throughout the day to ensure accuracy.',
      ),
      FAQItem(
        question: 'How do I set up rate alerts?',
        answer:
            'Tap the notification icon in the top bar or go to the Alerts section. You can set alerts for specific currency pairs when they reach your target rate. We\'ll notify you when your conditions are met.',
      ),
      FAQItem(
        question: 'Can I use the app offline?',
        answer:
            'Basic features like viewing your conversion history work offline, but live currency conversion requires an internet connection to fetch current exchange rates.',
      ),
      FAQItem(
        question: 'How do I change my default currencies?',
        answer:
            'Go to Profile → Preferences and select your preferred base and target currencies. These will be pre-selected whenever you use the conversion feature.',
      ),
      FAQItem(
        question: 'Is my data secure?',
        answer:
            'Yes, we take security seriously. Your personal information is encrypted and stored securely. We never share your data with third parties without your consent.',
      ),
      FAQItem(
        question: 'How do I enable dark mode?',
        answer:
            'Go to Profile → Preferences and toggle the Dark Mode setting. The app will automatically switch themes and remember your preference.',
      ),
      FAQItem(
        question: 'Can I export my conversion history?',
        answer:
            'Currently, you can view your conversion history in the History tab. Export functionality is planned for a future update.',
      ),
      FAQItem(
        question: 'Why am I not receiving notifications?',
        answer:
            'Check that notifications are enabled in your device settings and in the app\'s Preferences. Also ensure you\'ve set up rate alerts in the Alerts section.',
      ),
      FAQItem(
        question: 'How do I delete my account?',
        answer:
            'You can request account deletion by sending feedback through the app or contacting our support team. We\'ll process your request within 7 business days.',
      ),
    ];
  }

  /// Toggle expansion state of an FAQ item
  void toggleExpansion(int index) {
    if (index >= 0 && index < _faqItems.length) {
      _faqItems[index].isExpanded = !_faqItems[index].isExpanded;
      notifyListeners();

      if (kDebugMode) {
        print(
          '[FAQController] FAQ item $index toggled to: ${_faqItems[index].isExpanded}',
        );
      }
    }
  }

  /// Expand all FAQ items
  void expandAll() {
    bool changed = false;
    for (var item in _faqItems) {
      if (!item.isExpanded) {
        item.isExpanded = true;
        changed = true;
      }
    }

    if (changed) {
      notifyListeners();
      if (kDebugMode) {
        print('[FAQController] All FAQ items expanded');
      }
    }
  }

  /// Collapse all FAQ items
  void collapseAll() {
    bool changed = false;
    for (var item in _faqItems) {
      if (item.isExpanded) {
        item.isExpanded = false;
        changed = true;
      }
    }

    if (changed) {
      notifyListeners();
      if (kDebugMode) {
        print('[FAQController] All FAQ items collapsed');
      }
    }
  }

  /// Search FAQ items (for future enhancement)
  List<FAQItem> searchFAQ(String query) {
    if (query.isEmpty) return _faqItems;

    final lowercaseQuery = query.toLowerCase();
    return _faqItems.where((item) {
      return item.question.toLowerCase().contains(lowercaseQuery) ||
          item.answer.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  /// Get FAQ count
  int get totalFAQs => _faqItems.length;

  /// Get expanded FAQ count
  int get expandedFAQs => _faqItems.where((item) => item.isExpanded).length;
}
