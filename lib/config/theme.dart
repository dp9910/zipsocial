import 'package:flutter/material.dart';

class AppTheme {
  // Soft Teal color scheme - eye-friendly and relaxing
  static const Color primary = Color(0xFF4ECDC4);
  static const Color primaryDark = Color(0xFF44A08D);
  static const Color primaryLight = Color(0xFF7FDBDA);
  
  // Updated neutral colors to complement teal
  static const Color backgroundLight = Color(0xFFF8FFFE);
  static const Color backgroundDark = Color(0xFF0F1419);
  static const Color contentLight = Color(0xFF1A1F24);
  static const Color contentDark = Color(0xFFF1F5F4);
  static const Color subtleLight = Color(0xFF2A4A47);
  static const Color subtleDark = Color(0xFFA7E8E3);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
        primary: primary,
        background: backgroundLight,
        surface: backgroundLight,
        onPrimary: backgroundDark,
        onBackground: contentLight,
        onSurface: contentLight,
        secondary: subtleLight,
      ),
      scaffoldBackgroundColor: backgroundLight,
      fontFamily: 'BeVietnamPro',
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundLight,
        foregroundColor: contentLight,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: contentLight,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          fontFamily: 'BeVietnamPro',
        ),
      ),
      cardTheme: CardThemeData(
        color: backgroundLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: primary.withValues(alpha: 0.2)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: backgroundDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9999),
          ),
          elevation: 0,
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'BeVietnamPro',
          ),
        ),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: contentLight, fontFamily: 'BeVietnamPro'),
        bodyMedium: TextStyle(color: contentLight, fontFamily: 'BeVietnamPro'),
        titleLarge: TextStyle(
          color: contentLight,
          fontWeight: FontWeight.bold,
          fontFamily: 'BeVietnamPro',
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.dark,
        primary: primary,
        background: backgroundDark,
        surface: backgroundDark,
        onPrimary: backgroundLight,
        onBackground: contentDark,
        onSurface: contentDark,
        secondary: subtleDark,
      ),
      scaffoldBackgroundColor: backgroundDark,
      fontFamily: 'BeVietnamPro',
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundDark,
        foregroundColor: contentDark,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: contentDark,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          fontFamily: 'BeVietnamPro',
        ),
      ),
      cardTheme: CardThemeData(
        color: backgroundDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: primary.withValues(alpha: 0.3)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: backgroundDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9999),
          ),
          elevation: 0,
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'BeVietnamPro',
          ),
        ),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: contentDark, fontFamily: 'BeVietnamPro'),
        bodyMedium: TextStyle(color: contentDark, fontFamily: 'BeVietnamPro'),
        titleLarge: TextStyle(
          color: contentDark,
          fontWeight: FontWeight.bold,
          fontFamily: 'BeVietnamPro',
        ),
      ),
    );
  }
}