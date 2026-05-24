import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryGreen = Color(0xFF1E824C);
  static const Color lightGreen = Color(0xFFF4F8F5);
  static const Color darkBg = Color(0xFF121212);
  static const Color white = Colors.white;
  static const Color gold = Color(0xFFFFC107);
  static const Color textDark = Color(0xFF212121);
  static const Color textGrey = Color(0xFF757575);
  static const Color textLight = Color(0xFF9E9E9E);
  static const Color accentGreen = Color(0xFF4CAF50);
  static const Color errorRed = Color(0xFFD32F2F);
  static const Color divider = Color(0xFFE0E0E0);
  
  static const Gradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1A6B3C),
      Color(0xFF0D3D21),
    ],
  );
}
