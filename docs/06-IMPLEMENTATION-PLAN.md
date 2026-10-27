# Money Well Spent — Implementation Plan for Claude Code
**Version:** 1.0 | **Execution:** Vertical slices, Phase 1 before networking

## 1. Before writing code
1. Read all 6 specs, resolve contradictions in an ADR (`docs/adr/0001-stack.md`), and report any truly blocking ambiguity. Defaults in TRD are the baseline.
2. Inspect current repository; preserve existing setup and conventions where compatible. Do not overwrite code blindly.
3. Set up monorepo `mobile/` and empty `server/` placeholder only when Phase 2 begins. Flutter app builds without a backend.
4. Generate `docs/traceability.md`: feature IDs → screens → data entities → tests.
5. Create GitHub issues/milestones per work package if repository permissions exist; otherwise write `docs/backlog.md` without claiming remote operations.

## 2. Phase 0 — foundation
- [ ] Initialize Flutter, Dart analysis rules, Riverpod, go_router, Drift and build flavors.
- [ ] Tokenized theme, Plus Jakarta Sans license, reusable buttons, glass cards, typography.
- [ ] Routing and bottom navigation with empty screens.
- [ ] Drift DB + migration harness + seed categories, local profile.
- [ ] Build pipeline: formatting, analyze, tests, Android build; iOS on macOS runner when available.
**Gate:** Fresh build launches setup → placeholder Home offline, theme consistent, migration tests green.

## 3. Phase 1 — functional offline MVP (exact order)
### Slice 1 — core ledger (EXP-01, EXP-02, EXP-03, LOC-01)
- [ ] Money value object, ISO exponent mapping and parser/formatter with unit tests.
- [ ] Create/edit/delete expenses via repository + Drift; archive categories.
- [ ] Quick-add sheet and Activity history/detail.
- [ ] Test date boundaries, note limits, duplicate submit and soft-delete undo.
**Gate:** 100 offline expenses can be created/edited/deleted with exact totals across restart.

### Slice 2 — dashboard & insights (EXP-04, EXP-05)
- [ ] Aggregate queries for day, week, month, year based on selected timezone.
- [ ] Home summary and recent list; Insight charts/category drilldowns.
- [ ] Empty, large values, category history and accessibility tests.
**Gate:** Every aggregate matches a raw SQL reference dataset including DST/week rollover.

### Slice 3 — budgeting (BUD-01, BUD-02)
- [ ] Weekly/monthly cap CRUD; budget usage progress and overage states.
- [ ] Threshold engine with dedup ledger and optional local notification adapter.
- [ ] Test create/edit/delete expenses crossing thresholds and calendar rollover.
**Gate:** Alerts are not duplicated; progress updates after edits/deletes without manual refresh.

### Slice 4 — settings, export and polish (LOC-02, ACC-01/02, UX-01)
- [ ] First-run currency/timezone flow; preferences persistence; category manager.
- [ ] CSV export, tested JSON backup/import if feasible (ACC-02 marked P1).
- [ ] Full design audit for blur fallbacks, reduced motion, type scale, keyboard/safe area.
- [ ] Instrument crash reporting only with explicit user privacy choice.
**Gate:** Phase 1 Definition of Done in PRD; airplane-mode test on Android/iOS, no P0 bugs.

## 4. Phase 2 — authentication + cloud sync (do not start before Phase 1 gate)
- [ ] Create Go Gin API scaffold, sqlc, migrations, PostgreSQL test harness.
- [ ] Select OIDC vendor in ADR with pricing, PKCE, token policy; no homemade passwords.
- [ ] Implement `/v1/me`, categories, expenses, budgets with owner-scoped queries and authorization tests.
- [ ] Implement mutation outbox, idempotent push, sequence-based pull, tombstones, 409 resolution.
- [ ] Local→account merge preview, retries, sign out/data retention, cloud data export/delete.
- [ ] Add API deploy to staging, error/latency metrics without personal values.
**Gate:** Two devices converge after offline edits; duplicates prevented; IDOR tests fail closed; delete account works.

## 5. Phase 3 — social competition
- [ ] Groups + invites (token hash, expiry, replay prevention, limits).
- [ ] Challenge setup, eligibility validation and locked budget caps.
- [ ] Aggregate-only leaderboard calculation, challenge consent and status.
- [ ] Group removal/leave/block/privacy controls; abuse & authorization tests.
- [ ] UX polish: fairness explanations, group empty states, pending sync states.
**Gate:** No participant can fetch another participant's transactions or notes; ranking correct on fixtures, currency mismatch not ranked.

## 6. Dependencies and priorities
```
Theme + DB → CRUD → Aggregations → Budgets → Settings + Export → Phase 1 Release
Phase 1 → OIDC + API → Sync → Accounts Release
Accounts + Sync → Groups → Challenges → Leaderboard → Social Release
```
**Must not** implement bank integrations, income, AI or recurring expense automation unless change-requested. Avoid speculative server abstractions in Phase 1.

## 7. Claude Code execution protocol
At the start of each slice:
1. Read related PRD IDs, app flow, TRD, schema and design tokens.
2. Output a brief implementation checklist and impacted files.
3. Implement small vertical commits with tests; run formatter/analyzer/test suite.
4. Update `docs/progress.md` with completed IDs, test output, migration notes, next tasks and open issues.
5. Mark completed only after acceptance criteria pass; do not claim device tests run if no emulator/device available.
6. Pause feature expansion at phase gate and report blockers honestly.

### Suggested initial Claude Code prompt
> Read `docs/01-PRD.md` through `docs/06-IMPLEMENTATION-PLAN.md` in order. Build only Phase 0 and Phase 1 of Money Well Spent. Follow feature IDs and screen routes exactly. Use the chosen offline-first Flutter/Drift stack, apply the confirmed brand colors and glass rules, and avoid implementing accounts or backend until Phase 1 is accepted. First inspect the existing repo, then create a file-level plan and the tests for the first vertical slice. Implement incrementally, run checks and maintain `docs/progress.md`. Ask only for an actual blocking decision; otherwise follow documented defaults and note assumptions in an ADR.

## 8. Release checklist
- [ ] No expenses disappear across app restart/migration.
- [ ] Currency values exact for 0/2/3-decimal currencies.
- [ ] Correct weeks, months, leap year, DST and local time boundary.
- [ ] No internet required to record/review budgets.
- [ ] Export checked for accuracy and spreadsheet formula injection.
- [ ] Screen reader, contrast, keyboard, large text, reduced motion pass.
- [ ] App size/performance measured on mid-range Android.
- [ ] Privacy disclosures describe actual data flow, not aspirational behavior.
- [ ] P0 acceptance matrix and CI checks passed.
