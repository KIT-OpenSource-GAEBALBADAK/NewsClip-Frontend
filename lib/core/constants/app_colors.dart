// styles/globals.css 변환
import 'package:flutter/material.dart';

class AppColors {
  // Primary Gradient Colors (--gradient-primary)
  static const Color primaryStart = Color(0xFF8B5CF6); // #8B5CF6
  static const Color primaryEnd = Color(0xFFEC4899);   // #EC4899
  
  // Light Theme Colors (:root)
  static const Color lightBackground = Color(0xFFFFFFFF);      // --background
  static const Color lightForeground = Color(0xFF1A1A1A);      // --foreground
  static const Color lightCard = Color(0xFFFFFFFF);            // --card
  static const Color lightMuted = Color(0xFFF8F7FF);           // --muted
  static const Color lightMutedForeground = Color(0xFF6B6B84); // --muted-foreground
  static const Color lightAccent = Color(0xFFF3F1FF);          // --accent
  static const Color lightBorder = Color(0x268B5CF6);          // rgba(139, 92, 246, 0.15)
  static const Color lightInputBackground = Color(0xFFF8F7FF); // --input-background
  
  // Dark Theme Colors (.dark)
  static const Color darkBackground = Color(0xFF1A1A1A);       // --background (dark)
  static const Color darkForeground = Color(0xFFFAFAFA);       // --foreground (dark)
  static const Color darkCard = Color(0xFF1A1A1A);             // --card (dark)
  static const Color darkMuted = Color(0xFF2A2A35);            // --muted (dark)
  static const Color darkMutedForeground = Color(0xFFB5B5B5);  // --muted-foreground (dark)
  static const Color darkAccent = Color(0xFF2A2A35);           // --accent (dark)
  static const Color darkBorder = Color(0x33A855F7);           // rgba(168, 85, 247, 0.2)
  
  // Action Colors
  static const Color like = Color(0xFFD4183D);        // --destructive (좋아요)
  static const Color dislike = Color(0xFF10B981);     // --dislike (싫어요)
  static const Color info = Color(0xFF0EA5E9);        // --chart-5
  static const Color warning = Color(0xFFF59E0B);
  static const Color success = Color(0xFF10B981);
  
  // Secondary Gradient Colors
  static const Color secondaryStart = Color(0xFF7C3AED); // --chart-3
  static const Color secondaryEnd = Color(0xFFBE185D);   // --chart-4
  
  // Gradients (--gradient-primary, --gradient-secondary)
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryStart, primaryEnd],
  );
  
  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondaryStart, secondaryEnd],
  );
  
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryEnd, info],
  );
}
