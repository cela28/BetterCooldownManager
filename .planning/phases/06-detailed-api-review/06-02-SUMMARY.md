---
phase: 06-detailed-api-review
plan: 02
subsystem: api
tags: [wow, lua, cooldown, midnight, secret-value, fail-show, forward-compat]

# Dependency graph
requires:
  - phase: 06-detailed-api-review/06-01
    provides: "Prioritized fix list (FIX-01 through FIX-04) from behavioral code-path analysis"
provides:
  - "IsSecretValue guard in IsSpellOnCooldown for Midnight 12.0 compatibility"
  - "Documented 1.5s GCD fallback rationale in Globals.lua"
  - "Documented GetAlpha() own-alpha semantics in CooldownManager.lua"
  - "Documented hooksSetup execution-order guarantee in HideWhenOffCooldown.lua"
  - "Post-Fix Verification section in 06-FINDINGS.md with ship-ready verdict"
affects: [HideSpellOffCD, ship-readiness-review]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "IsSecretValue guard before arithmetic on cooldown duration fields (Midnight forward-compat pattern)"
    - "Fail-show on unreadable duration: return false keeps icon visible when API data is opaque"

key-files:
  created: []
  modified:
    - Core/Globals.lua
    - Modules/HideWhenOffCooldown.lua
    - Modules/CooldownManager.lua
    - .planning/phases/06-detailed-api-review/06-FINDINGS.md

key-decisions:
  - "FIX-01 places IsSecretValue guard before first arithmetic comparison on cdInfo.duration (between cdInfo nil check and isOnGCD check) — fail-show direction on opaque duration"
  - "Secret Value returns false (not true) so icon stays visible — conservative fail-show correct for an unreadable duration"
  - "All three documentation fixes (FIX-02/03/04) applied as pure comment additions with no code change"

patterns-established:
  - "Midnight guard pattern: check BCDM:IsSecretValue(field) before any arithmetic on API-returned numeric fields"

requirements-completed: [REVIEW-04, REVIEW-05]

# Metrics
duration: 10min
completed: 2026-03-13
---

# Phase 6 Plan 02: API Fix Application Summary

**IsSecretValue guard added to IsSpellOnCooldown plus three inline documentation improvements for future-proof Midnight 12.0 compatibility with zero current-live behavior change**

## Performance

- **Duration:** ~10 min
- **Started:** 2026-03-13T13:35:00Z
- **Completed:** 2026-03-13T13:37:51Z
- **Tasks:** 2
- **Files modified:** 4 (3 source, 1 planning)

## Accomplishments

- Applied FIX-01: Added `BCDM:IsSecretValue(cdInfo.duration)` guard in `IsSpellOnCooldown` before any arithmetic comparison on `cdInfo.duration`. Prevents Lua error in Midnight (12.0) when cooldown duration fields are returned as opaque Secret Values. No behavior change on current TWW live.
- Applied FIX-02/03/04: Added explanatory comments documenting the 1.5s GCD fallback rationale, `GetAlpha()` own-alpha semantics, and `hooksSetup` execution-order guarantee.
- Verified all five critical scenarios against the fixed code — all pass with fail-show semantics preserved.
- Appended Post-Fix Verification section to 06-FINDINGS.md with before/after code snippets and a final ship-ready verdict.

## Task Commits

Each task was committed atomically:

1. **Task 1: Apply all fixes from 06-FINDINGS.md** - `fa82a10` (fix)
2. **Task 2: Verify fixes and document final state** - `102d556` (docs)

## Files Created/Modified

- `/home/sntanavaras/random-projects/BetterCooldownManager/Core/Globals.lua` - Added IsSecretValue guard (FIX-01) and expanded 1.5s fallback comment (FIX-02)
- `/home/sntanavaras/random-projects/BetterCooldownManager/Modules/HideWhenOffCooldown.lua` - Added hooksSetup execution-order comment (FIX-04)
- `/home/sntanavaras/random-projects/BetterCooldownManager/Modules/CooldownManager.lua` - Added GetAlpha() semantics comment (FIX-03)
- `/home/sntanavaras/random-projects/BetterCooldownManager/.planning/phases/06-detailed-api-review/06-FINDINGS.md` - Appended Post-Fix Verification section with scenario re-verification and ship-ready verdict

## Decisions Made

- FIX-01 placed between the `cdInfo` nil check and the `isOnGCD` check — earliest possible point before any arithmetic, and after confirming cdInfo exists.
- Secret Value guard returns `false` (fail-show = icon stays visible) rather than `true` — when we cannot read duration we cannot confirm a cooldown exists, so keeping the icon visible is the conservative choice.
- FIX-02 comment written as a block comment above the fallback check to explain the trigger conditions and trade-off rather than just labeling it.
- FIX-04 placed as a block comment directly before `hooksSetup = true` so the next reader sees the reasoning at the exact assignment point.

## Deviations from Plan

None — plan executed exactly as written. All four fixes from FINDINGS were applied in the order specified. The hooksSetup fix (FIX-04) was confirmed as a documentation-only change (not a code change) per FINDINGS Pitfall 3 verdict before execution, matching the plan's note to skip the code fix if FINDINGS called it a non-issue.

## Issues Encountered

None.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

The HideSpellOffCD feature is ship-ready:
- Zero current-live bugs remain
- Midnight 12.0 forward-compat guard in place
- All behavioral edge cases documented and verified
- No blockers or concerns

The branch is ready for review and merge to main.

---
*Phase: 06-detailed-api-review*
*Completed: 2026-03-13*
