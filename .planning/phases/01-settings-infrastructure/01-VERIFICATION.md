---
phase: 01-settings-infrastructure
verified: 2026-02-04T12:00:00Z
status: passed
score: 4/4 must-haves verified
re_verification: false
---

# Phase 01: Settings Infrastructure Verification Report

**Phase Goal:** Add the per-bar setting to enable/disable hiding
**Verified:** 2026-02-04
**Status:** passed
**Re-verification:** No - initial verification

## Goal Achievement

### Observable Truths

| #   | Truth                                                        | Status     | Evidence                                                                      |
| --- | ------------------------------------------------------------ | ---------- | ----------------------------------------------------------------------------- |
| 1   | HideWhenOffCooldown setting persists across /reload          | VERIFIED   | Setting stored in AceDB profile path (self.db.profile.CooldownManager)        |
| 2   | Each bar type (Essential, Utility) has independent setting   | VERIFIED   | Separate entries in Defaults.lua lines 129 and 143                            |
| 3   | Setting defaults to false (feature disabled by default)      | VERIFIED   | Both locations show `HideWhenOffCooldown = false`                             |
| 4   | Getter/setter functions return correct values                | VERIFIED   | Functions in Globals.lua lines 594-613 use correct db path                    |

**Score:** 4/4 truths verified

### Required Artifacts

| Artifact           | Expected                                       | Status      | Details                                                |
| ------------------ | ---------------------------------------------- | ----------- | ------------------------------------------------------ |
| `Core/Defaults.lua` | HideWhenOffCooldown default for Essential/Utility | VERIFIED | Line 129 (Essential), Line 143 (Utility) both = false |
| `Core/Globals.lua`  | 3 API functions for setting access             | VERIFIED    | Lines 594-613: Get, Set, IsEnabled functions present   |

### Key Link Verification

| From             | To                                   | Via                    | Status   | Details                                           |
| ---------------- | ------------------------------------ | ---------------------- | -------- | ------------------------------------------------- |
| Core/Globals.lua | BCDM.db.profile.CooldownManager      | getter/setter functions | WIRED    | Lines 596, 602 access `self.db.profile.CooldownManager[barType]` |
| IsHideWhenOffCooldownEnabled | CooldownManagerViewerToDBViewer | mapping table lookup | WIRED    | Line 611 uses existing mapping table (lines 9-13) |

### Artifact Details

#### Core/Defaults.lua

**Level 1 - Existence:** EXISTS (516 lines)

**Level 2 - Substantive:**
- Essential section (line 129): `HideWhenOffCooldown = false,  -- Hide icons when spell is off cooldown`
- Utility section (line 143): `HideWhenOffCooldown = false,  -- Hide icons when spell is off cooldown`
- Both entries follow existing convention (after CenterHorizontally field)

**Level 3 - Wired:**
- Defaults.lua is loaded by AceDB via BCDM:GetDefaultDB() (line 513-515)
- Settings automatically persist via WoW SavedVariables

#### Core/Globals.lua

**Level 1 - Existence:** EXISTS (614 lines)

**Level 2 - Substantive:**
```lua
-- Lines 594-598
function BCDM:GetHideWhenOffCooldown(barType)
    if not barType then return false end
    local barSettings = self.db.profile.CooldownManager[barType]
    return barSettings and barSettings.HideWhenOffCooldown or false
end

-- Lines 600-607
function BCDM:SetHideWhenOffCooldown(barType, value)
    if not barType then return end
    local barSettings = self.db.profile.CooldownManager[barType]
    if barSettings then
        barSettings.HideWhenOffCooldown = value
    end
end

-- Lines 610-613
function BCDM:IsHideWhenOffCooldownEnabled(viewerFrameName)
    local barType = self.CooldownManagerViewerToDBViewer[viewerFrameName]
    return self:GetHideWhenOffCooldown(barType)
end
```

**Level 3 - Wired:**
- Functions are methods on BCDM table (addon namespace)
- IsHideWhenOffCooldownEnabled uses existing CooldownManagerViewerToDBViewer mapping (lines 9-13)
- Ready for use by Options.lua (Phase 01-02) and CooldownManager.lua (Phase 02)

### Requirements Coverage

| Requirement                              | Status    | Blocking Issue |
| ---------------------------------------- | --------- | -------------- |
| Per-bar setting for hide functionality   | SATISFIED | None           |
| Settings persist across sessions         | SATISFIED | None           |
| API for other modules to access setting  | SATISFIED | None           |

### Anti-Patterns Found

| File              | Line | Pattern | Severity | Impact |
| ----------------- | ---- | ------- | -------- | ------ |
| Core/Globals.lua  | 605  | "Future phases may add..." comment | Info | Documentation only, not blocking |

No blocking anti-patterns found. The TODO-style comment is informational and expected for phased development.

### Human Verification Required

#### 1. Addon Loads Without Errors
**Test:** Load WoW with BetterCooldownManager addon enabled, check for Lua errors
**Expected:** No errors on login, /bcdm command works
**Why human:** Requires actual WoW client execution

#### 2. Settings GUI Accessibility (Phase 01-02)
**Test:** This will be verified when GUI toggle is added in 01-02-PLAN
**Expected:** N/A for this phase
**Why human:** GUI not implemented in this phase

### Gaps Summary

No gaps found. All must-haves verified:

1. **Defaults.lua** contains HideWhenOffCooldown = false for both Essential (line 129) and Utility (line 143) bars
2. **Globals.lua** contains all three API functions (lines 594-613):
   - BCDM:GetHideWhenOffCooldown(barType)
   - BCDM:SetHideWhenOffCooldown(barType, value)
   - BCDM:IsHideWhenOffCooldownEnabled(viewerFrameName)
3. Functions use correct data path pattern: `self.db.profile.CooldownManager[barType]`
4. Helper function correctly uses existing CooldownManagerViewerToDBViewer mapping table

Phase goal "Add the per-bar setting to enable/disable hiding" is achieved. The settings infrastructure is ready for:
- Phase 01-02: Adding GUI toggle in Options.lua
- Phase 02: Implementing visibility logic in CooldownManager.lua

---

_Verified: 2026-02-04_
_Verifier: Claude (gsd-verifier)_
