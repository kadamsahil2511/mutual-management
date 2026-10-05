import 'package:flutter/material.dart';

abstract final class AppColors {
  static const primary = Color(0xff0052ff);
  static const primaryActive = Color(0xff003ecc);
  static const primaryDisabled = Color(0xffa8b8cc);
  static const canvas = Color(0xffffffff);
  static const soft = Color(0xfff7f7f7);
  static const strong = Color(0xffeef0f3);
  static const dark = Color(0xff0a0b0d);
  static const darkElevated = Color(0xff16181c);
  static const hairline = Color(0xffdee1e6);
  static const ink = Color(0xff0a0b0d);
  static const body = Color(0xff5b616e);
  static const muted = Color(0xff7c828a);
  static const onDarkSoft = Color(0xffa8acb3);
  static const up = Color(0xff05b169);
  static const down = Color(0xffcf202f);
  static const yellow = Color(0xfff4b000);
}

abstract final class AppSpacing {
  static const double xxs = 4,
      xs = 8,
      sm = 12,
      base = 16,
      md = 20,
      lg = 24,
      xl = 32,
      xxl = 48,
      section = 96;
}

TextStyle numberStyle({double size = 18, Color? color}) => TextStyle(
  fontFamily: 'JetBrains Mono',
  fontSize: size,
  fontWeight: FontWeight.w500,
  color: color ?? AppColors.ink,
  height: 1.4,
);

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: AppColors.primary).copyWith(
    primary: AppColors.primary,
    onPrimary: Colors.white,
    surface: Colors.white,
    onSurface: AppColors.ink,
    error: AppColors.down,
  );
  final pill = RoundedRectangleBorder(borderRadius: BorderRadius.circular(100));
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'Inter',
    scaffoldBackgroundColor: AppColors.canvas,
    visualDensity: VisualDensity.standard,
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 80,
        fontWeight: FontWeight.w400,
        height: 1,
        letterSpacing: -2,
      ),
      displayMedium: TextStyle(
        fontSize: 64,
        fontWeight: FontWeight.w400,
        height: 1,
        letterSpacing: -1.6,
      ),
      displaySmall: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        height: 1.11,
        letterSpacing: -.5,
      ),
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w400,
        height: 1.13,
      ),
      headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w400),
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(fontSize: 16, height: 1.5, color: AppColors.body),
      bodyMedium: TextStyle(fontSize: 14, height: 1.5, color: AppColors.body),
      labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: pill,
        disabledBackgroundColor: AppColors.primaryDisabled,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: pill,
        side: const BorderSide(color: AppColors.hairline),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: pill,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.hairline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.hairline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.hairline),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.hairline,
      thickness: 1,
    ),
    chipTheme: ChipThemeData(
      shape: const StadiumBorder(),
      side: const BorderSide(color: AppColors.hairline),
      backgroundColor: AppColors.strong,
      selectedColor: AppColors.strong,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primary,
      linearTrackColor: AppColors.strong,
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
