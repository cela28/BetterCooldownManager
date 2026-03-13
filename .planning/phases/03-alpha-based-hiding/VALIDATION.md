---
phase: 03-alpha-based-hiding
generated: 2026-03-13
auditor: gsd-nyquist
status: green
checks_run: 18
checks_passed: 18
checks_failed: 0
---

# Phase 3: Alpha-Based Hiding — Validation Map

**Phase Goal:** Hide icons when their spell is off cooldown
**Validation Method:** grep/diff (no automated test framework; WoW Lua addon)
**Scope:** Checks the state of the codebase as delivered by phase 3.
**Note on DisableHideWhenOffCooldown:** The plan required this public API. It was present at phase 3 completion and later removed by phase 7 as dead code (never called). Checks below reflect phase 3 deliverables; phase 7's VALIDATION.md covers the removal.

---

## Check Map

| ID | Requirement | Command | Expected | Status |
|----|-------------|---------|----------|--------|
| 03-V-01 | HideWhenOffCooldown.lua file exists | `ls Modules/HideWhenOffCooldown.lua` | file listed | green |
| 03-V-02 | File is substantive (min 60 lines) | `wc -l Modules/HideWhenOffCooldown.lua` | >= 60 | green (160 lines) |
| 03-V-03 | UpdateIconVisibility function defined | `grep -n "function.*UpdateIconVisibility" Modules/HideWhenOffCooldown.lua` | match at line 31 | green |
| 03-V-04 | Icon hidden (alpha=0) when off cooldown | `grep -n "isOnCooldown and 1 or 0" Modules/HideWhenOffCooldown.lua` | match at line 55 | green |
| 03-V-05 | Feature check per-bar before toggling | `grep -n "IsHideWhenOffCooldownEnabled" Modules/HideWhenOffCooldown.lua` | match at line 36 | green |
| 03-V-06 | Phase 2 API used for cooldown detection | `grep -n "BCDM:IsSpellOnCooldown" Modules/HideWhenOffCooldown.lua` | match at line 53 | green |
| 03-V-07 | SetAlpha operates on parent icon frame | `grep -n "icon:SetAlpha" Modules/HideWhenOffCooldown.lua` | matches at lines 43, 50, 55, 131 | green |
| 03-V-08 | RefreshLayout hook wired via hooksecurefunc | `grep -n "hooksecurefunc.*RefreshLayout" Modules/HideWhenOffCooldown.lua` | match at line 82 | green |
| 03-V-09 | SPELL_UPDATE_COOLDOWN event registered | `grep -n "SPELL_UPDATE_COOLDOWN" Modules/HideWhenOffCooldown.lua` | match at line 111 | green |
| 03-V-10 | SPELL_UPDATE_CHARGES event registered | `grep -n "SPELL_UPDATE_CHARGES" Modules/HideWhenOffCooldown.lua` | match at line 112 | green |
| 03-V-11 | PLAYER_ENTERING_WORLD event registered | `grep -n "PLAYER_ENTERING_WORLD" Modules/HideWhenOffCooldown.lua` | match at line 113 | green |
| 03-V-12 | PLAYER_SPECIALIZATION_CHANGED event registered | `grep -n "PLAYER_SPECIALIZATION_CHANGED" Modules/HideWhenOffCooldown.lua` | match at line 114 | green |
| 03-V-13 | Fail-show: invalid spellID restores alpha=1 | `grep -n "not spellID or spellID == 0" Modules/HideWhenOffCooldown.lua` | match at line 49 | green |
| 03-V-14 | EssentialCooldownViewer in VIEWERS table | `grep -n "EssentialCooldownViewer" Modules/HideWhenOffCooldown.lua` | match at line 10 | green |
| 03-V-15 | UtilityCooldownViewer in VIEWERS table | `grep -n "UtilityCooldownViewer" Modules/HideWhenOffCooldown.lua` | match at line 11 | green |
| 03-V-16 | No OnUpdate polling (event-driven only) | `grep -c "OnUpdate" Modules/HideWhenOffCooldown.lua` | 0 | green |
| 03-V-17 | Module registered in Init.xml after DisableAuraOverlay | `grep -n "DisableAuraOverlay\|HideWhenOffCooldown" Modules/Init.xml` | DisableAuraOverlay at line 5, HideWhenOffCooldown at line 6 | green |
| 03-V-18 | Initialization wired in CooldownManager.lua | `grep -n "EnableHideWhenOffCooldown" Modules/CooldownManager.lua` | match at line 304 | green |

---

## Requirement Coverage

