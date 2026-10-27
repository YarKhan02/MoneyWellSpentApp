# Money Well Spent — Product Requirements Document
**Version:** 1.0 | **Status:** Build baseline | **Updated:** 2026-10-27

## 1. Product purpose
Money Well Spent (MWS) is a playful, premium-feeling, expense-only tracker that makes personal spending understandable with minimal effort. The core action is: enter an amount, select a category, save. Users can see daily, weekly, monthly, and yearly spending, set spending caps, and optionally compare budget discipline with friends. **No sign-in is required for private tracking.**

### Goals
- Capture a transaction in fewer than 10 seconds on a typical repeat entry.
- Make remaining budget and category breakdown readable at a glance.
- Keep private financial data local by default; require opt-in account + sync for social features.
- Offer competition without exposing individual transactions to friends.

### Non-goals for initial release
Income, bank connections, automatic SMS/email import, subscription billing, AI advice, investment/net-worth tracking, multi-currency aggregation, and web admin dashboards.

## 2. Product decisions and terminology
- Platform: mobile-first Android/iOS, responsive layouts; default local-only guest mode.
- Transaction: expense with positive minor-unit amount (e.g. cents, halalas, paisa), category, occurred-at date/time, optional note.
- Currency: one chosen base currency per profile; no FX conversions. Changing currency after recording expenses requires explicit archive/new-book flow (not silent number relabeling).
- Calendar: user's selected timezone and locale; week starts Monday by default, configurable in settings later.
- Budget period: weekly or monthly cap. Daily/yearly views are reports, not independently capped in MVP.
- Budget discipline ranking: percent of configured budget used, with eligibility rules; total-spent ranking: lowest total eligible spend wins. These are **separate** leaderboards.
- Competitions: opt-in with accepted invites, shared period and currency; spend totals/metrics visible, transactions and notes never visible.

## 3. Personas / scenarios
- Solo guest: capture coffee, groceries, ride, review weekly spend offline.
- Budget keeper: set weekly cap, monitor remaining balance and alerts.
- Social user: sign in, join a friend group, choose discipline or total-spent board, compare progress.

## 4. Requirements — Phase 1 (ship first)
| ID | Priority | Feature | Behaviour and acceptance criteria |
|---|---|---|---|
| EXP-01 | P0 | Quick add expense | Enter positive amount, category and optional note/date; Save persists locally and updates dashboard without network. Prevent zero, negative, malformed or above-max amounts. Default date is now. |
| EXP-02 | P0 | Expense history | Reverse chronological list grouped by local date; tap to view/edit; delete requires confirmation and supports short undo via local soft-delete. Filtering by date/category. |
| EXP-03 | P0 | Categories | Seed Food & Drinks, Groceries, Transport, Shopping, Bills, Health, Entertainment, Other; custom categories: create/edit/archive; deleting a used category is disallowed, archive instead. |
| EXP-04 | P0 | Dashboard | Today, this week, this month cards; weekly progress if budget exists; recent expenses; primary Add action; empty states. |
| EXP-05 | P0 | Reports | Totals for day/week/month/year and category shares for selected period; category totals reconcile to overall total. Zero-expense states handled. |
| BUD-01 | P0 | Spending budgets | Create one weekly and/or one monthly overall cap; show used, remaining, overage and percent (100%+ supported); prevent duplicate active cap for same period type. |
| BUD-02 | P1 | Budget signals | Local 75%, 90%, 100% threshold alerts once per period/threshold; opt-in device notifications, with in-app notices working even without permission. |
| LOC-01 | P0 | Offline first | Every Phase 1 core feature works without connectivity. Data survives restart and app updates. |
| LOC-02 | P0 | Settings | Currency, timezone display, week-start setting, notification preference, export CSV and destructive erase-local-data confirmation. |
| ACC-01 | P0 | Guest onboarding | User enters app with no account/permissions; simple 2-screen walkthrough can be skipped. Local database created. |
| ACC-02 | P1 | Guest backup/export | CSV export with schema and timestamps; optional local JSON backup/restore, validated and duplicate-safe. No unannounced cloud backup. |
| UX-01 | P0 | Visual polish & accessibility | Premium clean glassmorphism; readable text and contrast, large tap targets, reduced-motion settings and screen-reader labels. |

