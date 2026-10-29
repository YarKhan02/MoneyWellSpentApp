# Implementation progress — 2026-10-27

## Scope and user decisions

Read parent AGENTS.md, CLAUDE.md and all six specifications before implementation. App lives directly in `MoneyWellSpentApp`. User confirmed `com.shoukanlabs.moneywellspent` for Android/iOS and local milestone issue records. Supplied logos are used without inventing replacement branding.

## Delivered implementation

- Foundation: Flutter Android/iOS scaffolds; Riverpod, go_router, Drift/SQLite; centralized theme; supplied launcher icons; bundled Plus Jakarta Sans and license; four tabs; CI workflow; schema version 1; guest onboarding.
- Core ledger (EXP-01/02/03, LOC-01): exact integer money, validated create/edit, stable UUIDv7 IDs, duplicate-safe saves, confirmation/soft-delete/Undo, category creation/rename/archive and Activity filters.
- Dashboard/reports (EXP-04/05): day/week/month/year ranges, DST-aware boundaries, recent entries, category chart/text legends and drilldowns.
- Budgets (BUD-01/02): weekly/monthly caps, progress/remaining/overage, durable per-period signals, refresh after mutations and on app resume/calendar tick.
- Settings/export (LOC-02, ACC-01/02, UX-01): explicit currency/timezone, week start, signal/motion/transparency preferences, category manager, formula-safe CSV/system sharing and typed erase.
- Privacy: no runtime network/backend/analytics; Android backup/extraction exclusions; iOS application-support backup exclusion before database open. Native platform behavior still requires validation.

## Verified

- `flutter analyze`: **no issues found**.
- `flutter test`: **22 tests passed**.
- `dart format lib test integration_test`: completed successfully.
- `flutter pub run flutter_launcher_icons`: successfully generated Android/iOS icons from supplied asset.
- Tests include a 100-expense file-backed database across restart, duplicate submits, delete/undo, invalid inputs, archive rules, currency lock, DST/leap/week boundaries, microsecond timestamp ordering, raw SQL reconciliation, budget dedup/rollover, preference persistence, CSV safety and unsupported-schema preservation.
- Full UI tests verify onboarding and create → edit → delete → Undo against the actual local repository. Home smoke test at 200% text scaling passes.
- `docs/previews/home.png` is an actual Flutter rendering using an explicitly labeled test ledger. Production starts empty.

## Structural refactor — 2026-10-29 (presentation + ledger layering)

Behaviour-preserving reorganisation. No feature, copy, layout, schema or SQL
semantics changed; **Phase 1 only — no backend scaffolding was added.**

**Why.** Six files carried most of the app: `features/screens/dashboard.dart`
(1211 lines, four screens), `settings.dart` (810, three screens),
`forms.dart` (592, three screens), `core/design/theme.dart` (533, tokens +
eight widgets), `features/ledger/repository.dart` (453, read + write + alerts
+ export) and `app/app.dart` (374, root + router + shell + layout). Every
screen imported `app/app.dart` for `PageBody`/`LedgerView` while `app.dart`
imported every screen — a circular dependency that made the layering
meaningless.

**What changed.**
- `lib/` went from 12 files / 4,317 lines to 75 files / 5,432 lines (the
  growth is doc comments and the dedicated test fixtures; the largest file is
  now 268 lines, down from 1,211).
- **Design split**: `core/design/tokens.dart` (`Brand`, `AppTokens`, the
  `context.tokens/text/scheme` extension), `theme.dart` (`buildAppTheme()`
  only — replaces `Brand.theme()`), `category_style.dart`,
  `chart_palette.dart`.
- **`shared/widgets/`**: `AppCard`, `HeroCard`, `GlassCard`/`NestedGlassCard`,
  `MetricCard`, `SectionHeader`, `CategoryAvatar`, `EmptyState`,
  `ProgressBar`, `Pill`, `PageBody`, and a new `MoneyField` that de-duplicates
  the borderless amount input previously copied between the expense and
  budget forms. `shared/dialogs.dart` and `shared/errors.dart` hold `confirm`
  and `friendlyError`. Moving `PageBody` here broke the import cycle.
- **Feature-first screens**: `features/{home,activity,insights,budget,
  expenses,settings,categories,onboarding}/`, one screen per file with a
  `widgets/` subfolder each. The function-style screens (`homeScreen`,
  `budgetScreen`, `settingsScreen`, `categoriesScreen`, `newExpenseScreen`)
  are now classes, consistent with the rest.
