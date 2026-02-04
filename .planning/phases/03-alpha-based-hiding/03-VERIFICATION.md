---
phase: 03-alpha-based-hiding
verified: 2026-02-04T15:49:04+02:00
status: passed
score: 5/5 must-haves verified
---

# Phase 3: Alpha-Based Hiding Verification Report

**Phase Goal:** Hide icons when their spell is off cooldown
**Verified:** 2026-02-04T15:49:04+02:00
**Status:** passed
**Re-verification:** No - initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Icon is invisible (alpha=0) when spell is off cooldown and feature enabled | VERIFIED | Line 55: `icon:SetAlpha(isOnCooldown and 1 or 0)` - when isOnCooldown is false (off cooldown), alpha is set to 0 |
| 2 | Icon is visible (alpha=1) when spell is on cooldown | VERIFIED | Line 55: `icon:SetAlpha(isOnCooldown and 1 or 0)` - when isOnCooldown is true, alpha is set to 1 |
| 3 | Feature only affects bars where HideWhenOffCooldown setting is enabled | VERIFIED | Lines 36, 42-43: Checks `BCDM:IsHideWhenOffCooldownEnabled(viewerName)`, restores alpha=1 if disabled |
| 4 | All icon elements (texture, cooldown spiral, text) hide together via parent alpha | VERIFIED | Lines 43, 50, 55, 126: All SetAlpha calls operate on `icon` (parent frame), not child elements |
| 5 | Charge spells remain visible while recharging | VERIFIED | Phase 2 API at Globals.lua:645: `return chargeInfo.currentCharges < chargeInfo.maxCharges` - returns true (visible) when any charge is recharging |

**Score:** 5/5 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `Modules/HideWhenOffCooldown.lua` | Icon visibility logic (min 60 lines) | VERIFIED | 162 lines, contains UpdateIconVisibility function, substantive implementation |
| `Modules/Init.xml` | Module load registration | VERIFIED | Line 6: `<Script file="HideWhenOffCooldown.lua"/>` |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| HideWhenOffCooldown.lua | BCDM:IsSpellOnCooldown | function call | WIRED | Line 53: `local isOnCooldown = BCDM:IsSpellOnCooldown(spellID)` |
| HideWhenOffCooldown.lua | BCDM:IsHideWhenOffCooldownEnabled | function call | WIRED | Line 36: `local featureEnabled = BCDM:IsHideWhenOffCooldownEnabled(viewerName)` |
| HideWhenOffCooldown.lua | viewer.RefreshLayout | hooksecurefunc | WIRED | Line 82: `hooksecurefunc(viewer, "RefreshLayout", function()` |
| CooldownManager.lua | BCDM:EnableHideWhenOffCooldown | initialization call | WIRED | Line 390: `BCDM:EnableHideWhenOffCooldown()` in SkinCooldownManager() |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| - | - | - | - | None found |

No stub patterns, TODOs, FIXMEs, or placeholder content detected in HideWhenOffCooldown.lua.

### Human Verification Required

#### 1. Visual Confirmation - Icon Hiding

**Test:** Enable HideWhenOffCooldown for Essential bar in settings, then observe icons when spells are off cooldown
**Expected:** Icons should disappear when their spell is ready to use
**Why human:** Visual appearance cannot be verified programmatically

#### 2. Visual Confirmation - Icon Showing

**Test:** Cast a spell with cooldown while HideWhenOffCooldown is enabled
**Expected:** Icon should appear when spell enters cooldown, disappear when cooldown ends
**Why human:** Real-time behavior requires live WoW client

#### 3. Charge Spell Behavior

**Test:** Use a charge spell (e.g., Fire Blast) and observe icon while charges are recharging
**Expected:** Icon should remain visible while any charge is recharging, hide only when all charges are full
**Why human:** Charge spell mechanics require live game testing

#### 4. Per-Bar Setting Isolation

**Test:** Enable HideWhenOffCooldown on Essential but not Utility bar
**Expected:** Essential icons hide when off cooldown, Utility icons remain always visible
**Why human:** Per-bar setting behavior requires UI interaction

---

## Verification Summary

All automated checks passed:

1. **Artifact Existence:** Both files exist (`HideWhenOffCooldown.lua`, `Init.xml` registration)

2. **Artifact Substantive:** HideWhenOffCooldown.lua has 162 lines (well above 60 minimum), no stub patterns

3. **Key Links Wired:**
   - Uses Phase 2 API: `BCDM:IsSpellOnCooldown(spellID)` at line 53
   - Uses Phase 1 API: `BCDM:IsHideWhenOffCooldownEnabled(viewerName)` at line 36
   - Hooks RefreshLayout: `hooksecurefunc(viewer, "RefreshLayout", ...)` at line 82
   - Initialization wired: `BCDM:EnableHideWhenOffCooldown()` at CooldownManager.lua line 390

4. **Logic Verification:**
   - Alpha toggling: `icon:SetAlpha(isOnCooldown and 1 or 0)` correctly hides (0) when off cooldown, shows (1) when on cooldown
   - Parent-level alpha: SetAlpha operates on icon frame, not individual child elements
   - Feature gating: Checks IsHideWhenOffCooldownEnabled before applying visibility logic
   - Fail-show: Invalid spellIDs result in alpha=1 (visible)

5. **Event Registration:**
   - SPELL_UPDATE_COOLDOWN (cooldown changes)
   - SPELL_UPDATE_CHARGES (charge spell changes)
   - PLAYER_ENTERING_WORLD (initial state)
   - PLAYER_SPECIALIZATION_CHANGED (spec changes may change spells)

Phase 3 goal achieved. Ready for Phase 4 (Layout Collapse).

---

*Verified: 2026-02-04T15:49:04+02:00*
*Verifier: Claude (gsd-verifier)*
