# Audit Report: HideSpellOffCD Branch API Verification

**Date:** 2026-03-13
**Branch:** HideSpellOffCD
**Scope:** All WoW API calls, events, internal BCM functions, and integration points in branch changes
**Method:** Each item verified via Blizzard FrameXML GitHub (official API documentation) or codebase grep with file:line citations

---

## WoW API Calls

| # | API/Function | Source File:Line | Verification Source | Status |
|---|---|---|---|---|
| 1 | `C_Spell.GetSpellInfo(spellID)` | Globals.lua:686 | [Blizzard SpellDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/SpellDocumentation.lua) - `Name = "GetSpellInfo"`, returns `SpellInfo` | **PASS** |
| 2 | `C_Spell.GetSpellCharges(spellID)` | Globals.lua:691 | [Blizzard SpellDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/SpellDocumentation.lua) - `Name = "GetSpellCharges"`, returns `SpellChargeInfo`, MayReturnNothing=true | **PASS** |
| 3 | `C_Spell.GetSpellCooldown(spellID)` | Globals.lua:701 | [Blizzard SpellDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/SpellDocumentation.lua) - `Name = "GetSpellCooldown"`, returns `SpellCooldownInfo`, MayReturnNothing=true | **PASS** |

## Frame Methods

| # | API/Function | Source File:Line | Verification Method | Status |
|---|---|---|---|---|
| 4 | `viewer:GetChildren()` | HideWhenOffCooldown.lua:39,124 | Used 10+ times in existing BCM code (CooldownManager.lua:33,84,121,138,167,230,324; DisableAuraOverlay.lua:275). Standard Frame method per [Wowpedia API_Frame_GetChildren](https://warcraft.wiki.gg/wiki/API_Frame_GetChildren). | **PASS** |
| 5 | `icon:SetAlpha(alpha)` | HideWhenOffCooldown.lua:43,50,55,126 | Used extensively in BCM codebase. Standard Region method per [Wowpedia API_Region_SetAlpha](https://warcraft.wiki.gg/wiki/API_Region_SetAlpha). | **PASS** |
| 6 | `CreateFrame("Frame", name)` | HideWhenOffCooldown.lua:95 | Used in PowerBar.lua, CastBar.lua, DisableAuraOverlay.lua, etc. Standard global per [Wowpedia API_CreateFrame](https://warcraft.wiki.gg/wiki/API_CreateFrame). | **PASS** |
| 7 | `frame:SetScript("OnEvent", handler)` | HideWhenOffCooldown.lua:97 | Used in PowerBar.lua, DisableAuraOverlay.lua, SecondaryPowerBar.lua. Standard ScriptObject method per [Wowpedia API_ScriptObject_SetScript](https://warcraft.wiki.gg/wiki/API_ScriptObject_SetScript). | **PASS** |
| 8 | `frame:RegisterEvent(event)` | HideWhenOffCooldown.lua:106-109 | Used in PowerBar.lua, DisableAuraOverlay.lua, SecondaryPowerBar.lua. Standard Frame method per [Wowpedia API_Frame_RegisterEvent](https://warcraft.wiki.gg/wiki/API_Frame_RegisterEvent). | **PASS** |
| 9 | `frame:UnregisterAllEvents()` | HideWhenOffCooldown.lua:116 | Used in DisableAuraOverlay.lua. Standard Frame method per [Wowpedia API_Frame_UnregisterAllEvents](https://warcraft.wiki.gg/wiki/API_Frame_UnregisterAllEvents). | **PASS** |
| 10 | `hooksecurefunc(table, method, hook)` | HideWhenOffCooldown.lua:82 | Used in CooldownManager.lua:114,295,296. Standard global per [Wowpedia API_hooksecurefunc](https://warcraft.wiki.gg/wiki/API_hooksecurefunc). | **PASS** |

## GameTooltip Methods

| # | API/Function | Source File:Line | Verification Method | Status |
|---|---|---|---|---|
| 11 | `GameTooltip:SetOwner(owner, anchor)` | GUI.lua:1967 | Used 4+ times in existing GUI.lua (lines 582, 705, 712, 1571). Standard tooltip method per [Wowpedia API_GameTooltip_SetOwner](https://warcraft.wiki.gg/wiki/API_GameTooltip_SetOwner). | **PASS** |
| 12 | `GameTooltip:SetText(text, r, g, b, a, wrap)` | GUI.lua:1968 | Used in GUI.lua:583 with identical signature `(text, 1, 1, 1, 1, false)`. Standard tooltip method per [Wowpedia API_GameTooltip_SetText](https://warcraft.wiki.gg/wiki/API_GameTooltip_SetText). | **PASS** |
| 13 | `GameTooltip:Hide()` | GUI.lua:1971 | Used in GUI.lua:587,1572. Standard inherited Region method per [Wowpedia API_Region_Hide](https://warcraft.wiki.gg/wiki/API_Region_Hide). | **PASS** |

## WoW Events

| # | Event Name | Source File:Line | Verification Source | Status |
|---|---|---|---|---|
| 14 | `SPELL_UPDATE_COOLDOWN` | HideWhenOffCooldown.lua:106 | [Blizzard SpellBookDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/SpellBookDocumentation.lua) - `LiteralName = "SPELL_UPDATE_COOLDOWN"` | **PASS** |
| 15 | `SPELL_UPDATE_CHARGES` | HideWhenOffCooldown.lua:107 | [Blizzard SpellBookDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/SpellBookDocumentation.lua) - `LiteralName = "SPELL_UPDATE_CHARGES"` | **PASS** |
| 16 | `PLAYER_ENTERING_WORLD` | HideWhenOffCooldown.lua:108 | Used in existing BCM: PowerBar.lua (2x), DisableAuraOverlay.lua, SecondaryPowerBar.lua. Well-known system event. | **PASS** |
| 17 | `PLAYER_SPECIALIZATION_CHANGED` | HideWhenOffCooldown.lua:109 | Used in existing BCM: DisableAuraOverlay.lua, SecondaryPowerBar.lua (2x). Well-known system event. | **PASS** |

## Global References

| # | Reference | Source File:Line | Verification | Status |
|---|---|---|---|---|
| 18 | `_G[viewerName]` | HideWhenOffCooldown.lua:32,80,122 | Standard Lua global table. Used identically in CooldownManager.lua:84,121. | **PASS** |
| 19 | `ipairs()` | HideWhenOffCooldown.lua:39,66,79,124 | Standard Lua built-in function. | **PASS** |

---

## Return Value Structure Verification

### C_Spell.GetSpellCooldown -> SpellCooldownInfo

**Source:** [Blizzard SpellSharedDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/SpellSharedDocumentation.lua)

| Field We Access | Exists in SpellCooldownInfo? | Type | Notes |
|---|---|---|---|
| `.duration` | YES | `number` | "Cooldown duration in seconds if active; 0 if cooldown is inactive" |
| `.isOnGCD` | YES | `bool`, Nilable=true | "Whether or not this spell is considered to be on the global cooldown, do not trust this field unless responding to a SPELL_UPDATE_COOLDOWN event" |

**Status: PASS** - Both fields exist. Note: `isOnGCD` is Nilable (can be nil), which our code correctly handles with the `cdInfo.isOnGCD == nil` fallback at Globals.lua:714.

### C_Spell.GetSpellCharges -> SpellChargeInfo

**Source:** [Blizzard SpellSharedDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/SpellSharedDocumentation.lua)

| Field We Access | Exists in SpellChargeInfo? | Type | Notes |
|---|---|---|---|
| `.currentCharges` | YES | `number` | "Number of charges currently available" |
| `.maxCharges` | YES | `number` | "Max number of charges that can be accumulated" |

**Status: PASS** - Both fields exist and are non-nilable.

---

## Internal BCM Functions

| # | Function/Reference | Called From | Defined At | Status |
|---|---|---|---|---|
| 1 | `BCDM:IsHideWhenOffCooldownEnabled(viewerFrameName)` | HideWhenOffCooldown.lua:36 | Core/Globals.lua:660 | **PASS** |
| 2 | `BCDM:IsSpellOnCooldown(spellID)` | HideWhenOffCooldown.lua:53 | Core/Globals.lua:679 | **PASS** |
| 3 | `BCDM:GetHideWhenOffCooldown(barType)` | Core/Globals.lua:662 (called by IsHideWhenOffCooldownEnabled) | Core/Globals.lua:644 | **PASS** |
| 4 | `BCDM:SetHideWhenOffCooldown(barType, value)` | (public API, not directly called in our code) | Core/Globals.lua:650 | **PASS** |
| 5 | `BCDM:EnableHideWhenOffCooldown()` | (public API, called by CooldownManager initialization) | Modules/HideWhenOffCooldown.lua:138 | **PASS** |
| 6 | `BCDM:DisableHideWhenOffCooldown()` | (public API) | Modules/HideWhenOffCooldown.lua:150 | **PASS** |
| 7 | `BCDM:RefreshHideWhenOffCooldown()` | Core/GUI.lua:1964 | Modules/HideWhenOffCooldown.lua:158 | **PASS** |
| 8 | `BCDM.CooldownManagerViewerToDBViewer` | Core/Globals.lua:661 | Core/Globals.lua:9-13 | **PASS** |
| 9 | `BCDM.db.profile.CooldownManager[barType].HideWhenOffCooldown` | Core/GUI.lua:1961, Core/Globals.lua:646-647 | Core/Defaults.lua:129 (Essential), Core/Defaults.lua:143 (Utility) | **PASS** |

## Integration Points

| # | Integration Point | Description | Verified How | Status |
|---|---|---|---|---|
| 10 | `viewer.RefreshLayout` | hooksecurefunc hook target | Exists: CooldownManager.lua:114 hooks `CooldownViewerSettings.RefreshLayout`; lines 295-296 hook `EssentialCooldownViewer.RefreshLayout` and `UtilityCooldownViewer.RefreshLayout` | **PASS** |
| 11 | `frame.cooldownInfo` | Icon property for spell data | Used in DisableAuraOverlay.lua:58,87,181,247,276; CooldownManager.lua extensively. Property is set by Blizzard CooldownViewer frames. | **PASS** |
| 12 | `cooldownInfo.overrideSpellID` / `cooldownInfo.spellID` | Spell ID fields on cooldownInfo | DisableAuraOverlay.lua:61 uses identical pattern: `info.overrideSpellID or info.spellID` | **PASS** |
| 13 | `AG:Create("CheckBox")` | AceGUI checkbox widget pattern | Used 3+ times in existing GUI.lua: line 617 (specToggle), line 767 (scaleByIconSizeCheckbox). Established pattern. | **PASS** |
| 14 | Init.xml includes HideWhenOffCooldown.lua | Module registration | Modules/Init.xml:6 contains `<Script file="HideWhenOffCooldown.lua"/>`. File exists at Modules/HideWhenOffCooldown.lua (4945 bytes). | **PASS** |

---

## Summary

| Category | Checks | Passed | Failed |
|---|---|---|---|
| WoW API Calls (C_Spell) | 3 | 3 | 0 |
| Frame Methods | 7 | 7 | 0 |
| GameTooltip Methods | 3 | 3 | 0 |
| WoW Events | 4 | 4 | 0 |
| Global References | 2 | 2 | 0 |
| Return Value Structures | 4 fields | 4 | 0 |
| Internal BCM Functions | 9 | 9 | 0 |
| Integration Points | 5 | 5 | 0 |
| **Total** | **37** | **37** | **0** |

**Result: ALL CHECKS PASSED**

No failures or concerns identified. Every WoW API call, event, internal function reference, and integration point in the HideSpellOffCD branch changes has been verified as existing via direct observation of either:
- Blizzard's official FrameXML API documentation on GitHub (for C_Spell APIs, events, return value structures)
- Existing usage in the BCM codebase with file:line citations (for frame methods, internal functions, integration points)

### Notes

1. **isOnGCD nilability:** Our code correctly handles the fact that `SpellCooldownInfo.isOnGCD` is Nilable (Globals.lua:714 has an explicit `cdInfo.isOnGCD == nil` check with a duration-based GCD fallback).

2. **MayReturnNothing:** Both `C_Spell.GetSpellCooldown` and `C_Spell.GetSpellCharges` have `MayReturnNothing = true` in Blizzard docs. Our code correctly handles nil returns (Globals.lua:692 checks `if chargeInfo then`, line 702 checks `if not cdInfo then`).

3. **Pattern consistency:** The `GetSpellID` helper in HideWhenOffCooldown.lua:20-22 uses the exact same pattern as DisableAuraOverlay.lua:58-61, confirming it follows established BCM conventions.
