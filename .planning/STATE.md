# Project State: Hide When Off Cooldown Feature

## Current Position

**Phase:** 3 of 5 (Alpha-Based Hiding)
**Plan:** 1 of 1 in phase
**Status:** Phase complete
**Last activity:** 2026-02-04 - Completed 03-01-PLAN.md

**Progress:** [######----] 60%
- Phase 1: Settings Infrastructure - COMPLETE
- Phase 2: Cooldown State Detection - COMPLETE
- Phase 3: Alpha-Based Hiding - COMPLETE
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
| 03-01 | Parent alpha toggling | SetAlpha on icon frame hides all child elements together |
| 03-01 | Event-driven updates only | No OnUpdate polling - uses cooldown events + RefreshLayout hooks |
| 03-01 | Fail-show on visibility | Returns alpha=1 (visible) on any error condition |

## Blockers & Concerns

None identified.

## Session Continuity

**Last session:** 2026-02-04
**Stopped at:** Completed 03-01-PLAN.md
**Resume file:** None - Phase 3 complete, ready for Phase 4
