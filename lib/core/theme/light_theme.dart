// styles/globals.css (:root) 변환
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_dimensions.dart';

final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  fontFamily: AppTextStyles.fontFamily,
  
  scaffoldBackgroundColor: AppColors.lightBackground,
  
  colorScheme: const ColorScheme.light(
    primary: AppColors.primaryStart,
    secondary: AppColors.primaryEnd,
    surface: AppColors.lightCard,
    error: AppColors.like,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: AppColors.lightForeground,
    onError: Colors.white,
  ),
  
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: AppColors.lightForeground,
    elevation: 0,
    centerTitle: false,
    titleTextStyle: TextStyle(
      fontFamily: AppTextStyles.fontFamily,
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: AppColors.lightForeground,
    ),
  ),
  
  cardTheme: CardThemeData(
    color: AppColors.lightCard,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
      side: const BorderSide(color: AppColors.lightBorder, width: 1),
    ),
    shadowColor: AppColors.primaryStart.withOpacity(0.08),
  ),
  
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Colors.white,
    selectedItemColor: AppColors.primaryStart,
    unselectedItemColor: AppColors.lightMutedForeground,
    type: BottomNavigationBarType.fixed,
    elevation: 0,
    selectedLabelStyle: TextStyle(
      fontFamily: AppTextStyles.fontFamily,
      fontSize: 12,
      fontWeight: FontWeight.w600,
    ),
    unselectedLabelStyle: TextStyle(
      fontFamily: AppTextStyles.fontFamily,
      fontSize: 12,
      fontWeight: FontWeight.w400,
    ),
  ),
  
  textTheme: const TextTheme(
    displayLarge: AppTextStyles.h1,
    displayMedium: AppTextStyles.h2,
    displaySmall: AppTextStyles.h3,
    headlineMedium: AppTextStyles.h4,
    bodyLarge: AppTextStyles.body,
    bodyMedium: AppTextStyles.bodySmall,
    labelLarge: AppTextStyles.button,
    bodySmall: AppTextStyles.caption,
  ),
  
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primaryStart,
      foregroundColor: Colors.white,
      textStyle: AppTextStyles.button,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingXL,
        vertical: AppDimensions.spacingSM,
      ),
    ),
  ),
  
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.lightInputBackground,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
      borderSide: const BorderSide(color: AppColors.lightBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
      borderSide: const BorderSide(color: AppColors.lightBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
      borderSide: const BorderSide(color: AppColors.primaryStart, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppDimensions.spacingMD,
      vertical: AppDimensions.spacingSM,
    ),
  ),
);
