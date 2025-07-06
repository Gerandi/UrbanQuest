import 'package:flutter/material.dart';

/// Centralized color constants for Urban Quest
/// These colors match the theme defined in main.dart
class AppColors {
  // Primary Brand Colors (matches main.dart theme)
  static const Color primary = Color(0xFFf97316); // Orange-500
  static const Color secondary = Color(0xFFef4444); // Red-500  
  static const Color accent = Color(0xFFec4899); // Pink-500

  // Gradient colors for splash/backgrounds
  static const List<Color> primaryGradient = [
    Color(0xFFf97316), // Orange-500
    Color(0xFFef4444), // Red-500
    Color(0xFFec4899), // Pink-500
  ];

  // Common UI colors
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color transparent = Colors.transparent;

  // Opacity variations for glassmorphism effects
  static Color whiteOpacity10 = Colors.white.withOpacity(0.1);
  static Color whiteOpacity20 = Colors.white.withOpacity(0.2);
  static Color whiteOpacity30 = Colors.white.withOpacity(0.3);
  static Color whiteOpacity60 = Colors.white.withOpacity(0.6);
  static Color whiteOpacity80 = Colors.white.withOpacity(0.8);
  static Color whiteOpacity90 = Colors.white.withOpacity(0.9);
  
  static Color blackOpacity10 = Colors.black.withOpacity(0.1);
  static Color blackOpacity20 = Colors.black.withOpacity(0.2);

  // Text colors
  static const Color textPrimary = Color(0xFF1a1a1a);
  static const Color textSecondary = Color(0xFF6b7280);
  static const Color textLight = Color(0xFF9ca3af);

  // Helper function to get theme-aware colors
  static ColorScheme getColorScheme(BuildContext context) {
    return Theme.of(context).colorScheme;
  }
} 