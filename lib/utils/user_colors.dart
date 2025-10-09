import 'package:flutter/material.dart';

class UserColors {
  // Predefined set of attractive colors for users
  static const List<Color> _colors = [
    Color(0xFF6366F1), // Indigo
    Color(0xFF8B5CF6), // Violet
    Color(0xFFEC4899), // Pink
    Color(0xFFF59E0B), // Amber
    Color(0xFF10B981), // Emerald
    Color(0xFF06B6D4), // Cyan
    Color(0xFFEF4444), // Red
    Color(0xFF84CC16), // Lime
    Color(0xFF3B82F6), // Blue
    Color(0xFF8B5CF6), // Purple
    Color(0xFFF97316), // Orange
    Color(0xFF14B8A6), // Teal
  ];

  // Generate a consistent color for a user based on their ID
  static Color getUserColor(String userId) {
    // Use a simple hash function to get a consistent color for each user
    int hash = 0;
    for (int i = 0; i < userId.length; i++) {
      hash = userId.codeUnitAt(i) + ((hash << 5) - hash);
    }
    
    // Use absolute value to ensure positive index
    int colorIndex = hash.abs() % _colors.length;
    return _colors[colorIndex];
  }

  // Get a lighter version of the user color for backgrounds
  static Color getUserColorLight(String userId) {
    return getUserColor(userId).withOpacity(0.1);
  }

  // Get a darker version of the user color for text
  static Color getUserColorDark(String userId) {
    final color = getUserColor(userId);
    return Color.fromARGB(
      255,
      (color.red * 0.8).round(),
      (color.green * 0.8).round(),
      (color.blue * 0.8).round(),
    );
  }

  // Check if a color is light or dark to determine text color
  static bool isColorLight(Color color) {
    final luminance = (0.299 * color.red + 0.587 * color.green + 0.114 * color.blue) / 255;
    return luminance > 0.5;
  }

  // Get appropriate text color for a background color
  static Color getTextColorForBackground(Color backgroundColor) {
    return isColorLight(backgroundColor) ? Colors.black87 : Colors.white;
  }
}