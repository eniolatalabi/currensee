// main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// core
import 'core/theme.dart';
import 'core/app_router.dart';
import 'core/navigation_controller.dart';
import 'core/session_manager.dart';

// data services
import 'data/services/storage_service.dart';
import 'data/services/preferences_service.dart';
import 'data/services/feedback_service.dart';
import 'data/services/currency_service.dart';
import 'data/services/local_db_service.dart';
import 'data/services/notification_service.dart';
import 'data/services/market_service.dart';
import 'data/services/achievement_service.dart';

// feature services & controllers
import 'features/history/service/conversion_history_service.dart'; // Updated service
import 'features/history/controller/history_controller.dart';
import 'features/splash/controller/splash_controller.dart';
import 'features/auth/controller/auth_controller.dart';
import 'features/conversion/controller/conversion_controller.dart';
import 'features/home/controller/home_controller.dart';
import 'features/alerts/controller/notification_controller.dart';
import 'features/news/controller/news_controller.dart';
import 'features/profile/controller/preferences_controller.dart';
import 'features/profile/controller/faq_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- Core services ---
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await StorageService.init();
  await LocalDbService.instance.init(); // Keep for legacy support
  await NotificationServiceEnhanced.instance.initialize();

  // --- PreferencesController must be loaded ONCE here ---
  final preferencesService = PreferencesService.instance;
  final preferencesController = PreferencesController(preferencesService);
  await preferencesController.loadPreferences();

  runApp(CurrenSeeApp(preferencesController: preferencesController));
}

class CurrenSeeApp extends StatelessWidget {
  final PreferencesController preferencesController;

  const CurrenSeeApp({super.key, required this.preferencesController});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        /// Global singleton services
        Provider<CurrencyService>.value(value: CurrencyService.instance),
        Provider<NotificationServiceEnhanced>.value(
          value: NotificationServiceEnhanced.instance,
        ),
        Provider<MarketService>(create: (_) => MarketService()),
        Provider<PreferencesService>.value(value: PreferencesService.instance),
        Provider<FeedbackService>.value(value: FeedbackService.instance),

        /// NEW: Firestore-based conversion history service (no DAO needed)
        Provider<ConversionHistoryService>(
          create: (_) => ConversionHistoryService(),
        ),

        /// Feature controllers
        ChangeNotifierProvider(
          create: (_) => SplashController(StorageService.instance),
        ),
        ChangeNotifierProvider(create: (_) => AuthController()),

        /// ConversionController now gets the Firestore history service
        ChangeNotifierProvider(
          create: (context) => ConversionController(
            context.read<CurrencyService>(),
            context.read<ConversionHistoryService>(),
          ),
        ),

        ChangeNotifierProvider(create: (_) => HomeController()),

        /// HistoryController uses the same Firestore service instance
        ChangeNotifierProvider(
          create: (context) =>
              HistoryController(context.read<ConversionHistoryService>()),
        ),

        /// NotificationController with enhanced service
        ChangeNotifierProvider(
          create: (context) => NotificationController(
            context.read<NotificationServiceEnhanced>(),
          ),
        ),

        ChangeNotifierProvider(
          create: (context) => NewsController(context.read<MarketService>()),
        ),

        ChangeNotifierProvider.value(value: NavigationController.instance),
        Provider<AchievementService>.value(value: AchievementService.instance),

        /// Profile controllers
        ChangeNotifierProvider.value(value: preferencesController),
        ChangeNotifierProvider(create: (_) => FAQController()),
      ],
      child: Consumer<PreferencesController>(
        builder: (context, prefs, child) {
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: "CurrenSee",
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: prefs.preferences.isDarkMode
                ? ThemeMode.dark
                : ThemeMode.light,
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}
