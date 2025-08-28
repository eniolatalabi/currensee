// lib/features/profile/presentation/feedback_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants.dart';
import '../../../data/models/feedback_model.dart';
import '../../../data/services/feedback_service.dart';
import '../../../features/auth/controller/auth_controller.dart';
import '../widgets/feedback_textfield.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  late TextEditingController _messageController;
  FeedbackType _selectedType = FeedbackType.general;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Send Feedback'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(theme),
                  AppConstants.spacingLarge,
                  _buildFeedbackTypeSection(theme),
                  AppConstants.spacingLarge,
                  _buildMessageSection(theme),
                  AppConstants.spacingLarge,
                  _buildSubmitSection(theme),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'We\'d love to hear from you!',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Share your thoughts, report bugs, or suggest new features. Your feedback helps us improve CurrenSee.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackTypeSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Feedback Type',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        AppConstants.spacingSmall,
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppConstants.radius),
            boxShadow: AppConstants.boxShadow,
          ),
          child: Column(
            children: FeedbackType.values.map((type) {
              final isSelected = type == _selectedType;
              final isLast = type == FeedbackType.values.last;

              return Column(
                children: [
                  ListTile(
                    title: Text(_getFeedbackTypeTitle(type)),
                    subtitle: Text(_getFeedbackTypeDescription(type)),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary.withOpacity(0.15)
                            : theme.colorScheme.surfaceVariant.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getFeedbackTypeIcon(type),
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                    ),
                    trailing: Radio<FeedbackType>(
                      value: type,
                      groupValue: _selectedType,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedType = value);
                        }
                      },
                    ),
                    onTap: () => setState(() => _selectedType = type),
                  ),
                  if (!isLast)
                    Divider(
                      height: 1,
                      color: theme.colorScheme.outline.withOpacity(0.2),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Message',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        AppConstants.spacingSmall,
        FeedbackTextField(
          controller: _messageController,
          hintText: _getFeedbackHint(_selectedType),
          enabled: !_isSubmitting,
          errorText: _errorMessage,
          onChanged: (_) => _clearError(),
        ),
      ],
    );
  }

  Widget _buildSubmitSection(ThemeData theme) {
    return Consumer<AuthController>(
      builder: (context, authController, _) {
        final user = authController.currentUser;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!user.isGuest) ...[
              Container(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(AppConstants.radius),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 16,
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Submitting as',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${user.firstName} ${user.lastName} (${user.email})',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              AppConstants.spacingMedium,
            ],

            ElevatedButton(
              onPressed: _isSubmitting || user.isGuest ? null : _submitFeedback,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.send),
                        const SizedBox(width: 8),
                        Text(
                          user.isGuest
                              ? 'Sign in to send feedback'
                              : 'Send Feedback',
                        ),
                      ],
                    ),
            ),

            if (user.isGuest) ...[
              AppConstants.spacingSmall,
              Text(
                'Please sign in to send feedback. This helps us follow up on your suggestions.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        );
      },
    );
  }

  String _getFeedbackTypeTitle(FeedbackType type) {
    switch (type) {
      case FeedbackType.bug:
        return 'Bug Report';
      case FeedbackType.feature:
        return 'Feature Request';
      case FeedbackType.general:
        return 'General Feedback';
      case FeedbackType.compliment:
        return 'Compliment';
    }
  }

  String _getFeedbackTypeDescription(FeedbackType type) {
    switch (type) {
      case FeedbackType.bug:
        return 'Report issues or errors you\'ve encountered';
      case FeedbackType.feature:
        return 'Suggest new features or improvements';
      case FeedbackType.general:
        return 'General comments or questions';
      case FeedbackType.compliment:
        return 'Share what you love about the app';
    }
  }

  IconData _getFeedbackTypeIcon(FeedbackType type) {
    switch (type) {
      case FeedbackType.bug:
        return Icons.bug_report_outlined;
      case FeedbackType.feature:
        return Icons.lightbulb_outline;
      case FeedbackType.general:
        return Icons.chat_bubble_outline;
      case FeedbackType.compliment:
        return Icons.favorite_outline;
    }
  }

  String _getFeedbackHint(FeedbackType type) {
    switch (type) {
      case FeedbackType.bug:
        return 'Describe the bug you encountered. Include steps to reproduce it if possible...';
      case FeedbackType.feature:
        return 'Describe the feature you\'d like to see. How would it help you?';
      case FeedbackType.general:
        return 'Share your thoughts, questions, or general comments...';
      case FeedbackType.compliment:
        return 'Tell us what you love about CurrenSee!';
    }
  }

  void _clearError() {
    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    }
  }

  Future<void> _submitFeedback() async {
    final message = _messageController.text.trim();

    if (message.isEmpty) {
      setState(() => _errorMessage = 'Please enter your feedback message');
      return;
    }

    if (message.length < 10) {
      setState(
        () => _errorMessage =
            'Please provide more details (at least 10 characters)',
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final authController = context.read<AuthController>();
      final user = authController.currentUser;

      final success = await FeedbackService.instance.submitFeedback(
        user: user,
        type: _selectedType,
        message: message,
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Thank you! Your feedback has been sent successfully.',
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          Navigator.of(context).pop();
        }
      } else {
        setState(
          () => _errorMessage = 'Failed to send feedback. Please try again.',
        );
      }
    } catch (e) {
      setState(
        () => _errorMessage =
            'An error occurred. Please check your connection and try again.',
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
