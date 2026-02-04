---
phase: 03-alpha-based-hiding
plan: 01
subsystem: ui
tags: [wow-addon, lua, alpha-visibility, cooldown-management, event-driven]

# Dependency graph
requires:
  - phase: 01-settings-infrastructure
    provides: HideWhenOffCooldown per-bar setting and BCDM:IsHideWhenOffCooldownEnabled API
  - phase: 02-cooldown-state-detection
    provides: BCDM:IsSpellOnCooldown API for cooldown detection
provides:
  - HideWhenOffCooldown.lua module with icon visibility toggling
  - Event-driven visibility updates via SPELL_UPDATE_COOLDOWN and SPELL_UPDATE_CHARGES
  - RefreshLayout hooks for layout-driven visibility updates
  - Public APIs EnableHideWhenOffCooldown, DisableHideWhenOffCooldown, RefreshHideWhenOffCooldown
affects: [04-layout-collapse, 05-ui-configuration]

# Tech tracking
tech-stack:
  added: []
  patterns: [event-driven-updates, hooksecurefunc, fail-show-philosophy]

key-files:
  created: [Modules/HideWhenOffCooldown.lua]
  modified: [Modules/Init.xml, Modules/CooldownManager.lua]

key-decisions:
  - "Parent alpha toggling hides all icon elements together"
  - "Event-driven updates (no OnUpdate polling) for performance"
  - "Fail-show on any error (invalid spellID, nil viewer, API error)"

patterns-established:
  - "Alpha-based visibility: Use frame:SetAlpha(0/1) for show/hide"
  - "Viewer iteration: for _, icon in ipairs({ viewer:GetChildren() }) do pattern"
  - "Dual-path updates: RefreshLayout hooks + cooldown events cover all state changes"

# Metrics
duration: 8min
completed: 2026-02-04
---

# Phase 3 Plan 1: Alpha-Based Icon Hiding Summary

**Alpha-based icon visibility module using SetAlpha to hide off-cooldown spells on Essential and Utility bars**

## Performance

- **Duration:** 8 min
- **Started:** 2026-02-04T
- **Completed:** 2026-02-04T
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- Created HideWhenOffCooldown.lua module (162 lines) implementing icon visibility logic
- Integrated with Phase 1 setting API (BCDM:IsHideWhenOffCooldownEnabled)
- Integrated with Phase 2 cooldown API (BCDM:IsSpellOnCooldown)
- Wired module initialization in SkinCooldownManager after RefreshLayout hooks

## Task Commits

Each task was committed atomically:

1. **Task 1: Create HideWhenOffCooldown module** - `190e614` (feat)
2. **Task 2: Register module and wire initialization** - `67d01ad` (feat)

## Files Created/Modified
- `Modules/HideWhenOffCooldown.lua` - Core visibility logic with event handling and RefreshLayout hooks
- `Modules/Init.xml` - Module registration (loads after DisableAuraOverlay.lua)
- `Modules/CooldownManager.lua` - Initialization call in SkinCooldownManager()

## Decisions Made
- **Parent alpha toggling:** Setting alpha on the icon frame hides all child elements (texture, cooldown spiral, text) together, avoiding per-element management
- **Event-driven only:** No OnUpdate polling - relies on SPELL_UPDATE_COOLDOWN, SPELL_UPDATE_CHARGES events plus RefreshLayout hooks
- **Fail-show philosophy:** Returns alpha=1 (visible) on any error condition - matches Phase 2 API design

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Alpha-based hiding complete and functional
- Ready for Phase 4 (Layout Collapse) to add icon repositioning when hidden
- RefreshHideWhenOffCooldown() API available for settings UI integration in Phase 5

---
*Phase: 03-alpha-based-hiding*
*Completed: 2026-02-04*
