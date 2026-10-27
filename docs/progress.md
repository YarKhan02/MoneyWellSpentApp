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
