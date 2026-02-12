---
phase: 04-layout-collapse
plan: 01
subsystem: ui
tags: [wow-addon, lua, layout-reflow, icon-positioning, alpha-filtering]

# Dependency graph
requires:
  - phase: 01-settings-infrastructure
    provides: IsHideWhenOffCooldownEnabled API for feature toggle
  - phase: 03-alpha-based-hiding
    provides: SetAlpha(0) hiding mechanism and RefreshLayout hooks
provides:
  - Alpha-based filtering in CenterWrappedRows for layout collapse
  - Visible icons reflow to fill gaps left by hidden icons
  - Center-compacting behavior respecting multi-row wrapping
affects: [05-ui-configuration]

# Tech tracking
tech-stack:
  added: []
  patterns: [alpha-based-layout-filtering, feature-toggle-guards]

key-files:
  created: []
  modified: [Modules/CooldownManager.lua]

key-decisions:
  - "Guard alpha check with feature toggle to preserve existing behavior when disabled"
  - "Use GetAlpha() > 0 (not == 1) to handle potential intermediate alpha values"
  - "Maintain existing center-compacting math for icon positioning"

patterns-established:
  - "Alpha filtering pattern: Check collapseEnabled first, then GetAlpha() > 0"
  - "Feature toggle guard: not collapseEnabled or condition pattern"

# Metrics
duration: 42s
completed: 2026-02-12
---

# Phase 4 Plan 1: Layout Collapse Summary

**Alpha-filtered layout reflow causing visible icons to compact toward center and fill gaps left by hidden (alpha=0) icons**

## Performance

- **Duration:** 42 seconds
- **Started:** 2026-02-12T07:59:55Z
- **Completed:** 2026-02-12T08:00:38Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments
- Modified CenterWrappedRows to filter icons by alpha when HideWhenOffCooldown is enabled
- Integrated feature toggle check via BCDM:IsHideWhenOffCooldownEnabled
- Preserved existing center-compacting and multi-row wrapping behavior
- Maintained layoutIndex sort order for original position restoration

## Task Commits

Each task was committed atomically:

1. **Task 1: Add alpha filtering to CenterWrappedRows** - `57136de` (feat)

## Files Created/Modified
- `Modules/CooldownManager.lua` - Added collapseEnabled check and alpha filtering to icon collection loop (lines 227, 232-234)

## Decisions Made
- **Guard alpha check with feature toggle:** Only filter by alpha when HideWhenOffCooldown is enabled, preserving existing behavior when disabled
- **Use GetAlpha() > 0:** Instead of == 1 to handle potential intermediate alpha values from other systems
- **Maintain existing centering math:** No changes to startX = -rowWidth / 2 calculation - already achieves center-compacting requirement

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Layout collapse complete and functional
- Icons now reflow to fill gaps when HideWhenOffCooldown feature is enabled
- Ready for Phase 5 (UI Configuration) to add settings checkbox for user control
- All feature toggle infrastructure in place for GUI integration

## Self-Check: PASSED

---
*Phase: 04-layout-collapse*
*Completed: 2026-02-12*
