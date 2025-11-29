import 'dart:ui';

import 'package:flutter/material.dart';

class AppColors {
  // Primary gradient colors
  static const Color primaryGradientStart = Color(0xFF026948);
  static const Color primaryGradientEnd = Color(0xFF07B17A);
  
  // Background colors
  static const Color lightBackground = Color(0xFFCEF0E6);
  static const Color darkBackground = Color(0xFF03031E);
  
  // Additional theme colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey = Color(0xFF9E9E9E);
  static const Color lightGrey = Color(0xFFF5F5F5);
  static const Color darkGrey = Color(0xFF424242);
  
  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF44336);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);
}

class AppTheme {
  // Light theme configuration
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primarySwatch: const MaterialColor(0xFF07B17A, {
        50: Color(0xFFE8F5E8),
        100: Color(0xFFC8E6C9),
        200: Color(0xFFA5D6A7),
        300: Color(0xFF81C784),
        400: Color(0xFF66BB6A),
        500: Color(0xFF4CAF50),
        600: Color(0xFF43A047),
        700: Color(0xFF388E3C),
        800: Color(0xFF2E7D32),
        900: Color(0xFF1B5E20),
      }),
      scaffoldBackgroundColor: AppColors.lightBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryGradientStart,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGradientStart,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      cardTheme: CardTheme(
        color: AppColors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // Dark theme configuration
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primarySwatch: MaterialColor(0xFF07B17A, {
        50: Color(0xFFE8F5E8),
        100: Color(0xFFC8E6C9),
        200: Color(0xFFA5D6A7),
        300: Color(0xFF81C784),
        400: Color(0xFF66BB6A),
        500: Color(0xFF4CAF50),
        600: Color(0xFF43A047),
        700: Color(0xFF388E3C),
        800: Color(0xFF2E7D32),
        900: Color(0xFF1B5E20),
      }),
      scaffoldBackgroundColor: AppColors.darkBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGradientStart,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      cardTheme: CardTheme(
        color: AppColors.darkGrey,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class AppTextStyles {
  // Title text styles
  // static TextStyle get titleLarge => TextStyle();
  // static TextStyle get titleMedium => TextStyle();
  // static TextStyle get titleSmall => TextStyle();
  
  // Subtitle text styles
  // static TextStyle get subtitleLarge => TextStyle();
  // static TextStyle get subtitleMedium => TextStyle();
  // static TextStyle get subtitleSmall => TextStyle();
  
  // Body text styles
  // static TextStyle get bodyLarge => TextStyle();
  // static TextStyle get bodyMedium => TextStyle();
  // static TextStyle get bodySmall => TextStyle();
  
  // Button text styles
  // static TextStyle get buttonLarge => TextStyle();
  // static TextStyle get buttonMedium => TextStyle();
  // static TextStyle get buttonSmall => TextStyle();
}

class AppGradients {
  // Primary gradient for reusable components
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      AppColors.primaryGradientStart,
      AppColors.primaryGradientEnd,
    ],
  );
  
  // Additional gradient variations
  // static const LinearGradient lightGradient = LinearGradient();
  // static const LinearGradient darkGradient = LinearGradient();
  // static const LinearGradient cardGradient = LinearGradient();
}
