# 0001 — Offline mobile baseline

Date: 2026-10-27

Use the specified Flutter, Riverpod, go_router and Drift/SQLite stack. Build only the foundation required for Phase 1 and Phase 1 itself. No backend, account, sync or social scaffolding.

The user's explicit app directory is `MoneyWellSpentApp`; this overrides the plan's example `mobile/` directory. Specifications are copied into this repository so the implementation contract travels with the app.

The provided assets supersede the older specification wording that no logo exists. Use the supplied primary logo, symbol and app icon; preserve originals.

User confirmed Android/iOS identifier: `com.shoukanlabs.moneywellspent`. User requested local issue records for now.

GitHub CLI is unauthenticated. Track milestone evidence locally until remote issue creation is possible; do not claim remote issues exist.

Currency changes are locked while any expense (including soft-deleted history) or active budget exists. No archive/new-book feature is introduced silently.

## Implementation details

Drift runs an explicit versioned SQL schema with bound queries. Repository streams notify the UI after committed mutations, and snapshots are read transactionally. The initial local schema omits server revision/outbox fields and uses `is_system` instead of `owner_scope`; these are intentionally local representations. No Phase 2 schema is introduced. Category identity is stable and historical expenses retain references.

One offline application identity is used for Phase 1. Dev/staging/prod endpoint configuration and native environment variants are deferred until Phase 2, where the TRD introduces environments. JSON restore and OS notification delivery are optional P1 follow-ups; CSV and in-app signals are implemented now.

The initial currency picker exposes only explicitly mapped currencies (including ISO 0/2/3-decimal examples). Unknown currency codes fail validation; no unsupported code is assumed to have two decimals.
