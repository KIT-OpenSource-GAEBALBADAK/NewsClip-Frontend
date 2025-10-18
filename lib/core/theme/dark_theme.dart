// styles/globals.css (.dark) 변환
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_dimensions.dart';

final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  fontFamily: AppTextStyles.fontFamily,
  
  scaffoldBackgroundColor: AppColors.darkBackground,
  
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFFA855F7),
    secondary: Color(0xFFF472B6),
    surface: AppColors.darkCard,
    error: AppColors.like,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: AppColors.darkForeground,
    onError: Colors.white,
  ),
  
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.darkBackground,
    foregroundColor: AppColors.darkForeground,
    elevation: 0,
    centerTitle: false,
    titleTextStyle: TextStyle(
      fontFamily: AppTextStyles.fontFamily,
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: AppColors.darkForeground,
    ),
  ),
  
  cardTheme: CardThemeData(
    color: AppColors.darkCard,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
      side: const BorderSide(color: AppColors.darkBorder, width: 1),
    ),
    shadowColor: Colors.black.withOpacity(0.2),
  ),
  
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: AppColors.darkBackground,
    selectedItemColor: Color(0xFFA855F7),
    unselectedItemColor: AppColors.darkMutedForeground,
    type: BottomNavigationBarType.fixed,
    elevation: 0,
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
      backgroundColor: const Color(0xFFA855F7),
      foregroundColor: Colors.white,
      textStyle: AppTextStyles.button,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
      ),
    ),
  ),
  
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.darkMuted,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
      borderSide: const BorderSide(color: AppColors.darkBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
      borderSide: const BorderSide(color: AppColors.darkBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
      borderSide: const BorderSide(color: Color(0xFFA855F7), width: 2),
    ),
  ),
);