- **Testable domain logic** pulled out of `build()`:
  `features/ledger/budget_status.dart` (`BudgetStatus` — spent, remaining,
  fraction, percentages, over-budget; previously recomputed inline in three
  places), `category_share.dart` (`CategoryShare.within`),
  `spending_comparison.dart`, and `formatting.dart` (a `ProfileCalendar`
  extension so every date and period boundary derives from the book's own
  timezone and week start).
- **Ledger split**: `repository.dart` is now a facade owning only the
  transaction boundary and change stream. Reads go through
  `ledger_reader.dart` + `mappers.dart`, writes through
  `writers/{profile,expense,category,budget}_writer.dart`, milestones through
  `budget_alerts.dart`, export through `csv_export.dart` (now a pure
  `buildExpenseCsv(LedgerSnapshot)`), queries through `sql_access.dart`. The
  public `LedgerRepository` API is unchanged, so `repository_test.dart` was
  not touched.
- **App layer**: `app/app.dart` (root + lifecycle), `router.dart`, `shell.dart`
  (`AppShell`, `AppTopBar`, `AddExpenseBar`, `FloatingNav`), `ledger_view.dart`.

**New tests** (4 files, 24 cases) covering the extracted logic:
`budget_status_test.dart`, `category_share_test.dart`,
`spending_comparison_test.dart`, `csv_export_test.dart`, with shared builders
in `test/ledger_fixtures.dart`.

**Verification — NOT yet run.** The refactor was performed in an environment
with no Flutter SDK, so `dart format`, `flutter analyze` and `flutter test`
have **not** been executed against these changes and no claim is made that
they pass. A static import/symbol checker reported 0 unresolved symbols and 0
missing imports across all 75 files. The gates below must be run locally
before this is considered done:

```
dart format lib test integration_test
flutter analyze
flutter test
```

## Responsive UI refinement — 2026-10-29

Implements the 13-point UI brief. No financial calculation, persistence
schema, currency rule, export behaviour or other business rule was changed,
and **no backend work was added — still Phase 1.**

**Shared causes fixed first (§1–§3).** There was no global scaling of any
kind — no `Transform.scale`, no text-scale override, no whole-screen fitting
widget — so the oversized interface came from the token values themselves
and was fixed centrally:

| Token | Was | Now |
| --- | --- | --- |
| card / hero / nested padding | 24 everywhere | 18 / 20 / 16 |
| `cardRadius` / `heroRadius` | 22 / 28 | 18 / 20, plus `sheetRadius` 24, `inputRadius` and `buttonRadius` 14 |
| `displaySmall` (primary amounts) | 36 | 32 |
| `titleLarge` / `titleMedium` | 21 / 18 | 19 / 16 |
| `bodyLarge` | 16 | 15 |
| avatar | 44 | 38 (34 compact) |
| primary button height | 54 | 50 |
| card shadow | `0x14`, blur 24, y+10 | `0x0D`, blur 10, y+2, plus a `divider` token |
| `PageBody` bottom padding | 96 on every screen | 24 |

That 96 was not preventing an overlap — `Scaffold` already lays the body
above `bottomNavigationBar` and `extendBody` is off — it was simply a dead
band at the end of every list, including routes with no bars at all.

**Structural changes.**
- The shell's app bar is gone. Each tab opens with a compact `AppHeader`
  carrying the title and the settings action, saving a bar of chrome per
  screen. `SettingsAction` lives in `app/shell.dart`.
- Navigation is a solid docked surface; its height is derived from the
  viewer's text scale (`AppNavigationBar.heightFor`) and clamped at 96, so
  labels cannot clip at 200% text.
- New shared components: `AppHeader`, `ListSurface` (one card, hairline
  dividers, rows that own their padding so ink fills the row),
  `ResponsivePair` (side by side or stacked from real constraints, not a
  device breakpoint), `AmountText`, and `LayoutQueries` on `BuildContext`.

**Amounts.** `MoneyDisplay` (`core/money/money_display.dart`) adds grouping
separators for display only — `Money.decimal` is untouched, so form
round-tripping, `Money.parse` and the CSV export are unaffected. Grouping is
done on the digit string, never a double. `AmountText` sets the currency
code smaller than the figure and lets a long amount **wrap** rather than
shrink or truncate; every `FittedBox(scaleDown)` around a financial value is
gone. This is what fixes the clipped `PKR 1,250.00 / …` on Home.

