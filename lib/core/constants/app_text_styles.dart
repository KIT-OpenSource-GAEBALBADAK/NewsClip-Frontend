// styles/globals.css (타이포그래피) 변환
import 'package:flutter/material.dart';

class AppTextStyles {
  static const String fontFamily = 'Pretendard';
  
  // Heading Styles (globals.css h1-h4)
  static const TextStyle h1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,      // --text-2xl (1.5rem)
    fontWeight: FontWeight.w500,  // --font-weight-medium
    height: 1.5,
    letterSpacing: 0,
  );
  
  static const TextStyle h2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,      // --text-xl (1.25rem)
    fontWeight: FontWeight.w500,
    height: 1.5,
    letterSpacing: 0,
  );
  
  static const TextStyle h3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,      // --text-lg (1.125rem)
    fontWeight: FontWeight.w500,
    height: 1.5,
    letterSpacing: 0,
  );
  
  static const TextStyle h4 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,      // --text-base (1rem)
    fontWeight: FontWeight.w500,
    height: 1.5,
    letterSpacing: 0,
  );
  
  // Body Styles (globals.css p)
  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,  // --font-weight-normal
    height: 1.5,
    letterSpacing: 0,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,      // --text-sm (0.875rem)
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0,
  );
  
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,      // --text-xs (0.75rem)
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0,
  );
  
  // Button Style (globals.css button)
  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.5,
    letterSpacing: 0,
  );
}
