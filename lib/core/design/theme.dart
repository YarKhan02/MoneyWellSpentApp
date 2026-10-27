import 'dart:ui';
import 'package:flutter/material.dart';

abstract final class Brand {
  static const forest = Color(0xFF327039);
  static const wheat = Color(0xFFF0BE49);
  static const earth = Color(0xFF133020);
  static const hay = Color(0xFFF8EDD9);
  static const cherry = Color(0xFFDD5C36);
  static const muted = Color(0xFF49614F);
  static const spacing = 24.0;
  static const radius = 24.0;

  static ThemeData theme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: forest,
          brightness: brightness,
        ).copyWith(
          primary: dark ? wheat : forest,
          onPrimary: dark ? earth : Colors.white,
          surface: dark ? earth : hay,
          onSurface: dark ? hay : earth,
          error: dark ? const Color(0xFFFFB5A0) : const Color(0xFFA12D14),
        );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'PlusJakartaSans',
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        centerTitle: false,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
        headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(fontSize: 16, height: 1.4),
        bodyMedium: TextStyle(fontSize: 15, height: 1.4),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.all(16),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  const GlassCard({super.key, required this.child, this.opaque = false});
  final Widget child;
  final bool opaque;
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final solid =
        opaque ||
        MediaQuery.of(context).disableAnimations ||
        MediaQuery.of(context).highContrast;
    final content = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: dark
            ? Brand.earth
            : Colors.white.withValues(alpha: solid ? 1 : .88),
        border: Border.all(color: dark ? Brand.muted : Colors.white),
        borderRadius: BorderRadius.circular(Brand.radius),
      ),
      child: child,
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(Brand.radius),
      child: solid
          ? content
          : BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: content,
            ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.action,
  });
  final String title, message;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 32),
    child: Column(
      children: [
        const Icon(Icons.spa_outlined, size: 48),
        const SizedBox(height: 16),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center),
        if (action != null) ...[const SizedBox(height: 20), action!],
      ],
    ),
  );
}

const categoryIcons = [
  Icons.restaurant_outlined,
  Icons.shopping_basket_outlined,
  Icons.directions_bus_outlined,
  Icons.shopping_bag_outlined,
  Icons.receipt_long_outlined,
  Icons.favorite_border,
  Icons.movie_outlined,
  Icons.category_outlined,
];
IconData categoryIcon(String key) =>
    categoryIcons[(int.tryParse(key) ?? 7).clamp(0, 7)];
