import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'core/theme.dart';
import 'core/app_router.dart';
import 'data/services/storage_service.dart';
import 'data/services/currency_service.dart';

import 'features/splash/controller/splash_controller.dart';
import 'features/auth/controller/auth_controller.dart';
import 'features/conversion/controller/conversion_controller.dart';
import 'features/home/controller/home_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize local storage (SharedPreferences wrapper)
  await StorageService.init();

  runApp(const CurrenSeeApp());
}

class CurrenSeeApp extends StatelessWidget {
  const CurrenSeeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        /// Global singleton services
        Provider<CurrencyService>.value(value: CurrencyService.instance),

        /// Feature controllers
        ChangeNotifierProvider(
          create: (_) => SplashController(StorageService.instance),
        ),
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(
          create: (context) =>
              ConversionController(context.read<CurrencyService>()),
        ),
        ChangeNotifierProvider(create: (_) => HomeController()),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: "CurrenSee",
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
