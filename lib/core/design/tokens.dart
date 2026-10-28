import 'package:flutter/material.dart';

/// Brand palette and the spacing / radius scale.
/// Single source of colour truth — no widget code lives here.
abstract final class Brand {
  static const forest = Color(0xFF327039); // Forest Fern
  static const wheat = Color(0xFFF0BE49); // Wheat Field Sunrise
  static const earth = Color(0xFF133020); // Tilled Earth
  static const hay = Color(0xFFF8EDD9); // Alabaster Hay
  static const cherry = Color(0xFFDD5C36); // Cherry Grove
  static const ivory = Color(0xFFFFFCF5); // Warm Ivory — light card surfaces
  static const muted = Color(0xFF49614F); // secondary dark-green text

  // --- Spacing -----------------------------------------------------------
  // One scale, 4 → 32. Everything spatial picks a step from here.
  static const xs = 4.0, sm = 8.0, md = 12.0, lg = 16.0;
  static const xl = 20.0, xxl = 24.0, section = 28.0, xxxl = 32.0;

  // --- Corner radii ------------------------------------------------------
  // Smaller elements get tighter corners, so nothing reads as a bubble.
  static const smallRadius = 12.0; // inner surfaces, list row ink
  static const inputRadius = 14.0; // text fields
  static const buttonRadius = 14.0; // filled / outlined buttons
  static const cardRadius = 18.0; // ordinary cards
  static const heroRadius = 20.0; // the one prominent summary surface
  static const sheetRadius = 24.0; // modal bottom sheets, top corners only

  // --- Component metrics -------------------------------------------------
  /// Horizontal page gutter on a narrow phone.
  static const screenPadding = lg;

  /// Widest the content column ever gets, so large windows stay readable.
  static const contentMaxWidth = 720.0;

  static const cardPadding = 18.0;
  static const heroPadding = xl;
  static const nestedPadding = lg;

  /// Category avatar in a list row, and its smaller variant.
  static const avatarSize = 38.0;
  static const avatarSizeSmall = 34.0;

  /// Primary button height at normal text scale. Buttons grow past this
  /// when their label wraps — the value is a floor, not a cap.
  static const buttonHeight = 50.0;
  static const compactButtonHeight = 44.0;

  /// Minimum interactive target, even where the visible icon is smaller.
  static const minTouchTarget = 48.0;

  /// Navigation bar height at normal text scale; see `navBarHeight` in
  /// app/shell.dart, which grows this with the viewer's text scale.
  static const navBarHeight = 56.0;

  static const iconSize = 22.0;
  static const smallIconSize = 18.0;
}

/// Semantic surface tokens that Material's [ColorScheme] does not express well.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.hero,
    required this.heroNested,
    required this.onHero,
    required this.onHeroMuted,
    required this.neutralCard,
    required this.cardBorder,
    required this.divider,
    required this.track,
    required this.shadow,
  });

  /// The token set used by the light Forest & Sunrise theme.
  ///
  /// The shadow is deliberately shallow: ordinary cards are separated by a
  /// hairline border, and depth is reserved for surfaces that float
  /// (the navigation bar, sheets).
  static const light = AppTokens(
    hero: Brand.earth,
    heroNested: Color(0xFF294638),
    onHero: Brand.hay,
    onHeroMuted: Color(0xFFBFD3C4),
    neutralCard: Brand.ivory,
    cardBorder: Color(0x1A133020),
    divider: Color(0x12133020),
    track: Color(0x24327039),
    shadow: <BoxShadow>[
      BoxShadow(color: Color(0x0D133020), blurRadius: 10, offset: Offset(0, 2)),
    ],
  );

  final Color hero,
      heroNested,
      onHero,
      onHeroMuted,
      neutralCard,
      cardBorder,
      divider,
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
    Color? divider,
    Color? track,
    List<BoxShadow>? shadow,
  }) => AppTokens(
    hero: hero ?? this.hero,
    heroNested: heroNested ?? this.heroNested,
    onHero: onHero ?? this.onHero,
    onHeroMuted: onHeroMuted ?? this.onHeroMuted,
    neutralCard: neutralCard ?? this.neutralCard,
    cardBorder: cardBorder ?? this.cardBorder,
    divider: divider ?? this.divider,
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
      divider: Color.lerp(divider, other.divider, t)!,
      track: Color.lerp(track, other.track, t)!,
      shadow: t < .5 ? shadow : other.shadow,
    );
  }
}

/// Shorthand accessors so widgets read `context.tokens` instead of
/// `Theme.of(context).extension<AppTokens>()!`.
extension AppTheme on BuildContext {
  AppTokens get tokens => Theme.of(this).extension<AppTokens>()!;
  TextTheme get text => Theme.of(this).textTheme;
  ColorScheme get scheme => Theme.of(this).colorScheme;
}

/// Layout helpers that depend on the current constraints rather than on a
/// fixed breakpoint table. Screens ask "do these fit side by side?" instead
/// of "is this a phone?".
extension LayoutQueries on BuildContext {
  /// True when the viewport is too narrow, or the text too large, for two
  /// statistics to sit comfortably side by side.
  bool get stacksPairs {
    final media = MediaQuery.of(this);
    return media.size.width < 360 || media.textScaler.scale(14) > 19;
  }

  /// True when the viewport is short enough that tall decorative blocks
  /// (large charts, oversized empty states) should shrink.
  bool get isShort => MediaQuery.of(this).size.height < 640;

  /// Current text scale expressed as a plain multiplier, for sizing
  /// containers that must grow with their labels.
  double get textScale => MediaQuery.of(this).textScaler.scale(14) / 14;
}
