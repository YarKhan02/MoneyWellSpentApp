import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Brand palette and spacing/radius scale. Single source of colour truth.
abstract final class Brand {
  static const forest = Color(0xFF327039); // Forest Fern
  static const wheat = Color(0xFFF0BE49); // Wheat Field Sunrise
  static const earth = Color(0xFF133020); // Tilled Earth
  static const hay = Color(0xFFF8EDD9); // Alabaster Hay
  static const cherry = Color(0xFFDD5C36); // Cherry Grove
  static const ivory = Color(0xFFFFFCF5); // Warm Ivory — light card surfaces
  static const muted = Color(0xFF49614F); // secondary dark-green text

  // Spacing scale (4 → 48).
  static const xs = 4.0, sm = 8.0, md = 12.0, lg = 16.0;
  static const xl = 20.0, xxl = 24.0, section = 28.0, xxxl = 32.0;
  // Legacy aliases still referenced around the app.
  static const spacing = xxl;
  static const radius = 22.0;
  // Corner radii.
  static const heroRadius = 28.0, cardRadius = 22.0, smallRadius = 16.0;
  static const buttonRadius = 16.0;

  static ThemeData theme() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: forest,
          brightness: Brightness.light,
        ).copyWith(
          primary: forest,
          onPrimary: Colors.white,
          secondary: wheat,
          onSecondary: earth,
          tertiary: cherry,
          surface: hay,
          onSurface: earth,
          surfaceContainerLowest: hay,
          surfaceContainer: ivory,
          surfaceContainerHighest: const Color(0xFFFBF4E6),
          outlineVariant: const Color(0x22133020),
          error: const Color(0xFFA12D14),
        );

    const tokens = AppTokens(
      hero: earth,
      heroNested: Color(0xFF294638),
      onHero: hay,
      onHeroMuted: Color(0xFFBFD3C4),
      neutralCard: ivory,
      cardBorder: Color(0x14133020),
      track: Color(0x33327039),
      shadow: <BoxShadow>[
        BoxShadow(
          color: Color(0x14133020),
          blurRadius: 24,
          offset: Offset(0, 10),
        ),
      ],
    );

    final onSurface = scheme.onSurface;
    final textTheme = TextTheme(
      // Main spending amount.
      displaySmall: const TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        height: 1.05,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
      headlineLarge: const TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        height: 1.05,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
      // Page heading.
      headlineMedium: const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
      ),
      headlineSmall: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
      // Section title.
      titleLarge: const TextStyle(fontSize: 21, fontWeight: FontWeight.w600),
      // Card title.
      titleMedium: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      bodyLarge: const TextStyle(fontSize: 16, height: 1.4),
      bodyMedium: const TextStyle(fontSize: 14, height: 1.4),
      labelLarge: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      labelMedium: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
    ).apply(bodyColor: onSurface, displayColor: onSurface);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'PlusJakartaSans',
      scaffoldBackgroundColor: scheme.surface,
      extensions: [tokens],
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
          systemNavigationBarColor: hay,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        // Transparent — the floating glass container in AppShell provides the surface.
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 60,
        indicatorColor: forest.withValues(alpha: .16),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            color: s.contains(WidgetState.selected) ? forest : scheme.onSurface,
          ),
        ),
        labelTextStyle: WidgetStateProperty.all(textTheme.labelMedium),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ivory,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(smallRadius),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(smallRadius),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(smallRadius),
          borderSide: const BorderSide(color: forest, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: forest,
          foregroundColor: Colors.white,
          minimumSize: const Size(48, 54),
          textStyle: textTheme.titleMedium,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: forest,
          minimumSize: const Size(48, 52),
          side: BorderSide(color: scheme.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: forest),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: forest,
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
          borderRadius: BorderRadius.circular(cardRadius),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: earth,
        contentTextStyle: const TextStyle(color: hay),
        actionTextColor: wheat,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: forest,
        foregroundColor: Colors.white,
      ),
    );
  }
}

/// Semantic surface tokens that Material's ColorScheme does not express well.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.hero,
    required this.heroNested,
    required this.onHero,
    required this.onHeroMuted,
    required this.neutralCard,
    required this.cardBorder,
    required this.track,
    required this.shadow,
  });
  final Color hero,
      heroNested,
      onHero,
      onHeroMuted,
      neutralCard,
      cardBorder,
      track;
  final List<BoxShadow> shadow;

  @override
  AppTokens copyWith({
    Color? hero,
    Color? heroNested,
    Color? onHero,
    Color? onHeroMuted,
    Color? neutralCard,
    Color? cardBorder,
    Color? track,
    List<BoxShadow>? shadow,
  }) => AppTokens(
    hero: hero ?? this.hero,
    heroNested: heroNested ?? this.heroNested,
    onHero: onHero ?? this.onHero,
    onHeroMuted: onHeroMuted ?? this.onHeroMuted,
    neutralCard: neutralCard ?? this.neutralCard,
    cardBorder: cardBorder ?? this.cardBorder,
    track: track ?? this.track,
    shadow: shadow ?? this.shadow,
  );

  @override
  AppTokens lerp(AppTokens? other, double t) {
    if (other == null) return this;
    return AppTokens(
      hero: Color.lerp(hero, other.hero, t)!,
      heroNested: Color.lerp(heroNested, other.heroNested, t)!,
      onHero: Color.lerp(onHero, other.onHero, t)!,
      onHeroMuted: Color.lerp(onHeroMuted, other.onHeroMuted, t)!,
      neutralCard: Color.lerp(neutralCard, other.neutralCard, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      track: Color.lerp(track, other.track, t)!,
      shadow: t < .5 ? shadow : other.shadow,
    );
  }
}

