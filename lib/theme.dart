import 'package:flutter/material.dart';

ThemeData buildKdmpTheme() {
  const primary = Color(0xFFD9001B);
  const surface = Color(0xFFF8F9FA);
  const surfaceLow = Color(0xFFFFFFFF);
  const outline = Color(0xFFE8BCB8);
  const onSurface = Color(0xFF191C1D);

  final base = Typography.material2021().black;
  final textTheme = base.copyWith(
    displayLarge: base.displayLarge?.copyWith(
      fontSize: 44,
      fontWeight: FontWeight.w700,
      letterSpacing: -1.2,
      color: onSurface,
    ),
    headlineLarge: base.headlineLarge?.copyWith(
      fontSize: 31,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.8,
      color: onSurface,
    ),
    headlineMedium: base.headlineMedium?.copyWith(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: onSurface,
    ),
    titleLarge: base.titleLarge?.copyWith(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: onSurface,
    ),
    bodyLarge: base.bodyLarge?.copyWith(
      fontSize: 16,
      height: 1.45,
      color: onSurface,
    ),
    bodyMedium: base.bodyMedium?.copyWith(
      fontSize: 14,
      height: 1.45,
      color: onSurface,
    ),
    labelLarge: base.labelLarge?.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: onSurface,
    ),
    labelMedium: base.labelMedium?.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: const Color(0xFF6D5A58),
    ),
  );

  final colorScheme = ColorScheme.fromSeed(
    seedColor: primary,
    brightness: Brightness.light,
    primary: primary,
    surface: surface,
    outline: outline,
  ).copyWith(
    surface: surface,
    onSurface: onSurface,
    secondary: const Color(0xFF5D5F5F),
    tertiary: const Color(0xFFE9C400),
    error: const Color(0xFFBA1A1A),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: surface,
    fontFamily: 'sans-serif',
    textTheme: textTheme,
    cardTheme: const CardThemeData(
      color: surfaceLow,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(24)),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: surface,
      foregroundColor: primary,
      centerTitle: false,
      elevation: 0,
      titleTextStyle: textTheme.headlineMedium?.copyWith(color: primary),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceLow,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      hintStyle: textTheme.bodyLarge?.copyWith(color: const Color(0xFF7F8084)),
      prefixIconColor: const Color(0xFF7F8084),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: surfaceLow,
      selectedColor: primary.withValues(alpha: 0.12),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      labelStyle: textTheme.labelLarge ?? const TextStyle(),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      type: BottomNavigationBarType.fixed,
      backgroundColor: surfaceLow,
      selectedItemColor: primary,
      unselectedItemColor: Color(0xFF735A56),
      showUnselectedLabels: true,
      elevation: 0,
    ),
  );
}
