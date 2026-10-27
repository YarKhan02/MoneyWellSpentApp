# Phase 1 traceability

| Feature | Screens | Entities | Verification |
|---|---|---|---|
| ACC-01, LOC-01 | Welcome, Setup, Home | Local profile, SQLite | Bootstrap, persistence, restart |
| EXP-01/02/03 | Add, Activity, Detail, Categories | Expenses, categories | Exact money, CRUD, duplicate save, archive, undo |
| EXP-04/05 | Home, Insights, filtered Activity | Derived expense aggregates | Raw SQL reconciliation, DST, calendar boundaries |
| BUD-01/02 | Budget, Edit cap | Budgets, alert deliveries | Threshold dedup, edits, deletes, rollover |
| LOC-02, ACC-02 | Settings | Preferences, export | CSV escaping, formula injection, currency lock, erase |
| UX-01 | All Phase 1 screens | Shared theme | Large text, semantics, reduced motion, offline flow |

Phase 2 and 3 are explicitly excluded.