**Selection pattern (§6).** All four `DropdownButtonFormField`s are
replaced by one pattern in `shared/selection/`: a rounded modal bottom sheet
with a title, selected state, accessible rows, scrolling, keyboard-aware
padding, search above 12 options, and no change on dismiss. `SelectionField`
renders as an `InputDecorator` so it matches neighbouring text fields.
Category accent is now labeled colour swatches with a check indicator —
readable names, same stored `forest` / `wheat` / `cherry` values.

**Per screen.** Home: marketing headline dropped, one hero with
period → amount → budget hierarchy, the two nested budget cards replaced by
a `BudgetStrip` with a slim bar and the full spent-of-limit relationship,
metrics relabelled "Spent today" / "Spent this week" and stackable, recent
expenses in one `ListSurface`. Activity: compact header, neutral summary
instead of the dark pill, wrapping filter chips with an obvious active state
and a reset, small day headings, grouped compact rows (~64pt at normal
text). Insights: shortened intro, compact segmented control, contextual
period labels ("October 2026", exact range kept in the tooltip and
semantics), width-derived donut (150–220pt, smaller on short viewports) with
no total repeated in its centre. Budget: neutral cards, compact `tune`
action instead of the full-width button, status in words
("left to spend" / "exactly on budget" / "over your limit"). Settings:
intro removed, locked currency reads as a value with its reason, unsaved
changes are stated, erase moved to its own group. Categories: compact rows
in a `ListSurface`, app-bar add action, and a keyboard-aware editor sheet
with an adaptive icon grid.

**Glassmorphism.** Replacing Home's nested cards left `GlassCard` unused,
which would have made the "Opaque surfaces" preference a no-op. The widget
was deleted and the frosting moved to the one surface with something behind
it — the add-expense sheet over the ledger — still switched off by the
preference, by reduced motion and by high contrast.

**Tests.** `test/responsive_harness.dart` plus
`test/responsive_layout_test.dart` and `test/keyboard_insets_test.dart`
cover the six viewports (320×568 … 844×390 landscape) at 1.0 / 1.3 / 2.0
text scale, asserting no render overflow and no horizontal scrolling, on
populated and empty ledgers; plus long notes with large amounts, the
overspent state, last-row reachability, and the add-expense and category
sheets with a simulated keyboard. `ui_flow_test.dart` and
`integration_test/offline_flow_test.dart` were updated for the currency
sheet replacing the dropdown.

**Verification.** Run by the user on macOS; this environment has no Flutter
SDK. `dart format` and `flutter analyze` pass and the app compiles. First
`flutter test` run: 54 passed, 25 failed — all five root causes found and
fixed, and the second run cleared the whole viewport matrix (6 sizes × 3
text scales, populated and empty).

Defects the new tests caught, all genuine:

1. **Progress bar semantics crash** (21 failures). Flutter asserts a
   percentage announced to assistive technology is 0–100%, and an
   over-budget period legitimately reports 150%. `ProgressBar` now takes a
   raw `percent` and clamps the fill and the spoken value itself, so no
   call site can reintroduce it; the true figure stays in visible text.
2. **`BudgetStrip` header overflowed** by up to 212px at every width — an
   unflexed status `Text` beside an `Expanded` label. Now a `Wrap`.
3. **`SpendingOverview` overflowed** 8px at 2.0× — the period `Pill` was
   not flexible, and did not ellipsise.
4. **A floating toast covered a primary action.** "Expense saved" is raised
   after the form pops, so it landed on the detail screen's Delete button
   and swallowed the tap. The toast is now shown only for a new expense —
   after an edit the detail screen already shows the new figure — and a
   `ToastClearingObserver` on the router dismisses any stale toast on a
   route change.
5. **Lazy page bodies hid off-screen controls.** Switching `PageBody` to an
   `itemBuilder` meant a control below the fold did not exist in the tree
   at all. Reverted to an explicit child list, and the doc comment now
   states plainly that a `ListView` still lays out only what is near the
   viewport.

A sixth issue was a fault in the test rather than the app: the last-row
reachability check called `scrollUntilVisible` with a finder that already
matched the tiles built on first layout, so it never scrolled and then
measured a tile below the fold against the full viewport height. It now
jumps to `maxScrollExtent` and asserts the final row clears the top of the
docked navigation, which is the claim that matters.

No emulator or device check has been done, and the screenshots the brief
referred to were never supplied, so visual balance still follows the brief's
written targets rather than observed renders.

