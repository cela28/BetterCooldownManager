# Phase 6: Detailed API Review - Context

**Gathered:** 2026-03-13
**Status:** Ready for planning

<domain>
## Phase Boundary

Exhaustive validation of all HideSpellOffCD branch code to ensure correct in-game behavior. Builds on QT-2's API signature verification (37/37 passed) with deeper behavioral analysis, scenario coverage, and API contract cross-referencing. Find and fix any issues discovered.

This is NOT a broader codebase cleanup — scope is limited to code we added/modified in the HideSpellOffCD branch.

</domain>

<decisions>
## Implementation Decisions

### Verification depth
- **Behavioral verification:** Trace every code path through our 4 files and verify each branch produces correct in-game behavior
- **Full scenario matrix:** Build a complete matrix of WoW scenarios (combat lockdown, loading screens, spec changes, charge spells, GCD edge cases, talent swaps, etc.) and verify our code handles each one
- **API contract deep-dive:** Cross-reference Blizzard FrameXML source for undocumented behaviors, timing constraints, return value quirks, and nilability guarantees that could affect our code

### Files in scope
- `Core/Globals.lua` — HideWhenOffCooldown setting API (lines 641-724) and IsSpellOnCooldown function
- `Modules/HideWhenOffCooldown.lua` — Core visibility module (entire file, our addition)
- `Core/GUI.lua` — Checkbox addition and RefreshHideWhenOffCooldown integration
- `Core/CooldownManager.lua` — Changes to CenterWrappedRows for alpha filtering and EnableHideWhenOffCooldown call

### Output approach
- Report + auto-fix: Find issues and commit fixes directly in the same phase
- Each fix should preserve the fail-show philosophy (errors → show icon, don't hide)

### Fix scope boundary
- Only fix code we added or modified in the HideSpellOffCD branch
- Do NOT touch pre-existing bugs in files we edited (e.g., existing CooldownManager.lua patterns)
- Do NOT refactor untouched code even if related

### Claude's Discretion
- Specific order of verification checks
- How to structure the scenario matrix document
- Whether to use pcall wrapping or inline nil checks for hardening

</decisions>

<specifics>
## Specific Ideas

- QT-2 audit (37/37 passed) is the baseline — this phase goes deeper into behavioral correctness
- CONCERNS.md flags several patterns (unprotected GetSpecializationInfo, unprotected Unpack, no WoW API error handling) — check if any of these patterns exist in OUR code specifically
- `isOnGCD` nilability handling (Globals.lua:714) was flagged as a notable design decision — verify the 1.5s fallback is correct against Blizzard's actual GCD durations
- `MayReturnNothing` on GetSpellCooldown and GetSpellCharges — verify our nil handling is complete

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- QT-2 audit report at `.planning/quick/2-audit-codebase-to-verify-all-wow-api-cal/2-SUMMARY.md` — contains all API signature verifications with Blizzard source links
- CONCERNS.md at `.planning/codebase/CONCERNS.md` — lists known patterns to check against

### Established Patterns
- Fail-show philosophy: errors → return false (don't hide) → icon stays visible
- Event-driven updates: SPELL_UPDATE_COOLDOWN, SPELL_UPDATE_CHARGES, PLAYER_ENTERING_WORLD, PLAYER_SPECIALIZATION_CHANGED
- hooksecurefunc on RefreshLayout for visibility updates after layout changes
- `cooldownInfo.overrideSpellID or cooldownInfo.spellID` pattern from DisableAuraOverlay.lua

### Integration Points
- `_G[viewerName]` global lookups for EssentialCooldownViewer and UtilityCooldownViewer
- `viewer:GetChildren()` iteration for icon access
- `icon.cooldownInfo` property set by Blizzard CooldownViewer frames
- `viewer.RefreshLayout` hook target

</code_context>

<deferred>
## Deferred Ideas

- Broader codebase API hardening (CONCERNS.md items outside our branch) — future phase or separate effort
- Integration test framework for WoW addon testing — out of scope

</deferred>

---

*Phase: 06-detailed-api-review*
*Context gathered: 2026-03-13*
