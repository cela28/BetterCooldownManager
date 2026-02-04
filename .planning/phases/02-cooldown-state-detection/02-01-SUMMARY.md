---
phase: 02-cooldown-state-detection
plan: 01
subsystem: api
tags: [wow-api, cooldown, spell-detection, c_spell]

# Dependency graph
requires:
  - phase: 01-settings-infrastructure
    provides: HideWhenOffCooldown per-bar setting API
provides:
  - BCDM:IsSpellOnCooldown(spellID) detection function
  - GCD filtering via isOnGCD field with 1.5s fallback
  - Charge spell detection via C_Spell.GetSpellCharges
affects: [03-alpha-based-hiding, hide-when-off-cooldown feature]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Charge spells checked before regular cooldown (GetSpellCharges priority)"
    - "GCD filtering with isOnGCD field + 1.5s fallback"
    - "Fail-show philosophy: return false on errors"

key-files:
  created: []
  modified:
    - Core/Globals.lua

key-decisions:
  - "isOnGCD fallback: treat duration <= 1.5s as GCD when isOnGCD field is nil"
  - "Fail-show on all errors: invalid spellID, nil API response, malformed charge info"

patterns-established:
  - "IsSpellOnCooldown: single-function detection API for cooldown state"
  - "Charge spell priority: always check GetSpellCharges before GetSpellCooldown"

# Metrics
duration: 1min
completed: 2026-02-04
---

# Phase 02 Plan 01: Cooldown State Detection Summary

**IsSpellOnCooldown function with GCD filtering, charge spell support, and fail-show error handling**

## Performance

- **Duration:** 1 min
- **Started:** 2026-02-04T10:04:13Z
- **Completed:** 2026-02-04T10:05:07Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments

- Added BCDM:IsSpellOnCooldown(spellID) function to Core/Globals.lua
- Charge spell detection: returns true if any charge recharging (currentCharges < maxCharges)
- GCD filtering: uses isOnGCD field with 1.5s fallback for nil case
- Fail-show philosophy: returns false on any error or invalid input

## Task Commits

Each task was committed atomically:

1. **Task 1: Implement IsSpellOnCooldown function** - `f1e710a` (feat)

## Files Created/Modified

- `Core/Globals.lua` - Added IsSpellOnCooldown detection function (lines 615-673)

## Decisions Made

- **isOnGCD fallback:** When isOnGCD field is nil, treat duration <= 1.5s as GCD-only (not real cooldown)
- **Fail-show philosophy:** Return false (don't hide icon) on any error case including invalid spellID, unknown spell, nil API response, or malformed charge info

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- IsSpellOnCooldown function ready for consumption by Phase 3 (Alpha-Based Hiding)
- Function handles all edge cases: GCD filtering, charge spells, invalid inputs
- Phase 3 can call BCDM:IsSpellOnCooldown(spellID) on each icon update

---
*Phase: 02-cooldown-state-detection*
*Completed: 2026-02-04*
