---
phase: 06-detailed-api-review
plan: 01
subsystem: api
tags: [wow-addon, lua, cooldown, behavioral-analysis, api-review]

requires:
  - phase: 05-ui-configuration
    provides: HideWhenOffCooldown checkbox and RefreshHideWhenOffCooldown integration
  - phase: quick/2-audit-codebase
    provides: QT-2 API signature audit baseline (37/37 PASS)

provides:
  - Complete behavioral analysis of all 4 HideSpellOffCD branch files
  - All 6 research pitfalls analyzed with explicit verdicts
  - 18-scenario WoW game state matrix with code path traces
  - Prioritized fix list (FIX-01 through FIX-04) for Plan 02

affects: [06-02-PLAN.md, future Midnight compatibility work]

tech-stack:
  added: []
  patterns:
    - "Fail-show philosophy verified: all error paths return false (show icon)"
    - "isOnGCD=true correctly returns false (GCD is not a real cooldown)"
    - "Secret Value guard pattern: IsSecretValue check before arithmetic on cdInfo.duration"

key-files:
  created:
    - .planning/phases/06-detailed-api-review/06-FINDINGS.md
  modified: []

key-decisions:
  - "Pitfall 5 (Secret Values) requires FIX-01 code change for Midnight forward-compatibility"
  - "Pitfall 1 (1.5s GCD threshold) is acceptable risk — intentional fail-show for short-CD edge case"
  - "Pitfall 3 (hooksSetup flag) is non-issue — synchronous LoadAddOn guarantees viewer frames exist"
  - "No current-live bugs identified — only 1 future-proofing fix and 3 documentation improvements"
  - "GCD-only state correctly hides icons (isOnGCD=true → not on real cooldown → hide is intended)"

requirements-completed: [REVIEW-01, REVIEW-02, REVIEW-03]

duration: 5min
completed: 2026-03-13
---

# Phase 6 Plan 01: Detailed API Review - Behavioral Analysis Summary

**Behavioral code path trace of all 4 HideSpellOffCD files: 0 current-live bugs found, 1 Midnight forward-compat fix identified (IsSecretValue guard for cdInfo.duration arithmetic)**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-03-13T13:29:28Z
- **Completed:** 2026-03-13T13:33:52Z
- **Tasks:** 2 (scenario matrix included in same document as code path analysis)
- **Files modified:** 1

## Accomplishments

- Traced every code path in all 4 in-scope files (Globals.lua:641-724, HideWhenOffCooldown.lua entire, GUI.lua:1959-1973, CooldownManager.lua diff) with fail-show compliance verified at every branch
- Produced explicit verdicts for all 6 research pitfalls from 06-RESEARCH.md — 4 non-issues, 1 acceptable risk, 1 future-proofing fix
- Built 18-scenario WoW game state matrix covering all required scenarios (normal CD, GCD, charges, combat, loading, spec change, talent swap, toggle on/off, invalid data, addon load order, Secret Values)
- Produced a prioritized fix list (FIX-01: code change; FIX-02/03/04: documentation) ready for Plan 02 execution

## Task Commits

1. **Task 1: Code path trace and pitfall verdicts** — `43554b5` (docs)
   - Task 2 (scenario matrix + fix list) was completed in the same document in the same pass — no separate commit needed as all content was written atomically.

## Files Created/Modified

- `/home/sntanavaras/random-projects/BetterCooldownManager/.planning/phases/06-detailed-api-review/06-FINDINGS.md` — Complete behavioral analysis: code path tables for all 4 files, 6 pitfall verdicts, 18-scenario matrix, 4-item fix list (619 lines)

## Decisions Made

- **GCD-only state hides icons (intended):** When `isOnGCD=true`, `IsSpellOnCooldown` returns false (not on real cooldown) → `SetAlpha(0)` → icon hides during GCD. This matches the feature design: only show icons actively on a meaningful cooldown.
- **Pitfall 1 threshold: acceptable risk:** The 1.5s fallback only triggers when `isOnGCD` is nil (outside SPELL_UPDATE_COOLDOWN events) AND duration <= 1.5s. Real risk is narrow (short-CD spell during zone transition); behavior is fail-show direction (shows when uncertain). No code change needed.
- **FIX-01 is the only code change needed:** Secret Value guard is cheap (2-3 lines) using existing `BCDM:IsSecretValue()` infrastructure, forward-compatible with Midnight, no behavior change on live TWW.

## Deviations from Plan

None — plan executed exactly as written. Both tasks completed in a single document pass since the scenario matrix was written concurrently with the code path analysis.

## Issues Encountered

None.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

06-FINDINGS.md provides the complete input for Plan 02:
- **FIX-01:** Add `IsSecretValue` guard before `cdInfo.duration` arithmetic in `IsSpellOnCooldown` (Core/Globals.lua:714-719)
- **FIX-02:** Add comment explaining 1.5s fallback rationale (Core/Globals.lua:712-716)
- **FIX-03:** Add comment explaining `GetAlpha()` semantics in `CenterWrappedRows` (Modules/CooldownManager.lua)
- **FIX-04:** Add comment explaining hooksSetup execution order guarantee (Modules/HideWhenOffCooldown.lua:88)

No blockers. Feature is ready to ship on live TWW after Plan 02 documentation/hardening improvements.

---
*Phase: 06-detailed-api-review*
*Completed: 2026-03-13*
