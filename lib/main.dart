import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/theme.dart';
import 'core/app_router.dart';
import 'data/services/storage_service.dart';
import 'features/splash/controller/splash_controller.dart';
import 'features/auth/controller/auth_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (future-proof)
  await Firebase.initializeApp();

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
        ChangeNotifierProvider(
          create: (_) => SplashController(StorageService.instance),
        ),
        ChangeNotifierProvider(create: (_) => AuthController()),
        // Future controllers: PreferencesController, ConversionController, etc.
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
