// lib/config/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  // Primary colors
  static const Color primary = Color(0xFF6B86C9);
  static const Color primaryLight = Color(0xFF7B8EB5);
  
  // Secondary colors
  static const Color secondary = Color(0xFF4CAF50);
  static const Color secondaryLight = Color(0xFFE0F2F1);
  
  // Neutral colors
  static const Color textDark = Color(0xFF333333);
  static const Color textMedium = Color(0xFF666666);
  static const Color textLight = Color(0xFFAAAAAA);
  static const Color background = Color(0xFFF5F5F5);
  
  static final ThemeData lightTheme = ThemeData(
    primaryColor: primary,
    scaffoldBackgroundColor: Colors.white,
    fontFamily: 'Inter',
    colorScheme: ColorScheme.light(
      primary: primary,
      secondary: secondary,
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: Colors.white,
      titleTextStyle: TextStyle(
        color: primaryLight,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: primaryLight),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
      ),
    ),
  );
}