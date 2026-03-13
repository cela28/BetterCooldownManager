# Phase 7: Pre-Merge Cleanup - Context

**Gathered:** 2026-03-13
**Status:** Ready for planning

<domain>
## Phase Boundary

Remove dead code and dev-mode references from the HideSpellOffCD branch before merging to main. This phase does cleanup only — the actual merge to main is deferred until after in-game testing.

</domain>

<decisions>
## Implementation Decisions

### Dead code removal
- Remove `BCDM:SetHideWhenOffCooldown()` (Globals.lua:650) — never called, GUI writes to DB directly
- Remove `BCDM:DisableHideWhenOffCooldown()` (HideWhenOffCooldown.lua:155) — never called
- Straight deletion, no external addon compatibility concern

### Dev-mode conversion
- Use `toggle-dev.sh prod` to revert all `BetterCooldownManager_Dev` references back to `BetterCooldownManager`
- This handles: TOC rename, .pkgmeta, SavedVariables, asset paths, AceAddon/AceLocale/GetAddOnMetadata strings
- After conversion: keep `toggle-dev.sh` (useful for future dev), remove `BetterCooldownManager_Dev.toc`

### Merge strategy
- This phase does NOT merge to main — cleanup only
- Merge deferred until after in-game testing by the user
- Branch stays as HideSpellOffCD after cleanup

### Post-cleanup verification
- Diff branch against main (excluding .planning/ and .claude/ directories)
- Confirm only intentional feature additions remain
- No stray _Dev references, no dead code, no unintended changes

### Claude's Discretion
- Order of cleanup operations (dead code vs dev references first)
- Whether to combine cleanup into one commit or separate commits
- Handling any edge cases toggle-dev.sh might miss

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `toggle-dev.sh`: Handles full _Dev ↔ prod conversion (TOC, .pkgmeta, asset paths, addon name strings in all .lua files)

### Established Patterns
- GUI writes directly to DB (bypasses SetHideWhenOffCooldown) — confirmed by Phase 6 as the established BCM pattern
- Fail-show philosophy: errors → show icon, don't hide

### Integration Points
- Dead code locations: Globals.lua:650 (SetHideWhenOffCooldown), HideWhenOffCooldown.lua:155 (DisableHideWhenOffCooldown)
- _Dev references: Core.lua:2,6 / Globals.lua:26-30,35,267,278,289 / GUI.lua:5,1215-1247 / Locales/enUS.lua:1 / Locales/koKR.lua:1 / .pkgmeta:1

</code_context>

<specifics>
## Specific Ideas

- toggle-dev.sh prod is the proven tool for _Dev reversal — no need to reinvent
- Verification should focus on addon source files only (Core/, Modules/, Locales/, .toc, .pkgmeta) — planning dirs are branch-only artifacts

</specifics>

<deferred>
## Deferred Ideas

- Actual merge to main — after in-game testing
- In-game testing plan — user handles this outside GSD workflow

</deferred>

---

*Phase: 07-pre-merge-cleanup*
*Context gathered: 2026-03-13*
