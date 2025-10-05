import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF8CE830);
  static const Color backgroundLight = Color(0xFFF7F8F6);
  static const Color backgroundDark = Color(0xFF192111);
  static const Color contentLight = Color(0xFF192111);
  static const Color contentDark = Color(0xFFF7F8F6);
  static const Color subtleLight = Color(0xFF3B4D28);
  static const Color subtleDark = Color(0xFFC0EEA7);

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