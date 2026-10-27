# Local issue 001 — Core ledger milestone achieved

Status: achieved in automated verification, 2026-10-27. No GitHub issue created (user requested local tracking).

Delivered EXP-01/02/03 and LOC-01: exact 0/2/3-decimal money, local SQLite writes, create/edit, duplicate-safe insert, category management/archive, confirmation and soft-delete/undo, Activity filtering and expense detail.

Evidence: `flutter analyze` clean; `flutter test` 16 passing. Repository test writes 100 entries to a file-backed database, edits/deletes/restores records, closes and reopens SQLite, and verifies the exact remaining total. Tests cover invalid money, notes, currency mismatch and archived category behavior.

Native airplane-mode acceptance is pending toolchain/device availability; this issue does not claim a device release gate passed.
