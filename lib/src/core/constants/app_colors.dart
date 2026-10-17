import 'package:flutter/material.dart';

class AppColors {
  static const Color primary    = Color(0xFFFF7043);
  static const Color primaryDim = Color(0xFFFFF3EF);
  static const Color primaryMid = Color(0xFFFFE0D6);

  static const Color background  = Color(0xFFFFFFFF);
  static const Color surface     = Color(0xFFFFFFFF);
  static const Color surfaceGrey = Color(0xFFF7F7F7);
  static const Color divider     = Color(0xFFEEEEEE);
  static const Color border      = Color(0xFFE8E8E8);

  static const Color text1 = Color(0xFF0F0F0F);
  static const Color text2 = Color(0xFF5A5A5A);
  static const Color text3 = Color(0xFF9B9B9B);

  // Aliases for compatibility
  static const Color textPrimary   = text1;
  static const Color textSecondary = text2;
  static const Color textTertiary  = text3;
  static const Color cardBorder    = border;
  static const Color surfaceVariant = surfaceGrey;
  static const Color accentLight   = primaryDim;
  static const Color accent        = primary;

  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error   = Color(0xFFEF4444);
  static const Color info    = Color(0xFF3B82F6);

  static const Color shadow = Color(0x1A000000); // black @ ~10% opacity
}
