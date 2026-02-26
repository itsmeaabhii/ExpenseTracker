import 'package:flutter/material.dart';

// Dark theme colors - Pure Black Theme
class DarkColors {
  DarkColors._();
  
  static const Color background = Color(0xFF000000);
  static const Color surface = Color(0xFF0D0D0D);
  static const Color surfaceVariant = Color(0xFF1A1A1A);
  static const Color surfaceHighlight = Color(0xFF252525);
  static const Color primary = Color(0xFFFFFFFF);
  static const Color secondary = Color(0xFFB0B0B0);
  static const Color onBackground = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFFE8E8E8);
  static const Color onSurfaceVariant = Color(0xFF999999);
  static const Color onSurfaceVariantDim = Color(0xFF666666);
  static const Color positive = Color(0xFF4CAF50);
  static const Color negative = Color(0xFFEF5350);
  static const Color accent = Color(0xFF42A5F5);
  static const Color border = Color(0xFF2A2A2A);
}

ThemeData buildAppTheme({bool isDark = false}) {
  if (isDark) {
    return _buildDarkTheme();
  }
  return _buildLightTheme();
}

ThemeData _buildLightTheme() {
  const baseColorScheme = ColorScheme.light(
    primary: Colors.black,
    secondary: Colors.grey,
    background: Colors.white,
    surface: Colors.white,
    error: Colors.red,
  );

  final base = ThemeData.from(colorScheme: baseColorScheme);

  return base.copyWith(
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.w600,
        fontSize: 20,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.grey,
      backgroundColor: Colors.white,
      type: BottomNavigationBarType.fixed,
      selectedIconTheme: IconThemeData(size: 24),
      unselectedIconTheme: IconThemeData(size: 22),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey.shade100,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.black, width: 1.4),
      ),
      labelStyle: TextStyle(
        color: Colors.grey.shade600,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      elevation: 0,
      margin: EdgeInsets.zero,
    ),
    textTheme: base.textTheme.copyWith(
      headlineSmall: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      ),
      titleMedium: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      ),
      bodyMedium: const TextStyle(
        fontSize: 14,
        color: Colors.black87,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        color: Colors.grey.shade600,
      ),
    ),
  );
}

ThemeData _buildDarkTheme() {
  const baseColorScheme = ColorScheme.dark(
    primary: DarkColors.primary,
    secondary: DarkColors.secondary,
    surface: DarkColors.surface,
    error: DarkColors.negative,
    onPrimary: Colors.black,
    onSecondary: Colors.black,
    onSurface: DarkColors.onSurface,
    onError: Colors.white,
    brightness: Brightness.dark,
  );

  final base = ThemeData.from(colorScheme: baseColorScheme);

  return base.copyWith(
    scaffoldBackgroundColor: DarkColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: DarkColors.background,
      foregroundColor: DarkColors.onBackground,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: DarkColors.onBackground,
        fontWeight: FontWeight.w600,
        fontSize: 20,
      ),
      iconTheme: IconThemeData(color: DarkColors.onBackground),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: DarkColors.primary,
      unselectedItemColor: DarkColors.onSurfaceVariant,
      backgroundColor: DarkColors.surface,
      type: BottomNavigationBarType.fixed,
      selectedIconTheme: IconThemeData(size: 24),
      unselectedIconTheme: IconThemeData(size: 22),
      elevation: 8,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: DarkColors.primary,
      foregroundColor: Colors.black,
      elevation: 6,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: DarkColors.primary,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: DarkColors.primary,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: DarkColors.primary,
        foregroundColor: Colors.black,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: DarkColors.surfaceVariant,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: DarkColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: DarkColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: DarkColors.primary, width: 1.4),
      ),
      labelStyle: const TextStyle(
        color: DarkColors.onSurfaceVariant,
      ),
      hintStyle: const TextStyle(
        color: DarkColors.onSurfaceVariantDim,
      ),
      iconColor: DarkColors.onSurfaceVariant,
    ),
    cardTheme: CardThemeData(
      color: DarkColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: DarkColors.border, width: 0.5),
      ),
      elevation: 0,
      margin: EdgeInsets.zero,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: DarkColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: DarkColors.surface,
      modalBackgroundColor: DarkColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    ),
    textTheme: base.textTheme.copyWith(
      headlineSmall: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: DarkColors.onBackground,
      ),
      titleMedium: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: DarkColors.onBackground,
      ),
      bodyMedium: const TextStyle(
        fontSize: 14,
        color: DarkColors.onSurface,
      ),
      bodySmall: const TextStyle(
        fontSize: 12,
        color: DarkColors.onSurfaceVariant,
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: DarkColors.border,
      space: 1,
      thickness: 0.5,
    ),
    iconTheme: const IconThemeData(
      color: DarkColors.onSurface,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: DarkColors.surfaceVariant,
      selectedColor: DarkColors.primary,
      labelStyle: const TextStyle(color: DarkColors.onSurface),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: DarkColors.border),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: DarkColors.primary,
    ),
  );
}

