import 'package:flutter/material.dart';

// Colors modeled after Zerodha Kite's minimal palette
class AppColors {
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF7F7F7);
  static const Color primaryText = Color(0xFF2B2B2B);
  static const Color secondaryText = Color(0xFF8C8C8C);
  static const Color kiteBlue = Color(0xFF387ED1);
  static const Color positiveGreen = Color(0xFF2AAE59);
  static const Color negativeRed = Color(0xFFE53935);
  static const Color divider = Color(0xFFE8E8E8);
}

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Roboto',
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.kiteBlue,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.primaryText,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.primaryText,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      dividerColor: AppColors.divider,
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: AppColors.primaryText, fontSize: 14),
        bodySmall: TextStyle(color: AppColors.secondaryText, fontSize: 12),
      ),
    );
  }

  static Color pnlColor(double value) =>
      value >= 0 ? AppColors.positiveGreen : AppColors.negativeRed;
}
