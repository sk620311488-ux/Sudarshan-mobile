import 'package:flutter/material.dart';

class AppColors {
  static const window = Color(0xFFEFE8E4);
  static const surface = Color(0xFFFBF7F3);
  static const white = Color(0xFFFFFFFF);
  static const text = Color(0xFF2F2A26);
  static const muted = Color(0xFF746B65);
  static const line = Color(0xFFE5D9CF);
  static const yellow = Color(0xFFF7D37A);
  static const yellowSoft = Color(0xFFFFF1C7);
  static const green = Color(0xFF7CBC7E);
  static const greenSoft = Color(0xFFE5F3D8);
  static const blue = Color(0xFF95BCE0);
  static const blueSoft = Color(0xFFE4EDF9);
  static const coralSoft = Color(0xFFFDE2D8);
  static const coral = Color(0xFFE8785A);
  static const teal = Color(0xFF59B6A9);
  static const tealSoft = Color(0xFFDBF3EF);
  static const accent = Color(0xFFA8CA46);

  // Dark Mode Colors
  static const windowDark = Color(0xFF0F0E0D);
  static const surfaceDark = Color(0xFF1A1715);
  static const textDark = Color(0xFFEBE3DE);
  static const mutedDark = Color(0xFF91857D);
  static const lineDark = Color(0xFF2B2623);
  static const yellowDark = Color(0xFF5A4A28);
  static const greenDark = Color(0xFF2D442E);
  static const blueDark = Color(0xFF2A3A4A);
  static const coralDark = Color(0xFF4A2A22);
  static const tealDark = Color(0xFF1A4440);
}

ThemeData buildSudarshanTheme({bool isDark = false}) {
  final colorScheme = ColorScheme.light(
    primary: AppColors.accent,
    secondary: AppColors.teal,
    surface: isDark ? AppColors.surfaceDark : AppColors.surface,
    onPrimary: AppColors.white,
    onSecondary: AppColors.white,
    onSurface: isDark ? AppColors.textDark : AppColors.text,
    onSurfaceVariant: isDark ? AppColors.mutedDark : AppColors.muted,
    brightness: isDark ? Brightness.dark : Brightness.light,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: isDark ? AppColors.windowDark : AppColors.window,
    cardColor: isDark ? AppColors.surfaceDark : AppColors.white,
    dividerColor: isDark ? AppColors.lineDark : AppColors.line,
    appBarTheme: AppBarTheme(
      backgroundColor: isDark ? AppColors.windowDark : AppColors.window,
      surfaceTintColor: Colors.transparent,
      foregroundColor: isDark ? AppColors.textDark : AppColors.text,
      elevation: 0,
      centerTitle: false,
    ),
    textTheme: TextTheme(
      headlineLarge: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w800,
          color: isDark ? AppColors.textDark : AppColors.text,
          height: 1.05),
      headlineMedium: TextStyle(
          fontSize: 26, fontWeight: FontWeight.w800, color: isDark ? AppColors.textDark : AppColors.text),
      titleLarge: TextStyle(
          fontSize: 20, fontWeight: FontWeight.w700, color: isDark ? AppColors.textDark : AppColors.text),
      titleMedium: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? AppColors.textDark : AppColors.text),
      bodyLarge: TextStyle(fontSize: 15, color: isDark ? AppColors.textDark : AppColors.text, height: 1.35),
      bodyMedium: TextStyle(fontSize: 13, color: isDark ? AppColors.mutedDark : AppColors.muted, height: 1.35),
      labelLarge: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w700, color: isDark ? AppColors.textDark : AppColors.text),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
      indicatorColor: isDark ? AppColors.accent.withValues(alpha: 0.2) : AppColors.yellowSoft,
      iconTheme: WidgetStatePropertyAll(IconThemeData(color: isDark ? AppColors.textDark : AppColors.text)),
      labelTextStyle:
          WidgetStatePropertyAll(TextStyle(fontWeight: FontWeight.w700, color: isDark ? AppColors.textDark : AppColors.text)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: isDark ? AppColors.textDark : AppColors.text,
        side: BorderSide(color: isDark ? AppColors.lineDark : AppColors.line),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark ? AppColors.surfaceDark : AppColors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: isDark ? AppColors.lineDark : AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: isDark ? AppColors.lineDark : AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: isDark ? AppColors.accent : AppColors.text, width: 1.2),
      ),
    ),
  );
}
