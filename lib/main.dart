import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'theme/app_theme.dart';
import 'routes/app_routes.dart';

Future<void> main() async {
  // 1. Required for async initialization before runApp
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Load the .env file from the project root
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    // If it fails, the app still runs but baseUrl will be empty
    debugPrint("CRITICAL: Could not load .env file. Check folder structure: $e");
  }

  runApp(const SaarthiApp());
}

class SaarthiApp extends StatelessWidget {
  const SaarthiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Saarthi',

      // Theme loaded from your theme/app_theme.dart
      theme: AppTheme.lightTheme,

      // Routes loaded from your routes/app_routes.dart
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.routes,
    );
  }
}