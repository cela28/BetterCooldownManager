# Phase 01 Plan 01: Settings Infrastructure Summary

**One-liner:** Added HideWhenOffCooldown per-bar boolean setting to Essential/Utility bars with getter/setter API functions.

## What Was Built

Added the foundational setting infrastructure for the "hide spells when off cooldown" feature:

1. **Default Values in Defaults.lua**
   - Added `HideWhenOffCooldown = false` to Essential bar settings (line 129)
   - Added `HideWhenOffCooldown = false` to Utility bar settings (line 143)
   - Setting defaults to `false` (feature disabled by default, backward compatible)

2. **API Functions in Globals.lua**
   - `BCDM:GetHideWhenOffCooldown(barType)` - Returns boolean setting value for a bar type
   - `BCDM:SetHideWhenOffCooldown(barType, value)` - Stores boolean setting value
   - `BCDM:IsHideWhenOffCooldownEnabled(viewerFrameName)` - Helper that accepts viewer frame name (e.g., "EssentialCooldownViewer") and returns setting via CooldownManagerViewerToDBViewer lookup

## Technical Details

### Data Flow
```
User toggles setting in GUI (future phase)
    -> BCDM:SetHideWhenOffCooldown("Essential", true)
    -> BCDM.db.profile.CooldownManager.Essential.HideWhenOffCooldown = true
    -> AceDB handles SavedVariables persistence automatically
    -> Setting persists across /reload and relog
```

### Key Implementation Decisions

1. **Placement after CenterHorizontally**: Follows existing convention for per-bar boolean settings
2. **Defensive defaults**: Functions return `false` if barType is nil or setting doesn't exist
3. **Uses existing mapping table**: `IsHideWhenOffCooldownEnabled` leverages `CooldownManagerViewerToDBViewer` defined at line 9-13

## Files Modified

| File | Changes |
|------|---------|
| Core/Defaults.lua | +2 lines (HideWhenOffCooldown in Essential and Utility sections) |
| Core/Globals.lua | +24 lines (3 API functions with comments) |

## Commits

| Hash | Message |
|------|---------|
| 7ab11f3 | feat(01-01): add HideWhenOffCooldown to Defaults.lua |
| 468e826 | feat(01-01): add HideWhenOffCooldown API functions |

## Deviations from Plan

None - plan executed exactly as written.

## Success Criteria Verification

- [x] HideWhenOffCooldown = false exists in Essential section of Defaults.lua
- [x] HideWhenOffCooldown = false exists in Utility section of Defaults.lua
- [x] BCDM:GetHideWhenOffCooldown(barType) function exists in Globals.lua
- [x] BCDM:SetHideWhenOffCooldown(barType, value) function exists in Globals.lua
- [x] BCDM:IsHideWhenOffCooldownEnabled(viewerFrameName) function exists in Globals.lua
- [x] All grep verification commands pass (2 occurrences in Defaults.lua, 3 functions in Globals.lua)

## Next Phase Readiness

This plan provides the data storage layer. Future phases can now:
- **Phase 01-02**: Add GUI toggle in Options.lua using these getter/setter functions
- **Phase 02**: Implement visibility logic in CooldownManager.lua using `IsHideWhenOffCooldownEnabled`

No blockers or concerns identified.
