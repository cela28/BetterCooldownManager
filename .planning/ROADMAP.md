# Hide When Off Cooldown - Development Roadmap

## Milestone 1: Core Feature (v1.0)

### Phase 1: Settings Infrastructure ✓
**Goal:** Add the per-bar setting to enable/disable hiding
**Status:** Complete (2026-02-04)
**Plans:** 1/1 complete

Plans:
- [x] 01-01-PLAN.md - Add HideWhenOffCooldown setting to Defaults.lua and getter/setter functions to Globals.lua

### Phase 2: Cooldown State Detection ✓
**Goal:** Reliably detect when a spell is on/off cooldown
**Status:** Complete (2026-02-04)
**Plans:** 1/1 complete

Plans:
- [x] 02-01-PLAN.md - Create IsSpellOnCooldown function with GCD filtering and charge spell handling

### Phase 3: Alpha-Based Hiding
**Goal:** Hide icons when their spell is off cooldown

Tasks:
- Hook into icon update cycle
- Check bar's `hideWhenOffCooldown` setting
- Set icon alpha to 0 when spell off cooldown
- Set icon alpha to normal when spell on cooldown

### Phase 4: Layout Collapse
**Goal:** Make remaining icons shift to fill gaps

Tasks:
- Modify layout calculation to skip alpha=0 icons
- Ensure smooth repositioning when icons hide/show
- Test with various bar configurations

### Phase 5: UI Configuration
**Goal:** Let users toggle the feature per-bar

Tasks:
- Add checkbox to bar settings panel
- Wire checkbox to the setting
- Add tooltip explaining the feature

---

## Future Considerations (v2.0+)

- Fade animation option (instead of instant hide)
- Per-spell exceptions (always show certain spells)
- Show on hover (reveal hidden spells when hovering bar)
- API hooking approach for true removal (if alpha approach has issues)
