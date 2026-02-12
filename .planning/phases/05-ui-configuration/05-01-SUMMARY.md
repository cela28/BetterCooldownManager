---
phase: 05-ui-configuration
plan: 01
subsystem: ui
tags: [aceGUI, checkbox, wow-addon, settings-panel]

requires:
  - phase: 01-settings-infrastructure
    provides: HideWhenOffCooldown setting in Defaults.lua
  - phase: 03-alpha-based-hiding
    provides: RefreshHideWhenOffCooldown function
provides:
  - HideWhenOffCooldown checkbox in Essential/Utility settings panel
affects: []

tech-stack:
  added: []
  patterns: [AceGUI checkbox with GameTooltip]

key-files:
  created: []
  modified: [Core/GUI.lua]

key-decisions:
  - "Use GameTooltip via OnEnter/OnLeave callbacks for hover tooltip (not SetDescription)"
  - "Call RefreshHideWhenOffCooldown() for instant-apply behavior (not UpdateCooldownViewer)"
  - "Place checkbox inline within existing Essential/Utility Settings InlineGroup"

patterns-established:
  - "AceGUI checkbox with GameTooltip hover pattern for feature descriptions"

duration: <1min
completed: 2026-02-12
---

# Phase 5 Plan 1: UI Configuration Summary

**Checkbox control for hide-when-off-cooldown feature in Essential and Utility bar settings panels with instant-apply and hover tooltip**

## Performance

Execution completed in under 1 minute with a single clean commit. No deviations from plan required.

## Accomplishments

Added a "Hide When Off Cooldown" checkbox to the Essential and Utility bar settings panels (Core/GUI.lua). The checkbox:

- Appears only for Essential and Utility bar types (inside existing conditional block at line 1658)
- Is placed inline after the existing CenterHorizontally checkbox
- Reads from `BCDM.db.profile.CooldownManager[viewerType].HideWhenOffCooldown` setting (added in Phase 1)
- Updates the database and calls `BCDM:RefreshHideWhenOffCooldown()` on toggle (instant-apply)
- Shows a one-line tooltip on hover: "Hides spell icons that are not on cooldown"
- Uses GameTooltip with OnEnter/OnLeave callbacks (standard pattern from existing button tooltips)
- Uses `SetRelativeWidth(1)` for full-width checkbox layout

The implementation completes the hide-when-off-cooldown feature by exposing the existing backend functionality to users. All infrastructure from Phases 1-4 (settings, cooldown detection, alpha hiding, layout collapse) is now accessible via a simple checkbox toggle.

## Task Commits

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Add HideWhenOffCooldown checkbox to Essential/Utility settings panel | 95f926a | Core/GUI.lua |

## Files Created/Modified

**Modified:**
- Core/GUI.lua (lines 1687-1701): Added hideWhenOffCooldownCheckbox widget inside Essential/Utility Settings InlineGroup

**Created:**
- None

## Decisions Made

**1. Tooltip implementation via GameTooltip instead of SetDescription**
- **Rationale:** Research showed SetDescription is rarely used in BCDM (only 1 occurrence for multi-spec warnings) and consumes vertical space. GameTooltip via OnEnter/OnLeave callbacks is the standard pattern for feature descriptions (lines 1304-1305, 2093-2097).
- **Impact:** Cleaner UI layout, tooltip appears on-demand, matches existing addon patterns.

**2. Instant-apply via RefreshHideWhenOffCooldown() call**
- **Rationale:** All BCDM settings apply instantly (no "apply on close" pattern exists). RefreshHideWhenOffCooldown() is the correct refresh function (not UpdateCooldownViewer) per Phase 4 research pitfall #1.
- **Impact:** Icons hide/show immediately when checkbox is toggled, layout collapses instantly, consistent with addon's UX patterns.

**3. Placement inline within existing Essential/Utility Settings InlineGroup**
- **Rationale:** User locked decision specified "inline with existing options — no separator, header, or dedicated section". The conditional block at line 1658 already creates a toggleContainer InlineGroup specifically for Essential/Utility checkboxes.
- **Impact:** Visually grouped with CenterHorizontally checkbox, appears inside "Essential Settings" / "Utility Settings" box, no additional containers needed.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None. All infrastructure from previous phases (setting schema, getter functions, refresh API) worked as expected. The checkbox integrated seamlessly with existing AceGUI patterns.

## Next Phase Readiness

**Phase 5 Complete** - This was the final plan in the final phase.

All 5 phases of the hide-when-off-cooldown feature are now complete:
1. ✓ Settings Infrastructure (Phase 1)
2. ✓ Cooldown State Detection (Phase 2)
3. ✓ Alpha-Based Hiding (Phase 3)
4. ✓ Layout Collapse (Phase 4)
5. ✓ UI Configuration (Phase 5)

**Feature status: FULLY FUNCTIONAL**

Users can now:
- Open BetterCooldownManager settings
- Navigate to Essential or Utility bar settings
- Check the "Hide When Off Cooldown" checkbox
- See spell icons instantly hide when they come off cooldown
- See remaining icons collapse to fill gaps
- Hover the checkbox to see a tooltip describing the feature
- Uncheck to instantly restore all icons

**No blockers, concerns, or follow-up work required for this feature.**

Future enhancements (v2.0+) could include:
- Fade animation option (instead of instant hide)
- Per-spell exceptions (always show certain spells)
- Show on hover (reveal hidden spells when hovering bar)
- Support for Custom, Item, ItemSpell, and Trinket bar types

## Self-Check: PASSED

✓ All modified files verified:
- Core/GUI.lua exists and contains hideWhenOffCooldownCheckbox code

✓ All commits verified:
- 95f926a exists in git log
