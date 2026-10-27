# Money Well Spent — Design Brief and UI System
**Version:** 1.0 | **Direction:** Vibrant, clean, premium glassmorphism with playful finance cues

## 1. Brand personality
Approachable, thoughtful, energetic and quietly premium. Money Well Spent helps people notice patterns instead of shaming overspending. Avoid "corporate banking" coldness, overloaded gradients, flashy trading-app aesthetics or childish gamification.

## 2. Color system (confirmed palette)
| Token | Hex | Use |
|---|---|---|
| Forest Fern | `#327039` | Primary CTA, active navigation, positive accents |
| Wheat Field Sunrise | `#F0BE49` | Warm highlights, active chips, celebratory details |
| Tilled Earth | `#133020` | Main dark text, deep surfaces, premium grounding |
| Alabaster Hay | `#F8EDD9` | Main warm background, light surfaces |
| Cherry Grove | `#DD5C36` | Controlled warning/over-budget highlight, never sole indicator |

**Note:** user-typed `FOBE49` interpreted as `F0BE49` (digit zero) because hex permits 0–9, A–F; confirm if different intent. Never add competing saturated colors as major brand hues. Derived neutrals/opacity variants are permissible.

### Suggested semantic tokens
```
color.bg = #F8EDD9
color.text.primary = #133020
color.text.secondary = #49614F          // verify contrast on chosen surface
color.brand.primary = #327039
color.brand.accent = #F0BE49
color.status.over = #DD5C36
color.surface.glass = rgba(255,255,255,0.62)
color.stroke.glass = rgba(255,255,255,0.72)
color.shadow = rgba(19,48,32,0.10)
```
Color usage target (approximate): warm neutral 65%, deep/green 25%, gold and coral 10%. Don't set tiny text directly in Forest Fern on semi-transparent gold without verifying contrast.

## 3. Glassmorphism rules
- Glass is for top summary cards, modal sheets, sticky nav accents and selected surfaces, **not every container**.
- Backdrop blur 12–20 logical px maximum, 1px translucent edge, soft shadow. Always supply opaque fallback for low-end devices/reduced transparency.
- Put text on a sufficiently opaque layer so backgrounds don't compromise WCAG AA legibility.
- Keep white-space and hierarchy more important than blur. Maximum two stacked glass layers.
- Motion: subtle 150–250ms microinteractions; honor reduce motion. Avoid looping cash/coin animation.

## 4. Typography, spacing and shape
- Primary font: **Plus Jakarta Sans** (bundle with license); fallback platform sans. Numbers use tabular lining digits when available, to prevent progress cards shifting.
- Type scale: display 32/38 semibold; H1 24/30 bold; H2 20/26 semibold; body 15–16/22 regular; label 13/18 medium; micro 12/16 only for secondary information.
- Baseline spacing: 4pt; common gaps 8, 12, 16, 24, 32. Screen horizontal margin 20–24.
- Radius: card 24, sheet 28, button 16, chip pill. Tap targets >=44×44pt, 48 preferred.
- Iconography: simple rounded line icons, 2px strokes; category symbols friendly, consistent, and not solely dependent on color.

## 5. Component inventory
- GlassSummaryCard: label, prominent amount, delta/period context.
- BudgetProgressCard: limit, spent, remaining, progress (>100% supports overflow), threshold text.
- ExpenseRow: category icon, primary label, optional note, date, right-aligned amount.
- CategoryChip and CategoryLegendRow: icon+name+share+value.
- AmountField: oversized tabular amount, decimal formatting, currency cue and accessible input.
- SegmentedPeriodSelector, DateRangeNavigator, EmptyState, ErrorState, ConfirmationDialog, Toast/Undo.
- PrimaryButton (Forest Fern / white text), SecondaryButton (deep text/transparent), WarningAction (coral reserved for confirmed destructive actions).
- Chart variants: restrained donut/category and 7/30-day bar. Legends always accompany charts; no 3D, heavy shadows, or arbitrary colors.

## 6. Screen direction
| Screen | Design intent |
|---|---|
| Onboarding | Calm visual of three stylized spending marks; one clear CTA per step. |
| Home | Warm background; strong spend number hero; gold progress accents; clean recent list. |
| Add expense | Focused sheet; large amount and category grid; minimally distracting details. |
| Activity | Readable statement-like list, tasteful category badges, generous vertical spacing. |
| Insights | One hero total and one primary chart at a time; category rows for precise figures. |
| Budget | Side-by-side or stacked weekly/monthly glass cards with clear remaining/overage. |
| Friends | Friendly group avatars and status; leaderboard respectful, no humiliation language. |
| Settings | Simple grouped preferences with opaque readability-first rows. |

## 7. Logo direction and usage
Product identity: playful finance symbol, simple and memorable at 24px app icon size. Candidate directions from brand exploration: (a) abstract coin + upward check, (b) simplified wallet/leaf intersect, (c) typographic `M` constructed from receipt/flow shapes. **No final logo has been selected yet; do not invent a finalized mark.** Build an app icon placeholder with an abstract brand monogram until logo sign-off. Document safe area, one-color use, minimum size and prohibited stretching after selection.

## 8. Design don'ts
- No neon green stock-trading visuals; no fake 3D currency everywhere.
- No glass behind small low-contrast numbers; no more than one main CTA per screen.
- Do not equate spending more with moral failure. Avoid red-only errors or green-only success.
- No generic gradient on every card, overloaded category colors, saturated charts with 10+ colors.
- No hamburger-only navigation for critical tracking flows.

## 9. Handoff acceptance criteria
Design tokens live in a single theme module; no magic hex values in feature views. Test light/dark system appearance (Phase 1 may ship carefully curated warm-light plus a solid dark fallback), font scaling 200%, contrast, small phone and tablet sizes, lower-end device blur fallbacks, and reduced motion. Screens must match the flow spec's empty/error/confirmation states.
