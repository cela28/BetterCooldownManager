---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
status: completed
stopped_at: Completed 07-01-PLAN.md
last_updated: "2026-03-13T14:40:19.650Z"
last_activity: "2026-03-13 - Phase 6 added: Detailed API review"
progress:
  total_phases: 7
  completed_phases: 7
  total_plans: 8
  completed_plans: 8
  percent: 100
---

# Project State: Hide When Off Cooldown Feature

## Current Position

**Phase:** 6 of 6 (Detailed API review)
**Plan:** 0 of 0 in phase
**Status:** Milestone complete
**Last activity:** 2026-03-13 - Phase 6 added: Detailed API review

**Progress:** [██████████] 100%
- Phase 1: Settings Infrastructure - COMPLETE
- Phase 2: Cooldown State Detection - COMPLETE
- Phase 3: Alpha-Based Hiding - COMPLETE
- Phase 4: Layout Collapse - COMPLETE
- Phase 5: UI Configuration - COMPLETE
- Phase 6: Detailed API review - NOT STARTED

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
- [Phase 06]: Pitfall 5 (Secret Values) requires FIX-01 code change for Midnight forward-compatibility
- [Phase 06]: No current-live bugs in HideSpellOffCD branch; 1 Midnight guard + 3 comment improvements needed
- [Phase 06-02]: IsSecretValue guard placed before first arithmetic on cdInfo.duration — fail-show on unreadable Midnight Secret Value durations
- [Phase 06-02]: All FINDINGS fixes applied: FIX-01 code change + FIX-02/03/04 documentation comments only
- [Phase 07-01]: toggle-dev.sh retained as untracked file; Category-enUS field left matching main

## Blockers & Concerns

None identified.

### Roadmap Evolution
- Phase 6 added: Detailed API review

## Quick Tasks

| Task | Description | Status | Date |
|------|-------------|--------|------|
| QT-1 | Rebase HideSpellOffCD onto origin/main | COMPLETE | 2026-03-13 |
| QT-2 | Audit all WoW API calls and internal references | COMPLETE | 2026-03-13 |
| QT-3 | Generate API compatibility report (TWW + Midnight) | COMPLETE | 2026-03-13 |

## Session Continuity

**Last session:** 2026-03-13T15:07:09Z
**Stopped at:** Completed QT-3 (API compatibility report)
**Resume file:** None