### Truth 1: Icon is invisible (alpha=0) when spell is off cooldown and feature enabled
- **Checks:** 03-V-04, 03-V-05, 03-V-06
- **Evidence:** `icon:SetAlpha(isOnCooldown and 1 or 0)` at line 55; when `isOnCooldown` is false, alpha is 0. Gated by `IsHideWhenOffCooldownEnabled` at line 36.

### Truth 2: Icon is visible (alpha=1) when spell is on cooldown
- **Checks:** 03-V-04
- **Evidence:** Same expression `isOnCooldown and 1 or 0` at line 55; when `isOnCooldown` is true, alpha is 1.

### Truth 3: Feature only affects bars where HideWhenOffCooldown setting is enabled
- **Checks:** 03-V-05
- **Evidence:** `BCDM:IsHideWhenOffCooldownEnabled(viewerName)` checked per-viewer at line 36; if false, `icon:SetAlpha(1)` restores visibility at line 43.

### Truth 4: All icon elements hide together via parent alpha
- **Checks:** 03-V-07
- **Evidence:** All `SetAlpha` calls target `icon` (the parent frame), not child elements. Lines 43, 50, 55, 131.

### Truth 5: Charge spells remain visible while recharging
- **Checks:** 03-V-10, 03-V-06
- **Evidence:** `SPELL_UPDATE_CHARGES` event at line 112 triggers `UpdateAllViewers()`; visibility is determined by `BCDM:IsSpellOnCooldown(spellID)` which (per Phase 2 API contract in Globals.lua:645) returns true when any charge is recharging.

### Artifact: Modules/HideWhenOffCooldown.lua
- **Checks:** 03-V-01, 03-V-02, 03-V-03
- **Evidence:** File exists, 160 lines (above 60 minimum), contains `UpdateIconVisibility` at line 31.

### Artifact: Modules/Init.xml registration
- **Checks:** 03-V-17
- **Evidence:** `<Script file="HideWhenOffCooldown.lua"/>` at line 6, immediately after DisableAuraOverlay.lua at line 5.

### Key Link: HideWhenOffCooldown.lua -> BCDM:IsSpellOnCooldown
- **Checks:** 03-V-06
- **Evidence:** Line 53.

### Key Link: HideWhenOffCooldown.lua -> BCDM:IsHideWhenOffCooldownEnabled
- **Checks:** 03-V-05
- **Evidence:** Line 36.

### Key Link: HideWhenOffCooldown.lua -> RefreshLayout via hooksecurefunc
- **Checks:** 03-V-08
- **Evidence:** Line 82.

### Key Link: CooldownManager.lua -> BCDM:EnableHideWhenOffCooldown
- **Checks:** 03-V-18
- **Evidence:** Line 304.

---

## Human-Only Checks (Not Automatable)

These require a live WoW client and cannot be verified by grep/diff:

| # | Test | Expected |
|---|------|----------|
| H-1 | Enable HideWhenOffCooldown on Essential bar; observe icons for off-cooldown spells | Icons are invisible |
| H-2 | Cast a spell with a cooldown while feature enabled; observe icon during and after cooldown | Icon appears when spell enters cooldown, disappears when cooldown expires |
| H-3 | Use a charge spell (e.g., Fire Blast); observe while charges recharge | Icon visible while any charge is recharging; hidden only when all charges are full |
| H-4 | Enable feature on Essential bar only, not Utility; observe both bars | Essential icons hide when off cooldown; Utility icons always visible |

---

## Anti-Pattern Checks

| Pattern | Command | Expected | Status |
|---------|---------|----------|--------|
| No OnUpdate polling | `grep -c "OnUpdate" Modules/HideWhenOffCooldown.lua` | 0 | green |
| No stub/TODO/FIXME | `grep -in "todo\|fixme\|stub\|placeholder" Modules/HideWhenOffCooldown.lua` | 0 matches | green |
| No SetAlpha on child elements (texture/cooldown text) | `grep -n "texture:SetAlpha\|text:SetAlpha\|cooldown:SetAlpha" Modules/HideWhenOffCooldown.lua` | 0 matches | green |

---

## Summary

All 18 automated checks passed. Phase 3 deliverables are present and correctly wired:

- `Modules/HideWhenOffCooldown.lua` — 160 lines, implements event-driven alpha toggling
- `Modules/Init.xml` — module loaded after DisableAuraOverlay.lua
- `Modules/CooldownManager.lua` — `EnableHideWhenOffCooldown()` called at line 304

Phase 3 goal achieved. 4 human-only checks remain for live WoW client validation.
