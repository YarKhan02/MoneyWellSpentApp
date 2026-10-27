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

## Schema and deferred work

Schema version 1 is the initial schema, with no previous production versions. Unsupported upgrades fail without reset; future versions require additive migration fixtures. UTC text timestamps have fixed six-digit fractional precision. Raw SQL is parameterized, writes/snapshots are transactional, and money remains integer minor units.

Optional P1 OS notifications and JSON backup/import are deferred and disclosed in the UI/README. No accounts, backend, sync, social features, bank integrations, income or recurring automation were added. Native environment flavors/endpoints remain a Phase 2 concern.

Next: finish configured Android/iOS builds and `docs/release-checklist.md`. The foundation's native-build gate and final Phase 1 release gate are **not marked complete**.