extension AppTheme on BuildContext {
  AppTokens get tokens => Theme.of(this).extension<AppTokens>()!;
  TextTheme get text => Theme.of(this).textTheme;
  ColorScheme get scheme => Theme.of(this).colorScheme;
}

/// Neutral card that sits on the cream canvas. Soft border + gentle shadow.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Brand.xxl),
    this.radius = Brand.cardRadius,
    this.color,
    this.onTap,
  });
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Color? color;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final card = Ink(
      decoration: BoxDecoration(
        color: color ?? t.neutralCard,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: t.cardBorder),
        boxShadow: onTap == null ? t.shadow : null,
      ),
      child: Padding(padding: padding, child: child),
    );
    if (onTap == null) {
      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: t.shadow,
        ),
        child: card,
      );
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: card,
      ),
    );
  }
}

/// Deep Tilled-Earth hero surface for prominent financial summaries.
class HeroCard extends StatelessWidget {
  const HeroCard({super.key, required this.child, this.padding});
  final Widget child;
  final EdgeInsets? padding;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding ?? const EdgeInsets.all(Brand.xxl),
    decoration: BoxDecoration(
      color: context.tokens.hero,
      borderRadius: BorderRadius.circular(Brand.heroRadius),
    ),
    child: DefaultTextStyle.merge(
      style: TextStyle(color: context.tokens.onHero),
      child: IconTheme.merge(
        data: IconThemeData(color: context.tokens.onHero),
        child: child,
      ),
    ),
  );
}

/// A row heading with an optional trailing action.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.action});
  final String title;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(title, style: context.text.titleLarge)),
      ?action,
    ],
  );
}

/// Compact metric tile (e.g. Today / This week).
class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.iconColor = Brand.forest,
    this.onTap,
  });
  final String label, value;
  final IconData? icon;
  final Color iconColor;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => AppCard(
    onTap: onTap,
    padding: const EdgeInsets.all(Brand.lg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: Brand.md),
        ],
        Text(
          label,
          style: context.text.labelLarge?.copyWith(color: Brand.muted),
        ),
        const SizedBox(height: Brand.sm),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value, style: context.text.titleLarge),
        ),
      ],
    ),
  );
}

/// Category colour + icon helpers.
Color categoryColor(String key) => switch (key) {
  'wheat' => Brand.wheat,
  'cherry' => Brand.cherry,
  _ => Brand.forest,
};

/// Rounded tinted square holding a category icon.
class CategoryAvatar extends StatelessWidget {
  const CategoryAvatar({
    super.key,
    required this.iconKey,
    this.colorKey = 'forest',
    this.size = 44,
    this.onHero = false,
  });
  final String iconKey, colorKey;
  final double size;
  final bool onHero;
  @override
  Widget build(BuildContext context) {
    final c = categoryColor(colorKey);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c.withValues(alpha: onHero ? .28 : .16),
        borderRadius: BorderRadius.circular(size * .3),
      ),
      child: Icon(
        categoryIcon(iconKey),
        size: size * .5,
        color: onHero ? Brand.hay : c,
      ),
    );
  }
}

/// Subtle glassmorphism, used sparingly for nested/floating surfaces.
/// Becomes fully opaque when the user prefers opaque surfaces.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.opaque = false,
    this.onHero = false,
  });
  final Widget child;
  final bool opaque, onHero;
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final solid =
        opaque ||
        MediaQuery.of(context).disableAnimations ||
        MediaQuery.of(context).highContrast;
    final base = onHero ? t.heroNested : t.neutralCard;
    final content = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Brand.xxl),
      decoration: BoxDecoration(
        color: base.withValues(alpha: solid ? 1 : .86),
        border: Border.all(
          color: onHero ? Colors.white.withValues(alpha: .08) : t.cardBorder,
        ),
        borderRadius: BorderRadius.circular(Brand.cardRadius),
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: onHero ? t.onHero : context.scheme.onSurface),
        child: child,
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(Brand.cardRadius),
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
    this.icon = Icons.spa_outlined,
    this.action,
  });
  final String title, message;
  final IconData icon;
  final Widget? action;
  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
    child: Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Brand.forest.withValues(alpha: .12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 30, color: Brand.forest),
        ),
        const SizedBox(height: Brand.lg),
        Text(
          title,
          style: context.text.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Brand.sm),
        Text(
          message,
          style: context.text.bodyMedium?.copyWith(color: Brand.muted),
          textAlign: TextAlign.center,
        ),
        if (action != null) ...[const SizedBox(height: Brand.xl), action!],
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
