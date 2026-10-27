# Phase 1 release verification

## Automated evidence
- [x] Explicit guest onboarding reaches Home with saved currency/timezone.
- [x] UI create → edit → delete → Undo updates real local SQLite data.
- [x] 100-entry file-backed ledger survives reopen with exact expected totals.
- [x] 0/2/3-decimal parsing, limits and malformed input.
- [x] Date boundaries, DST spring/fall, leap year and week rollover.
- [x] Category shares reconcile and archived history remains available.
- [x] Budget threshold deduplication, edits/deletes and period rollover.
- [x] CSV quoting, exact amounts, timestamps and formula mitigation.
- [x] Unsupported newer schema retains existing records on failed open.
- [x] 200% text-scale Home smoke test and actual rendered brand preview.

## Must verify before release
- [ ] Successful Android debug/release build on a configured SDK.
- [ ] Successful iOS simulator/device build with full Xcode.
- [ ] Airplane-mode create/edit/delete/export and restart on both platforms.
- [ ] Native share sheet, backup exclusion, launcher icons and timezone detection.
- [ ] Screen reader, contrast, keyboard, safe areas, dark mode, narrow phones/tablets.
- [ ] p95 save/report timings on representative Android hardware; app size and 50k-entry load.
- [ ] Production signing, store privacy disclosures, no P0 defects.

Optional P1 follow-ups: OS notification adapter and validated duplicate-safe JSON backup/import. Separate environment flavors become meaningful with Phase 2 endpoints; no backend environments exist in Phase 1.
