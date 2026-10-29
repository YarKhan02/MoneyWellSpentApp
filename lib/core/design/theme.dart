import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'tokens.dart';

/// Builds the single light Forest & Sunrise [ThemeData].
/// Colour and spacing values come from [Brand] / [AppTokens] — nothing is
/// hardcoded here that a token could express.
ThemeData buildAppTheme() {
  final scheme = _colorScheme();
  final textTheme = _textTheme(scheme.onSurface);
  final onSurface = scheme.onSurface;

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'PlusJakartaSans',
    scaffoldBackgroundColor: scheme.surface,
    extensions: const [AppTokens.light],
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      foregroundColor: onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Brand.hay,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      // Transparent — the floating glass container in AppShell is the surface.
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      indicatorColor: Brand.forest.withValues(alpha: .16),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(
          color: s.contains(WidgetState.selected)
              ? Brand.forest
              : scheme.onSurface,
        ),
      ),
      labelTextStyle: WidgetStateProperty.all(textTheme.labelMedium),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Brand.ivory,
      border: _inputBorder(scheme.outlineVariant),
      enabledBorder: _inputBorder(scheme.outlineVariant),
      focusedBorder: _inputBorder(Brand.forest, width: 2),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: Brand.lg,
        vertical: Brand.md,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Brand.forest,
        foregroundColor: Colors.white,
        minimumSize: const Size(Brand.minTouchTarget, Brand.buttonHeight),
        textStyle: textTheme.titleMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Brand.buttonRadius),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Brand.forest,
        minimumSize: const Size(Brand.minTouchTarget, Brand.minTouchTarget),
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Brand.buttonRadius),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: Brand.forest),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.white,
      selectedColor: Brand.forest,
      side: BorderSide(color: scheme.outlineVariant),
      shape: const StadiumBorder(),
      labelStyle: TextStyle(color: onSurface, fontWeight: FontWeight.w600),
      secondaryLabelStyle: const TextStyle(color: Colors.white),
      showCheckmark: false,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Brand.cardRadius),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: AppTokens.light.divider,
      thickness: 1,
      space: 1,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Brand.hay,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Brand.sheetRadius),
        ),
      ),
      clipBehavior: Clip.antiAlias,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Brand.ivory,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Brand.cardRadius),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      minVerticalPadding: Brand.md,
      visualDensity: VisualDensity.standard,
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Brand.earth,
      contentTextStyle: TextStyle(color: Brand.hay),
      actionTextColor: Brand.wheat,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Brand.forest,
      foregroundColor: Colors.white,
    ),
  );
}

ColorScheme _colorScheme() =>
    ColorScheme.fromSeed(
      seedColor: Brand.forest,
      brightness: Brightness.light,
    ).copyWith(
      primary: Brand.forest,
      onPrimary: Colors.white,
      secondary: Brand.wheat,
      onSecondary: Brand.earth,
      tertiary: Brand.cherry,
      surface: Brand.hay,
      onSurface: Brand.earth,
      surfaceContainerLowest: Brand.hay,
      surfaceContainer: Brand.ivory,
      surfaceContainerHighest: const Color(0xFFFBF4E6),
      outlineVariant: const Color(0x22133020),
      error: const Color(0xFFA12D14),
    );

OutlineInputBorder _inputBorder(Color color, {double width = 1}) =>
    OutlineInputBorder(
      borderRadius: BorderRadius.circular(Brand.inputRadius),
      borderSide: BorderSide(color: color, width: width),
    );

TextTheme _textTheme(Color onSurface) => TextTheme(
  /// Primary financial amount — the one number a screen is about.
  displaySmall: const TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.05,
    fontFeatures: [FontFeature.tabularFigures()],
  ),

  /// Onboarding headline only.
  headlineLarge: const TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w700,
    height: 1.1,
    fontFeatures: [FontFeature.tabularFigures()],
  ),

  /// Page title.
  headlineMedium: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
  headlineSmall: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),

  /// Section heading.
  titleLarge: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600),

  /// Card title, list row title, transaction amount.
  titleMedium: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
  bodyLarge: const TextStyle(fontSize: 15, height: 1.4),
  bodyMedium: const TextStyle(fontSize: 14, height: 1.35),
  labelLarge: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
  labelMedium: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
).apply(bodyColor: onSurface, displayColor: onSurface);
