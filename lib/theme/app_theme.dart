import 'package:flutter/material.dart';

class AppTheme {
  // COLORS
  static const Color primary          = Color(0xFF1D72FE); // A slightly punchier, modern Blue
  static const Color parentTheme = Color(0xFF4A148C); // Deep Purple/Indigo
  static const Color mentorTheme = Color(0xFF00875A); // Professional Green
  static const Color mentorThemeLight = Color(0xFFE3FCEF);
  // Backgrounds: The soft blue-to-green look
  static const Color backgroundTop    = Color(0xFFDBE8FE); // soft blue
  static const Color backgroundMid    = Color(0xFFF7FBFF); // almost white
  static const Color backgroundBottom = Color(0xFFC7EDCA); // soft green

  static const Color surface          = Colors.white;
  static const Color surfaceBorder    = Colors.white; // White border for glass effect

  static const Color textPrimary      = Color(0xFF101828); // Darker, cleaner navy/black
  static const Color textSecondary    = Color(0xFF475467); // Slate grey
  static const Color textMuted        = Color(0xFF98A2B3);

  // 1. Deep, saturated colors for the icons and titles
  static const Color student          = Color(0xFF005BD3); // Vibrant Blue
  static const Color mentor           = Color(0xFF008A5D); // Vibrant Green
  static const Color parent           = Color(0xFF6B4EE0); // Vibrant Purple

  // 2. These backgrounds need to be DARKER than what you have now to be visible
  static const Color studentBg        = Color(0xFFD0E3FF);
  static const Color mentorBg         = Color(0xFFCEF5E1);
  static const Color parentBg         = Color(0xFFEBE5FF);

  // TEXT STYLES
  static const TextStyle heading = TextStyle(
    fontSize: 42,
    fontWeight: FontWeight.w900, // Extra bold for that "Stitch" look
    color: textPrimary,
    height: 1.1,
    letterSpacing: -1.0,
  );

  static const TextStyle subheading = TextStyle(
    fontSize: 15,
    color: textSecondary,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 19, // Slightly larger
    fontWeight: FontWeight.w800, // Thicker for more 'pop'
    letterSpacing: -0.5,
  );

  static const TextStyle cardSubtitle = TextStyle(
    fontSize: 14,
    color: textSecondary,
    height: 1.2,
  );

  // THEME DATA
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Inter', // Or your default sans-serif font
    brightness: Brightness.light,
    scaffoldBackgroundColor: backgroundTop,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      background: backgroundTop,
    ),
  );
}