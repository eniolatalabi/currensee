// lib/features/profile/presentation/preferences_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants.dart';
import '../../../data/services/currency_service.dart';
import '../widgets/preference_item.dart';
import '../controller/preferences_controller.dart';

class PreferencesScreen extends StatelessWidget {
  const PreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Preferences'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Consumer<PreferencesController>(
        builder: (context, controller, _) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.errorMessage != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(controller.errorMessage!),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
              controller.clearError();
            });
          }

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(context, 'Currency Settings'),
                      _buildCurrencySection(context, controller),

                      AppConstants.spacingLarge,

                      _buildSectionHeader(context, 'Appearance'),
                      _buildAppearanceSection(context, controller),

                      AppConstants.spacingLarge,

                      _buildSectionHeader(context, 'Conversion'),
                      _buildConversionSection(context, controller),

                      AppConstants.spacingLarge,

                      _buildSectionHeader(context, 'Notifications'),
                      _buildNotificationSection(context, controller),

                      const SizedBox(height: 100),
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

  Widget _buildCurrencySection(
    BuildContext context,
    PreferencesController controller,
  ) {
    final preferences = controller.preferences;

    return _styledContainer(
      context,
      children: [
        PreferenceItem.navigation(
          title: 'Default Base Currency',
          subtitle:
              CurrencyService.supportedCurrencyNames[preferences
                  .defaultBaseCurrency] ??
              preferences.defaultBaseCurrency,
          icon: Icons.money_outlined,
          onTap: () => _showCurrencySelector(
            context: context,
            title: 'Select Base Currency',
            currentValue: preferences.defaultBaseCurrency,
            onSelected: controller.updateDefaultBaseCurrency,
          ),
        ),
        _divider(context),
        PreferenceItem.navigation(
          title: 'Default Target Currency',
          subtitle:
              CurrencyService.supportedCurrencyNames[preferences
                  .defaultTargetCurrency] ??
              preferences.defaultTargetCurrency,
          icon: Icons.swap_horiz_outlined,
          onTap: () => _showCurrencySelector(
            context: context,
            title: 'Select Target Currency',
            currentValue: preferences.defaultTargetCurrency,
            onSelected: controller.updateDefaultTargetCurrency,
          ),
        ),
      ],
    );
  }

  Widget _buildAppearanceSection(
    BuildContext context,
    PreferencesController controller,
  ) {
    final preferences = controller.preferences;
    return _styledContainer(
      context,
      children: [
        PreferenceItem(
          title: 'Dark Mode',
          subtitle: 'Use dark theme',
          icon: preferences.isDarkMode ? Icons.dark_mode : Icons.light_mode,
          trailing: Switch(
            value: preferences.isDarkMode,
            onChanged: controller.updateThemeMode,
          ),
        ),
      ],
    );
  }

  Widget _buildConversionSection(
    BuildContext context,
    PreferencesController controller,
  ) {
    final preferences = controller.preferences;
    return _styledContainer(
      context,
      children: [
        PreferenceItem(
          title: 'Auto Convert',
          subtitle: 'Convert automatically as you type',
          icon: Icons.auto_mode_outlined,
          trailing: Switch(
            value: preferences.autoConvert,
            onChanged: controller.updateAutoConvert,
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationSection(
    BuildContext context,
    PreferencesController controller,
  ) {
    final preferences = controller.preferences;
    return _styledContainer(
      context,
      children: [
        PreferenceItem(
          title: 'Push Notifications',
          subtitle: 'Receive rate alerts and updates',
          icon: Icons.notifications_outlined,
          trailing: Switch(
            value: preferences.enableNotifications,
            onChanged: controller.updateNotifications,
          ),
        ),
      ],
    );
  }

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

  void _showCurrencySelector({
    required BuildContext context,
    required String title,
    required String currentValue,
    required Function(String) onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CurrencySelector(
        title: title,
        currentValue: currentValue,
        onSelected: onSelected,
      ),
    );
  }
}

// 🔒 Private widget, scoped only to this screen
class _CurrencySelector extends StatelessWidget {
  final String title;
  final String currentValue;
  final Function(String) onSelected;

  const _CurrencySelector({
    required this.title,
    required this.currentValue,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Currency list
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: CurrencyService.supportedCodes.length,
                  itemBuilder: (context, index) {
                    final code = CurrencyService.supportedCodes[index];
                    final name =
                        CurrencyService.supportedCurrencyNames[code] ?? code;
                    final selected = code == currentValue;

                    return ListTile(
                      leading: Icon(
                        selected ? Icons.check_circle : Icons.circle_outlined,
                        color: selected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline,
                      ),
                      title: Text("$code — $name"),
                      onTap: () {
                        onSelected(code);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
