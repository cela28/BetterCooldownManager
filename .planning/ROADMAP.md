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

### Phase 3: Alpha-Based Hiding ✓
**Goal:** Hide icons when their spell is off cooldown
**Status:** Complete (2026-02-04)
**Plans:** 1/1 complete

Plans:
- [x] 03-01-PLAN.md - Create HideWhenOffCooldown module with RefreshLayout hooks and event-driven visibility

### Phase 4: Layout Collapse ✓
**Goal:** Make visible icons shift to fill gaps left by hidden (alpha=0) icons
**Status:** Complete (2026-02-12)
**Plans:** 1/1 complete

Plans:
- [x] 04-01-PLAN.md - Add alpha filtering to CenterWrappedRows for layout collapse

### Phase 5: UI Configuration
**Goal:** Let users toggle the feature per-bar via checkbox in settings panel
**Plans:** 1 plan

Plans:
- [ ] 05-01-PLAN.md - Add HideWhenOffCooldown checkbox to Essential/Utility settings panel with instant-apply and tooltip

---

## Future Considerations (v2.0+)

- Fade animation option (instead of instant hide)
- Per-spell exceptions (always show certain spells)
- Show on hover (reveal hidden spells when hovering bar)
- API hooking approach for true removal (if alpha approach has issues)