### Phase 1 Definition of Done
A fresh install can set currency, create expenses, review period and category charts, set a weekly/monthly cap, edit/delete, export, and function in airplane mode. Data totals remain consistent after timezone/day rollovers and app restarts.

## 5. Requirements — Phase 2 (accounts and sync)
| ID | Priority | Feature | Behaviour and acceptance criteria |
|---|---|---|---|
| ACC-03 | P0 | Optional sign-in | Email magic link or OAuth (provider selected at implementation); guests retain full local features; sign-in is needed only to sync and join groups. |
| SYN-01 | P0 | Guest-to-account migration | Preview count, confirm upload, attach local records to new account, avoid duplicate records across retries; never delete local data until remote acknowledgment. |
| SYN-02 | P0 | Multi-device sync | Incremental sync, optimistic offline writes, retry queue, tombstones, documented conflict rule; last server-accepted edit per record plus conflict indicator. |
| ACC-04 | P1 | Account delete | Account, owned cloud transactions, budgets, memberships and invites removed per retention policy; local device erase choice shown. |
| SEC-01 | P0 | Privacy controls | Profile private by default; no public discovery, address book permissions, public spending feed or raw transaction sharing. |

## 6. Requirements — Phase 3 (friends and challenges)
| ID | Priority | Feature | Behaviour and acceptance criteria |
|---|---|---|---|
| SOC-01 | P0 | Friend groups | Signed-in users create a private group and send invite via short-lived token/link; invitee explicitly accepts; owner can remove member; user can leave. |
| SOC-02 | P0 | Challenge setup | Group chooses week or month, discipline vs total-spent, common currency, shared start/end boundaries. No retroactive changes once active. |
| SOC-03 | P0 | Leaderboard | Ranking shows display name, eligible aggregate and position only, not category or transaction details; users may hide from participation. |
| SOC-04 | P0 | Budget fairness | Discipline challenges require an accepted, locked cap per member set before challenge begins; unbudgeted members marked ineligible. Display percent used; lower is better. |
| SOC-05 | P0 | Comparison fairness | Total-spent challenges compare only same currency and entire time window; no cross-currency comparisons. Show "personal tracking, not absolute financial virtue" copy. |
| SOC-06 | P1 | Social safety | Block/report member, leave challenge, revoke invites; rate-limit invitations; no minors-oriented social targeting or public leaderboard. |

**Leaderboard computation:** `sum(expense.amount_minor)` for non-deleted expenses whose occurred-at instant falls within challenge start inclusive/end exclusive in challenge timezone. Discipline score = `100 * eligible_spent / locked_budget_cap`; lowest wins. Zero-cap cannot enroll. Ties share rank by score with deterministic secondary alphabetical display only. Challenges have a clear 'not eligible' state if unsupported currency or missing cap; do not silently rank 0 as best.

## 7. Detailed edge cases
- **Time:** store UTC timestamps; render by user-selected IANA timezone. DST and cross-midnight entries must fall into exactly one local calendar period.
- **Money:** integer minor units only, use currency exponent from ISO 4217 (JPY 0, USD 2, KWD 3, etc.); no floating-point arithmetic. Notes sanitized and limited to 280 characters.
- **Categories:** archived categories remain visible in historical analytics but cannot be selected for new expenses.
- **Budgets:** editing cap changes current future calculations, with audit snapshot later for social locked caps. Negative remaining is valid and shown as over budget.
- **Sync:** offline guest mode never sends data; signing out removes auth credentials but retains offline data per explicit preference.
- **Leaderboards:** do not fabricate scores for missing or partial data; show “sync pending” until server computation is authoritative.

## 8. Success metrics (privacy-safe)
- Median create-expense completion duration (opt-in telemetry only).
- 7-day active tracking retention; weekly budget adoption.
- Crash-free sessions; local data loss incidents (target zero).
- Sync convergence error rate; challenge participation opt-in and completion.
**Do not collect** expense amounts, notes or category-by-user content through analytics SDK.

## 9. Launch gates
Functional tests for arithmetic and periods, accessibility review, offline test matrix, schema migration/restore rehearsal, and no P0 defects. Phase 2 and 3 only start after Phase 1 passes these gates.
