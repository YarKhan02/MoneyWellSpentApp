# Money Well Spent — Claude Code Instructions

You are building **Money Well Spent**, an offline-first, mobile expense tracker. Treat `docs/` as the source of truth; this file is the standing instruction for every task.

## Read the relevant specs before editing
- `docs/01-PRD.md` — requirements, scope, feature IDs, acceptance criteria
- `docs/02-TRD.md` — stack, architecture, APIs, tests, security
- `docs/03-APP-FLOW.md` — navigation and screen behavior
- `docs/04-DESIGN-BRIEF.md` — brand, UI tokens, components
- `docs/05-BACKEND-SCHEMA.md` — local/server data and authorization
- `docs/06-IMPLEMENTATION-PLAN.md` — dependencies, phase gates, build order

At session start, check `docs/progress.md` if present, inspect the repo and read the specs relevant to the requested work. Do not reread all six files for every small edit; consult specific sections as needed. If documentation conflicts, flag it and propose a decision rather than silently improvising.

## Non-negotiable product rules
- **Phase 1:** guest mode, expenses only, on-device SQLite, fully usable offline; **no login or backend dependency**.
- Daily/weekly/monthly/yearly spending insights and weekly/monthly budgets.
- **Phase 2:** optional accounts, backup and sync. **Phase 3:** friend groups and opt-in leaderboards. Never implement later phases unless requested.
- Personal expense entries, notes and category details stay private; friends may see only explicitly allowed aggregate challenge metrics.
- Money uses integer minor units; handle timezones, currency and date boundaries correctly. Never silently discard or overwrite financial records.

## Engineering defaults
- Mobile: Flutter/Dart, Riverpod, go_router, Drift/SQLite.
- Backend *only when authorized for Phase 2+:* Go/Gin, PostgreSQL/sqlc/migrations, managed OIDC.
- Use existing project conventions where compatible. No unnecessary services, abstractions, libraries or premature backend scaffolding.
- Every feature requires validation, loading/empty/error states, accessible interaction and meaningful tests. Run formatter, static analysis and affected tests; report anything that cannot be run.
- Never hardcode credentials, weaken authorization or expose private expense data in logs.

## Design rules
- Clean, playful, premium **glassmorphism**, sparingly applied with readable opaque fallbacks.
- Palette: Forest Fern `#327039`, Wheat Field `#F0BE49`, Tilled Earth `#133020`, Alabaster Hay `#F8EDD9`, Cherry Grove `#DD5C36`.
- Use centralized design tokens and shared components. Respect contrast, touch targets and reduced motion.
- Use the approved finance-symbol logo asset once provided; do not invent a replacement.

## Workflow on each task
1. Identify phase, feature IDs, affected screens and data rules. Inspect existing code before changing it.
2. Make the **smallest complete vertical slice** consistent with the specs; avoid unrelated refactors.
3. Add/update tests, run relevant checks and fix failures you introduced.
4. Update `docs/progress.md` with completed work, pending work and blockers; update specs/ADR only when a deliberate decision changes them.
5. Respond briefly: changed files, behavior delivered, test results and next recommended task. Do not claim tests or deployments succeeded unless verified.

**If no specific task is given:** inspect the repo, determine the next unchecked milestone in `docs/06-IMPLEMENTATION-PLAN.md`, explain the intended slice and begin only if the user's instruction authorizes implementation.
