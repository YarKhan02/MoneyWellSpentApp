# Money Well Spent — Technical Requirements Document
**Version:** 1.0 | **Status:** Proposed implementation contract | **Updated:** 2026-10-27

## 1. Architecture decisions (explicit defaults)
These are **proposed technical choices**, not previously user-approved. Claude Code must implement as documented unless instructed otherwise; record deviations in an ADR before coding. No server is necessary to ship Phase 1.

| Concern | Decision | Rationale |
|---|---|---|
| App | Flutter stable + Dart, Material 3 customized | One codebase for Android/iOS, responsive and animation-ready |
| State/navigation | Riverpod + go_router | Testable state and declarative routes |
| Local persistence | SQLite via Drift | Typed reactive queries, offline migrations |
| Money | Int64 minor units + `currency_code` | Exact calculations |
| Visuals | ThemeExtensions + design tokens, fl_chart for charts | One consistent design system |
| Secure storage | flutter_secure_storage | Auth and device secrets only; not bulk finance records |
| Backend (Phase 2+) | Go, Gin, PostgreSQL, sqlc, golang-migrate | Thin API, explicit SQL and authorization |
| Authentication | Managed OIDC provider via PKCE for native clients, vendor TBD | Avoid custom password implementation |
| Hosting | Managed Postgres + HTTPS API, provider TBD | Deploy portability |
| CI | GitHub Actions (format, analyze, unit/integration, build) | Repeatable checks |
| Testing | flutter_test, integration_test, Go tests, PostgreSQL integration via testcontainers | Data safety |

No Redis, event bus, AI, push notification service or microservices in Phase 1. Phase 3 may introduce async leaderboard caching only when necessary.

## 2. Module boundaries
```
mobile/lib/
  app/                  # bootstrap, routing, dependency setup
  core/design/          # tokens, text, reusable components
  core/money/           # amount parsing/formatting, currency exponent
  core/time/            # periods and timezone helpers
  core/storage/         # Drift DB, migrations
  features/onboarding/
  features/expenses/    # UI, domain, repository, data
  features/categories/
  features/budgets/
  features/reports/
  features/settings/
  features/auth/        # Phase 2
  features/sync/        # Phase 2
  features/social/      # Phase 3
server/                 # Phase 2+
  cmd/api/
  internal/auth/
  internal/expenses/
  internal/budgets/
  internal/sync/
  internal/social/
  internal/store/
  migrations/
```
UI imports domain use cases, not raw DB; repositories hide local vs remote persistence. All expense writes go to local DB first. Backend never required to display a guest dashboard.

## 3. Local data rules
- ULID/UUIDv7 client-generated IDs to allow offline creation.
- `created_at_utc`, `updated_at_utc`, `deleted_at_utc?`; soft-deletes sync as tombstones.
- Every write transactionally updates data; widgets subscribe to reactive aggregate queries.
- Database migrations additive, transactional where supported, tested against at least two previous versions.
- No raw SQL string interpolation. Use bound parameters.
- Exports: UTF-8 CSV with formula injection mitigation and ISO 8601 timestamps; system share sheet with user confirmation.
- Never log financial notes, balances, authentication tokens or invite tokens.

## 4. Domain and calculation rules
- Expense `amount_minor > 0` and bounded by 9e14 minor units; chosen app currency must match expense currency.
- `periodStart`/`periodEnd` derived from IANA timezone, then converted to UTC; lower bound inclusive, upper bound exclusive.
- Weekly start Monday initially; if changed, reports and budgets consistently rerender according to that preference.
- Period aggregates derived from source expenses, not accumulated mutable dashboard counters.
- Category breakdown totals sum to period total; archived categories count historically.
- Limits: weekly and monthly budgets can coexist independently; category budgets deferred.
- Alert dedup key `(budget_id, period_start, threshold)`; recalculate when expenses edited/deleted.

## 5. Phase 2 API contract
Base `/v1`; HTTPS required. JSON snake_case; RFC 3339 timestamps, ID strings, amount integers. Authorization Bearer token from verified OIDC ID/access token as appropriate; backend validates issuer, audience, expiration, signature, subject. All resources scoped by server-derived `sub`, **never by client-supplied owner ID**.

| Verb | Endpoint | Purpose |
|---|---|---|
| GET | `/v1/me` | My profile and config |
| PATCH | `/v1/me` | Update safe profile settings |
| GET/POST | `/v1/expenses` | Cursor-paged list / create |
| GET/PATCH/DELETE | `/v1/expenses/{id}` | Owned expense operation |
| GET/POST | `/v1/categories` | Owned+system categories / create |
| PATCH | `/v1/categories/{id}` | Update/archive own category |
| GET/PUT | `/v1/budgets/{period_type}` | Get/upsert weekly/monthly cap |
| POST | `/v1/sync/push` | Idempotent mutation batch |
| GET | `/v1/sync/pull?cursor=...` | Incremental user-scoped changes incl. tombstones |
| DELETE | `/v1/me` | Delete cloud account and its data |

