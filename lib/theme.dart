import 'package:flutter/material.dart';

/// 全局主题：温暖的橙色系，符合"宝宝/亲子"的视觉感觉。
/// 颜色集中管理，改一处全 App 生效。
class AppTheme {
  static const Color primary = Color(0xFFF2874A);   // 主色：暖橙
  static const Color primaryDark = Color(0xFFD9662E);
  static const Color accent = Color(0xFF5FB3A0);    // 辅色：青绿
  static const Color background = Color(0xFFFFF8F2); // 背景：奶白
  static const Color card = Colors.white;

  // 语义色：营养达标 / 偏低 / 偏高
  static const Color good = Color(0xFF4CAF50);
  static const Color low = Color(0xFFFF9800);
  static const Color high = Color(0xFFE53935);

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: accent,
      ),
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}
