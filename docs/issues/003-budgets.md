# Local issue 003 — Budget calculation and signal milestone achieved

Status: achieved in automated verification, 2026-10-27. No GitHub issue created.

Delivered BUD-01 and in-app BUD-02: weekly/monthly cap create/edit/remove, used/remaining/overage and percent above 100, durable 75/90/100 threshold ledger. Writes refresh the observed ledger; timer/resume refresh calendar periods.

Evidence: `flutter test` covers threshold recrossing after edits, delete/undo, cap editing without duplicate active budgets and a new period receiving a new set of signals.

Optional OS notifications are deferred; the app explicitly presents in-app signals and does not request notification permissions.