Example create expense:
```json
{
  "id": "0192a8b7-0000-7000-8000-000000000001",
  "amount_minor": 1450,
  "currency_code": "SAR",
  "category_id": "0192a8b7-0000-7000-8000-000000000002",
  "occurred_at": "2026-10-27T08:15:00Z",
  "note": "Lunch",
  "client_updated_at": "2026-10-27T08:16:00Z"
}
```
Response: 201 + canonical object and `revision` integer. Validation errors: 422 with stable field error codes; 401 unauthenticated; 403 forbidden group action; 404 non-owned row (to prevent enumeration); 409 version conflict; 429 request rate limit.

### Sync protocol
- Persist local outbox `{mutation_id, entity_type, entity_id, op, payload, enqueued_at, attempts}`.
- Push `mutation_id` for idempotency (unique per actor); backend applies only once within one DB transaction.
- Pull ordered change log keyed by monotonic server sequence and user partition, not wall-clock timestamp.
- On concurrent revisions, backend returns 409 with current canonical object; client displays conflict resolution (default keep server with user prompted to reapply local edit). Never silently discard a local new transaction.
- Guest account migration: batch upload under same stable client IDs, transactionally idempotent, mark acknowledged outbox entries only after server success.
- Backoff exponential with jitter; manual retry; sync status visible; queue survives restart.

## 6. Phase 3 API additions
| Verb | Endpoint | Purpose |
|---|---|---|
| POST/GET | `/v1/groups` | Create / list joined private groups |
| POST | `/v1/groups/{id}/invites` | Owner issues expiring single-use invite |
| POST | `/v1/invites/{token}/accept` | Authenticated recipient accepts |
| DELETE | `/v1/groups/{id}/members/{user_id}` | Owner removes member; user can remove self |
| POST/GET | `/v1/groups/{id}/challenges` | Create / list challenges |
| POST | `/v1/challenges/{id}/enroll` | Accept rules; lock cap where required |
| GET | `/v1/challenges/{id}/leaderboard` | Server-calculated aggregate-only ranking |
| POST | `/v1/users/{id}/block` | Block abusive account |

Challenge creation takes IANA timezone, period enum, mode enum, base currency; immutable once started. API must apply per-member participation permissions and do all aggregations server-side. Never accept ranking score from client.

## 7. Security and privacy requirements
- Restrict endpoints by authenticated principal, object ownership and group membership; use SQL owner filter in query, not post-fetch checks only.
- Guest mode must not use analytics tracking or upload anything by default.
- OIDC authorization code + PKCE in system browser; refresh tokens encrypted in OS-protected storage; redact errors.
- Rate limit auth sensitive endpoints, invite creation/acceptance; enforce token expiry and one-time use using hashed token stored server-side.
- No transactions exposed to friend group API. All leaderboard outputs limited to user display name, participation state, aggregate score, rank.
- Account erasure includes subordinate records, change logs, export jobs and revocation as feasible; retention policy documented before release.
- Encrypt transport with TLS; rely on platform storage encryption and optional encrypted local DB enhancement after performance review (make security claim precise).
- Backups encrypted server-side; production secrets in secret manager; database least-privilege role.
- Abuse prevention, minimal audit metadata; do not log personally sensitive amount/note content.

## 8. Quality and performance targets
- Cold launch to functional guest home: target < 2.5 sec on representative mid-range Android device.
- Save expense local roundtrip: p95 < 250ms under 10k records.
- Period views: p95 < 400ms at 50k local expenses with indexes.
- Mobile scroll 60fps target with glass blur layers bounded and disabled/reduced under low-power modes.
- Crash-free rate target >= 99.5% (opt-in aggregated telemetry only).
- APIs p95 < 400ms for simple CRUD excluding network under normal load; measure rather than assert.

## 9. Test matrix
Unit: money exponents, parsing, validation, leap day, DST, week boundaries, 0 spend/overbudget, roundoff; category aggregation. Widget: empty states, form errors, dynamic text scale, keyboard insets. Integration: offline CRUD/export/migrations; sign-in migration, retry duplicates/conflicts, ownership denial, invite replay/expiration, incomplete leaderboard. Release: Android/iOS builds, accessibility scanner, airplane-mode flows, corrupt import rejection, account deletion.

## 10. Environment and rollout
`dev`, `staging`, `prod` OIDC projects + API endpoints (Phase 2). No secrets in repo. Feature flags: `account_enabled`, `sync_enabled`, `social_enabled` default false until tested. Migrations before server deploy with rollback plan; app upgrades tolerate additive schema changes. Privacy policy and export/delete behavior must match actual implementation.
