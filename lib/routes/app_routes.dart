import 'package:flutter/material.dart';
import '../screens/splash_screen.dart';
import '../screens/landing_screen.dart';

class AppRoutes {
  static const String splash = "/";
  static const String landing = "/landing";

  static Map<String, WidgetBuilder> routes = {
    splash: (context) => const SplashScreen(),
    landing: (context) => const LandingScreen(),
  };
}