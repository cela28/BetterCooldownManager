# Project State: Hide When Off Cooldown Feature

## Current Position

**Phase:** 2 of 5 (Cooldown State Detection)
**Plan:** 1 of 1 in phase
**Status:** Phase complete
**Last activity:** 2026-02-04 - Completed 02-01-PLAN.md

**Progress:** [####------] 40%
- Phase 1: Settings Infrastructure - COMPLETE
- Phase 2: Cooldown State Detection - COMPLETE
- Phase 3: Alpha-Based Hiding - Not started
- Phase 4: Layout Collapse - Not started
- Phase 5: UI Configuration - Not started

## Accumulated Decisions

| Phase | Decision | Rationale |
|-------|----------|-----------|
| 01-01 | Defaults to `false` (disabled) | Backward compatible, opt-in feature |
| 01-01 | Essential and Utility bars only | Custom/Item/Trinket bars deferred to future phases |
| 01-01 | Placed after CenterHorizontally | Follows existing per-bar boolean convention |
| 02-01 | isOnGCD fallback: duration <= 1.5s | Treat short cooldowns as GCD when isOnGCD field is nil |
| 02-01 | Fail-show on all errors | Return false (don't hide) on invalid spellID, nil API, malformed data |

## Blockers & Concerns

None identified.

## Session Continuity

**Last session:** 2026-02-04
**Stopped at:** Completed 02-01-PLAN.md
**Resume file:** None - Phase 2 complete, ready for Phase 3
