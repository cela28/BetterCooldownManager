# Project State: Hide When Off Cooldown Feature

## Current Position

**Phase:** 5 of 5 (UI Configuration)
**Plan:** 1 of 1 in phase
**Status:** ALL PHASES COMPLETE
**Last activity:** 2026-02-12 - Completed 05-01-PLAN.md

**Progress:** [██████████] 100%
- Phase 1: Settings Infrastructure - COMPLETE
- Phase 2: Cooldown State Detection - COMPLETE
- Phase 3: Alpha-Based Hiding - COMPLETE
- Phase 4: Layout Collapse - COMPLETE
- Phase 5: UI Configuration - COMPLETE

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
| 04-01 | Guard alpha check with feature toggle | Preserve existing behavior when HideWhenOffCooldown is disabled |
| 04-01 | Use GetAlpha() > 0 (not == 1) | Handle potential intermediate alpha values from other systems |
| 04-01 | Maintain existing centering math | Center-compacting behavior already satisfies requirements |
| 05-01 | GameTooltip for hover tooltip | Standard pattern for feature descriptions, cleaner than SetDescription |
| 05-01 | Instant-apply via RefreshHideWhenOffCooldown | Matches addon's instant-apply UX pattern for all settings |
| 05-01 | Inline placement in toggleContainer | User-specified: no separator, header, or dedicated section |

## Blockers & Concerns

None identified.

## Session Continuity

**Last session:** 2026-02-12
**Stopped at:** Completed 05-01-PLAN.md - ALL PHASES COMPLETE
**Resume file:** None - Feature fully implemented and functional
