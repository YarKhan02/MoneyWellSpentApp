# Local milestone issues

The user requested local records instead of GitHub issues on 2026-10-27. No remote issues have been created.

| Issue | Milestone | Status |
|---|---|---|
| [001](issues/001-core-ledger.md) | Core ledger | Achieved in automated verification |
| [002](issues/002-insights.md) | Dashboard and insight calculations | Achieved in automated verification |
| [003](issues/003-budgets.md) | Budgets and in-app threshold signals | Achieved in automated verification |
| [004](issues/004-settings-export.md) | Settings, export and guest UI | Achieved in automated verification |

## Open release blockers

- Complete Android command-line tools and license setup; finish native builds.
- Install/select full Xcode and the iOS plugin toolchain; validate iOS configuration/build.
- Run the device acceptance and performance checklist in `release-checklist.md`.

The foundation's native-build gate and final Phase 1 release gate remain open. Optional JSON restore and OS notifications are deferred; accounts/sync/social remain out of scope.
