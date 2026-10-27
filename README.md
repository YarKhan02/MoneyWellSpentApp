# Money Well Spent

An offline-first Flutter expense tracker from Shoukan Labs. Android and iOS application identifier: `com.shoukanlabs.moneywellspent`.

## Phase 1 implementation

- Guest welcome and explicit currency/timezone setup; no account or backend.
- Exact integer money, positive amount validation and 0/2/3-decimal currencies.
- SQLite expense create/edit/delete/undo, category management and Activity filters.
- Daily, weekly, monthly and yearly reports with category drilldowns.
- Weekly/monthly caps, overage, persistent in-app 75/90/100% signals.
- Saved timezone, week start, accessibility and signal preferences.
- Formula-safe UTF-8 CSV export via the system share sheet; confirmed local erase.
- Supplied brand assets, bundled Plus Jakarta Sans/OFL license, warm/light and dark themes.

No login, sync, backend, analytics or social code is included. OS notifications and JSON restore are optional Phase 1 follow-ups, not implemented. CSV is an export, not a restorable backup.

## Run

Developed with Flutter 3.47.2 / Dart 3.13.2.

```sh
flutter pub get
flutter run
```

Install an Android SDK with command-line tools and accept its licenses. iOS requires full Xcode and the plugin dependency toolchain. No secrets or server configuration are required.

```sh
dart format lib test integration_test
flutter analyze
flutter test
flutter build apk --debug
flutter build ios --simulator --debug
```

The integration test requires a **clean test device** in airplane mode:

```sh
flutter test integration_test/offline_flow_test.dart -d DEVICE_ID
```

Do not run that first-run test on a personal ledger. Widget/repository tests use isolated temporary/in-memory databases. The preview test writes `docs/previews/home.png` with explicitly labeled sample data; sample data is never seeded into the production app.

## Architecture

`lib/app` owns bootstrap, Riverpod dependency injection and go_router navigation. Feature screens call `LedgerRepository`; only the repository accesses Drift/SQLite. Writes are transactional, queries bind user values, and widgets observe fresh snapshots. Calendar boundaries use IANA timezone data. SQLite timestamps use fixed six-digit UTC fractional seconds for correct lexical ordering.

Schema version 1 is the first released schema; there are no previous production versions to migrate. Tests cover fresh schema creation, reopening real SQLite files and refusing unsupported newer schemas without deleting records. Future schema changes require explicit transactional migrations and fixtures.

## Data and privacy

The app uses application-support SQLite storage. Android backup/device extraction exclusions and iOS backup exclusion are configured; native behavior still needs device verification. There is no telemetry. System storage encryption depends on the device; the app does not claim a separately encrypted database. Export sharing is initiated by the user. Erase is permanent and requires typing `ERASE`.

Currency is locked while expense history (including soft-deleted records) or active budgets exist. Export and explicitly erase before starting a different book. Archived categories remain in reports. Budget signals record milestones reached and are not reissued when usage falls and crosses the same threshold again.

## Delivery status

See [progress](docs/progress.md), [local milestone issues](docs/backlog.md), [traceability](docs/traceability.md) and [release checks](docs/release-checklist.md). Automated checks are distinct from native/device release acceptance. GitHub Actions is configured but has not been run remotely. Release signing credentials are not configured; Android's generated debug signing is only for development.
