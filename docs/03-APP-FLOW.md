# Money Well Spent — App Flow and Screen-by-Screen Specification
**Version:** 1.0 | **Status:** Navigation baseline

## 1. Navigation model
Bottom tabs in Phase 1: **Home**, **Activity**, **Insights**, **Budget**. A prominent floating **Add** action is reachable from Home and Activity. **Settings** via top-right profile/gear entry, not a fifth permanent tab. Phase 3 adds **Friends** as a fifth tab for signed-in users with social enabled (or a top-level hub surfaced prominently when narrow); never bury friends inside Budget.

```text
Splash → First-run setup (currency + timezone) → Home
Home ⇄ Activity ⇄ Insights ⇄ Budget
  └── Add Expense (sheet) → Save → previous screen + refreshed totals
Activity → Expense Detail → Edit / Delete
Budget → Set Weekly Cap / Set Monthly Cap
Insights → Period Picker → Category Drilldown (filtered Activity)
Settings → Preferences / Data Export / Help
[Phase 2] Settings → Sign In → Sync Overview / Account / Delete
[Phase 3] Friends → Groups → Group Detail → Challenge → Leaderboard
```

## 2. First-time flows
### F01 Splash / local DB bootstrap
Load local DB, apply migrations, preferences; no network gate. If corrupted, offer safe recovery/import not destructive silent reset. Route setup if no currency; else Home.

### F02 Welcome / setup (Phase 1)
Screen 1: succinct pitch + "Continue without account" primary. Screen 2: choose currency (default device region suggestion but confirm), timezone auto-detect editable; optional week-start preference. Completion initializes profile. No required notifications prompt. Account login teaser is Phase 2 only.

## 3. Main screens — Phase 1
### S01 Home `/home`
Header greeting + settings button. Summary: total spent Today, This Week, This Month; weekly progress with cap, remaining or overage. Content: recent 5 expenses; category quick highlights; prominent Add. Empty state explains first action. Tapping a metric opens Insights with matching period; recent item opens Expense Detail.

### S02 Add expense `/expenses/new` (bottom sheet)
Amount keypad / decimal entry with currency symbol, category chips/grid and “More”, optional note, occurred-at date/time, Save. Autofocus amount; sensible last-used category suggestion but never assume category silently. Save returns to previous route, shows confirmation and undo where applicable. Validation inline; prevent double-submit. Accessibility: proper amount keyboard and labels.

### S03 Activity `/activity`
Sticky month or period selector, category filter and grouped expense rows (date, icon, category, optional note preview, amount). Search notes locally may be P1; avoid complexity for v1. Empty/filter-empty states differentiated. Pull to refresh only Phase 2; don't imply cloud dependency.

### S04 Expense detail `/expenses/:id`
Full amount, category, date/time, note, created/edited information. Edit opens same form prefilled. Delete via confirmation modal; soft delete and show Undo snackbar. Stale/deleted deep links show safe not-found.

### S05 Insights `/insights`
Segmented Day / Week / Month / Year, date period navigator, total expense chart, category breakdown and ranked category list. Selecting category opens Activity with same range/category query filters. Ensure legend and text values make charts optional for accessibility. Default Month.

### S06 Budget `/budget`
Weekly and Monthly cards, each with cap, spent, remaining, progress and Edit/Set action; month/week date boundaries surfaced. Zero caps unset (not division by zero). Over budget state uses text + color, not red alone. Last modified label. Educational helper text on first use.

### S07 Edit budget `/budget/:periodType/edit`
Numeric currency entry; confirm save. Offer Remove budget separately with confirmation. Validate >0 and upper limit. Return with updated progress. Schedule threshold in-app alerts; OS notifications optional.

### S08 Settings `/settings`
Preferences: currency (locked once expenses exist unless archive/new ledger), timezone and week start; appearance follows system with accessible high-contrast fallback; device notifications optional. Data: CSV export, JSON backup/restore (P1), erase local entries (type-to-confirm). In Phase 2, Account & Sync section. Help/privacy entry. No raw account deletion in guest mode.

### S09 Category manager `/settings/categories`
List active/archived system/custom categories. Add custom name, icon, color; rename custom; archive custom. Seed categories are not deletable; archived category remains on old expenses. Duplicate normalized labels warned. Fast category selection available from Add Expense.

## 4. Phase 2 screens and interactions
### S10 Sign in `/account/sign-in`
Continue with supported OIDC flow; explicit message: tracking works without account; sync/social require sign-in. Login success transitions to migration preview if local expenses exist.

### S11 Merge preview `/account/migration`
Show local count vs account count, explain duplicate matching via stable IDs; confirm merge or cancel. No silent overwrite; progress/retry state visible. On failure remain in local mode with retained queue.

### S12 Sync status `/account/sync`
Last successful sync, queued operations, sync failures, Retry button, offline indicator. Sign-out choices explain what remains on device. Account deletion confirmation opens authenticated delete flow.

## 5. Phase 3 screens and interactions
### S13 Friends hub `/friends`
Private groups list, pending invitations, Create group. Signed-out state with privacy-focused invitation to sign in.

### S14 Group detail `/friends/groups/:id`
Member avatars and display names, outstanding invites, active/upcoming/finished challenges; owner menu for member management, all members can leave.

### S15 Create challenge `/friends/groups/:id/challenges/new`
Pick mode (discipline/total spent), common period and currency, clear eligibility/visibility explanation; start next full week/month by default for fairness. Confirm locks rules.

### S16 Challenge detail `/friends/challenges/:id`
Start/end, participation eligibility, enrollment and lock cap where relevant, leaderboard, "Only totals are shared" privacy notice. Show incomplete/offline state without invented rank. For both modes display exact interpretation and status.

### S17 Invitation `/invite/:token`
If signed out → sign in while preserving token. Preview group name and inviter display name, explicit Accept/Decline; invalid/expired/reused token state. Never autojoin.

## 6. Interactions / states every screen must cover
- Loading: use skeletons only when loading exists (local startup is brief); do not flicker.
- Empty: provide a relevant CTA; no fake sample finance data presented as real data.
- Errors: form inline validation; export permission/share failures; offline sync banner only when relevant.
- Accessibility: screen reader reading order, 44×44pt tap targets, semantics for each icon, charts with numeric summaries.
- Navigation: back button restores filters and scroll; no destructive reinitialization after edit.
- Mobile keyboard: save button remains reachable; safe areas, portrait, tablets, RTL-aware spacing planned but localization can be later.

## 7. Flow acceptance tests
1. Offline first run → setup → add two expenses → Home and Insights totals reconcile.
2. Edit expense date across calendar week → old and new week counts update.
3. Delete + undo → totals restored; archived category still in old reports.
4. Change timezone near midnight → grouping matches selected timezone.
5. Set cap, exceed cap → overage shown and threshold alert deduplicated.
6. Phase 2 sign in after offline entries → no duplicates after 3 retries.
7. Phase 3 invite expired/used → no unauthorized join; member sees aggregates not receipts/notes.