## Milestone records

Local issues 001–004 are in `docs/issues/`, indexed in `docs/backlog.md`. They record achieved automated implementation milestones, not unverified device release gates. No remote GitHub issues or CI runs are claimed.

## Native/release status

- Android build started; Gradle bootstrap downloaded successfully. Final build result pending.
- Flutter doctor reports missing Android command-line tools and unknown SDK license status.
- iOS build attempt returned `Application not configured for iOS`. Full Xcode is unavailable and CocoaPods is missing. Generated iOS project and identifier exist, but native compilation is not verified.
- No Android/iOS device or simulator was available. Airplane-mode/platform share/backup/accessibility/performance acceptance remains open.
- Debug Android signing is scaffold-only; production signing/store delivery is not configured.
- Forest & Sunrise polish pass (matched to reference screenshot): added Warm Ivory `#FFFCF5` as the light card surface token (cards/inputs); replaced the logo app bar with a "MONEY WELL SPENT" eyebrow + two-tone headline and a frosted circular settings button; metric cards now carry tinted icons (calendar/chart); simplified home empty state ("No expenses yet") and "View all"; **floating glass bottom navigation**; **Add Expense is a docked full-width bar (Home only), no longer an overlapping FAB** — bars are docked (extendBody off) so content clips above them. Verified light + dark renders and all 22 tests (PageBody bottom padding tuned to 96 so the add-sheet scroll stays deterministic in tests).
- UI/UX redesign (Forest & Sunrise): rebuilt the presentation layer only — `core/design/theme.dart` (brand palette, `AppTokens` theme extension, type scale, themed Material components, light + depth-preserving dark theme, status-bar styling) and shared components (`AppCard`, `HeroCard`, `MetricCard`, `SectionHeader`, `CategoryAvatar`, refined `GlassCard`/`EmptyState`). Reskinned all screens: shell header/nav/FAB (`app/app.dart`), Home (Tilled-Earth spending hero + nested weekly/available cards + metric tiles + recent list), Activity (compact summary + grouped list), Insights (segmented period, deep-green summary, doughnut with single-category bar fallback, category progress rows), Budget (progress cards, accurate overspend), Add/Edit/Detail (`forms.dart`, light haptics on save), Settings (grouped cards, currency-lock UX) and Categories. Logic layer (money/period/models/repository/database) untouched. FAB now Home-only. Verified: `flutter analyze` clean, format gate clean, all 22 tests pass, debug APK builds, Home preview render inspected.
- Brand assets rewired to the new "Coin Path" naming: app-bar symbol → `01_coin_path_symbol_transparent_512w.png`; onboarding hero → `07_stacked_logo_transparent.png`; launcher icons regenerated via flutter_launcher_icons with forest (#327039) adaptive background + `10_android_adaptive_foreground_transparent.png` (iOS from `09_android_launcher_forest.png`). Widget/UI tests render both logos and pass.
- CI fix: `android/app/build.gradle.kts` release `signingConfig` now guards on `key.properties` existing. Previously the `as String` casts crashed Gradle configuration for every build (incl. `--debug`) wherever the gitignored `key.properties` was absent — breaking the `flutter.yml` CI debug-build job. Verified `flutter build apk --debug` passes with the file absent. Release signing wired for CI: `android-release.yml` now writes `android/key.properties` (storeFile=upload-keystore.jks + the `KEYSTORE_*`/`KEY_*` secrets) before `flutter build appbundle --release`, so the AAB is signed with the upload key instead of falling back to the debug key (which Play rejected: found debug SHA1 95:3A:…, expected upload SHA1 8C:C7:…). Assumes the keystore is PKCS12 (build.gradle hardcodes `storeType = "pkcs12"`).

## Schema and deferred work

Schema version 1 is the initial schema, with no previous production versions. Unsupported upgrades fail without reset; future versions require additive migration fixtures. UTC text timestamps have fixed six-digit fractional precision. Raw SQL is parameterized, writes/snapshots are transactional, and money remains integer minor units.

Optional P1 OS notifications and JSON backup/import are deferred and disclosed in the UI/README. No accounts, backend, sync, social features, bank integrations, income or recurring automation were added. Native environment flavors/endpoints remain a Phase 2 concern.

Next: finish configured Android/iOS builds and `docs/release-checklist.md`. The foundation's native-build gate and final Phase 1 release gate are **not marked complete**.
