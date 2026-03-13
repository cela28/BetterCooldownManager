---
phase: quick-2
plan: 01
type: execute
wave: 1
depends_on: []
files_modified: []
autonomous: true
requirements: [AUDIT-01]

must_haves:
  truths:
    - "Every WoW API call in our branch changes is verified against Wowpedia or FrameXML"
    - "Every internal BCM function reference is traced to its definition file:line"
    - "Every WoW event name is verified as a real event"
    - "A pass/fail checklist report exists as the SUMMARY"
  artifacts:
    - path: ".planning/quick/2-audit-codebase-to-verify-all-wow-api-cal/2-01-SUMMARY.md"
      provides: "Complete audit report with pass/fail checklist"
---

<objective>
Audit all WoW API calls, internal function references, and integration points in the HideSpellOffCD branch changes. Verify each one exists via Wowpedia, Blizzard FrameXML GitHub, or codebase grep. Produce a pass/fail checklist report.

Purpose: Ensure our code references only real, existing APIs and functions before merging.
Output: SUMMARY.md with complete audit checklist.
</objective>

<execution_context>
@/home/sntanavaras/.claude/get-shit-done/workflows/execute-plan.md
@/home/sntanavaras/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@.planning/quick/2-audit-codebase-to-verify-all-wow-api-cal/2-CONTEXT.md

Files to audit (READ ONLY — do NOT modify any source files):
@Modules/HideWhenOffCooldown.lua
@Core/Globals.lua (lines 641-724 — our additions)
@Core/Defaults.lua (lines 129, 143 — HideWhenOffCooldown entries)
@Core/GUI.lua (lines 1959-1973 — our checkbox addition)
@Modules/Init.xml (line 6 — our Script entry)
</context>

<tasks>

<task type="auto">
  <name>Task 1: Verify all WoW API calls and events against Wowpedia and FrameXML</name>
  <files>NONE — read-only audit, no files modified</files>
  <action>
READ-ONLY AUDIT. Do NOT modify any source files.

For each WoW API call and event below, fetch the Wowpedia page AND/OR check Blizzard FrameXML GitHub to verify it exists. Record the verification URL and PASS/FAIL.

**C_Spell namespace APIs (from Globals.lua lines 686-720):**
1. `C_Spell.GetSpellInfo(spellID)` — Fetch https://warcraft.wiki.gg/wiki/API_C_Spell.GetSpellInfo
2. `C_Spell.GetSpellCharges(spellID)` — Fetch https://warcraft.wiki.gg/wiki/API_C_Spell.GetSpellCharges
3. `C_Spell.GetSpellCooldown(spellID)` — Fetch https://warcraft.wiki.gg/wiki/API_C_Spell.GetSpellCooldown

For each, verify: (a) the function exists, (b) return value structure matches our usage (GetSpellCooldown returns table with .isOnGCD, .duration; GetSpellCharges returns table with .currentCharges, .maxCharges).

**Frame methods (from HideWhenOffCooldown.lua):**
4. `frame:GetChildren()` — Fetch https://warcraft.wiki.gg/wiki/API_Frame_GetChildren
5. `frame:SetAlpha(alpha)` — Fetch https://warcraft.wiki.gg/wiki/API_Region_SetAlpha
6. `CreateFrame("Frame", name)` — Fetch https://warcraft.wiki.gg/wiki/API_CreateFrame
7. `frame:SetScript("OnEvent", handler)` — Fetch https://warcraft.wiki.gg/wiki/API_ScriptObject_SetScript
8. `frame:RegisterEvent(event)` — Fetch https://warcraft.wiki.gg/wiki/API_Frame_RegisterEvent
9. `frame:UnregisterAllEvents()` — Fetch https://warcraft.wiki.gg/wiki/API_Frame_UnregisterAllEvents
10. `hooksecurefunc(table, method, hook)` — Fetch https://warcraft.wiki.gg/wiki/API_hooksecurefunc

**GameTooltip methods (from GUI.lua lines 1966-1971):**
11. `GameTooltip:SetOwner(owner, anchor)` — Fetch https://warcraft.wiki.gg/wiki/API_GameTooltip_SetOwner
12. `GameTooltip:SetText(text, r, g, b, a, wrap)` — Fetch https://warcraft.wiki.gg/wiki/API_GameTooltip_SetText
13. `GameTooltip:Hide()` — Fetch https://warcraft.wiki.gg/wiki/API_Region_Hide (inherited)

**WoW Events (from HideWhenOffCooldown.lua lines 106-109):**
14. `SPELL_UPDATE_COOLDOWN` — Fetch https://warcraft.wiki.gg/wiki/SPELL_UPDATE_COOLDOWN
15. `SPELL_UPDATE_CHARGES` — Fetch https://warcraft.wiki.gg/wiki/SPELL_UPDATE_CHARGES
16. `PLAYER_ENTERING_WORLD` — Fetch https://warcraft.wiki.gg/wiki/PLAYER_ENTERING_WORLD
17. `PLAYER_SPECIALIZATION_CHANGED` — Fetch https://warcraft.wiki.gg/wiki/PLAYER_SPECIALIZATION_CHANGED

**Global references:**
18. `_G[viewerName]` — Standard Lua global table, no verification needed (PASS by definition)
19. `ipairs()` — Standard Lua function (PASS by definition)

For any API where Wowpedia returns a redirect or 404, try the FrameXML GitHub as backup:
- https://github.com/Gethe/wow-ui-source (search for function name in Interface/AddOns/Blizzard_FrameXML or SharedXML)

Record each result in a structured table.
  </action>
  <verify>All 17 WoW API/event items have a verification URL and PASS/FAIL status recorded</verify>
  <done>Every WoW API call and event in our code is verified against an external source with direct citation</done>
</task>

<task type="auto">
  <name>Task 2: Verify all internal BCM function references and integration points</name>
  <files>NONE — read-only audit, no files modified</files>
  <action>
READ-ONLY AUDIT. Do NOT modify any source files.

For each internal BCM function reference and integration point, grep the codebase to find where it is defined. Record file:line and PASS/FAIL.

**Internal function calls made by our code:**
1. `BCDM:IsHideWhenOffCooldownEnabled(viewerFrameName)` — called in HideWhenOffCooldown.lua:36. Grep for `function BCDM:IsHideWhenOffCooldownEnabled` to find definition.
2. `BCDM:IsSpellOnCooldown(spellID)` — called in HideWhenOffCooldown.lua:53. Grep for `function BCDM:IsSpellOnCooldown` to find definition.
3. `BCDM:GetHideWhenOffCooldown(barType)` — called by IsHideWhenOffCooldownEnabled. Grep for `function BCDM:GetHideWhenOffCooldown` to find definition.
4. `BCDM:SetHideWhenOffCooldown(barType, value)` — defined but verify it exists. Grep for `function BCDM:SetHideWhenOffCooldown`.
5. `BCDM:EnableHideWhenOffCooldown()` — public API. Grep for `function BCDM:EnableHideWhenOffCooldown`.
6. `BCDM:DisableHideWhenOffCooldown()` — public API. Grep for `function BCDM:DisableHideWhenOffCooldown`.
7. `BCDM:RefreshHideWhenOffCooldown()` — called from GUI.lua:1964. Grep for `function BCDM:RefreshHideWhenOffCooldown`.
8. `BCDM.CooldownManagerViewerToDBViewer` — table used in IsHideWhenOffCooldownEnabled. Grep for `CooldownManagerViewerToDBViewer` to find definition.
9. `BCDM.db.profile.CooldownManager[barType].HideWhenOffCooldown` — data path. Verify Defaults.lua has this field under Essential and Utility.

**Integration points (existing BCM patterns our code hooks into):**
10. `viewer.RefreshLayout` — hooksecurefunc target. Grep the codebase for `function.*RefreshLayout` or `RefreshLayout =` to confirm this method exists on viewer frames.
11. `frame.cooldownInfo` — icon property accessed. Grep for `cooldownInfo` to confirm this is a real property set elsewhere.
12. `cooldownInfo.overrideSpellID` and `cooldownInfo.spellID` — fields accessed. Grep for `overrideSpellID` and `spellID` in context of cooldownInfo.

**AceGUI integration (from GUI.lua):**
13. `AG:Create("CheckBox")` — AceGUI widget. Grep for `AG:Create("CheckBox")` to confirm this pattern is used elsewhere in GUI.lua.

**Module registration (from Init.xml):**
14. Verify `Modules/Init.xml` includes `<Script file="HideWhenOffCooldown.lua"/>` and that the file path matches the actual file location.

Record each result in a structured table with: reference name, source file:line where called, definition file:line, PASS/FAIL.
  </action>
  <verify>All 14 internal references have been traced to their definitions with file:line citations</verify>
  <done>Every internal BCM function, data path, and integration point is verified as existing in the codebase</done>
</task>

<task type="auto">
  <name>Task 3: Compile pass/fail audit report as SUMMARY</name>
  <files>.planning/quick/2-audit-codebase-to-verify-all-wow-api-cal/2-01-SUMMARY.md</files>
  <action>
Compile results from Tasks 1 and 2 into a single SUMMARY report with these sections:

## Audit Report: HideSpellOffCD Branch API Verification

### WoW API Calls
| # | API/Function | Source File:Line | Verification Source | Status |
|---|---|---|---|---|
| 1 | C_Spell.GetSpellInfo | Globals.lua:686 | [Wowpedia URL] | PASS/FAIL |
| ... | ... | ... | ... | ... |

### WoW Events
| # | Event Name | Source File:Line | Verification Source | Status |
|---|---|---|---|---|
| 1 | SPELL_UPDATE_COOLDOWN | HideWhenOffCooldown.lua:106 | [Wowpedia URL] | PASS/FAIL |
| ... | ... | ... | ... | ... |

### Internal BCM Functions
| # | Function/Reference | Called From | Defined At | Status |
|---|---|---|---|---|
| 1 | BCDM:IsHideWhenOffCooldownEnabled | HideWhenOffCooldown.lua:36 | Globals.lua:660 | PASS/FAIL |
| ... | ... | ... | ... | ... |

### Integration Points
| # | Integration Point | Description | Verified How | Status |
|---|---|---|---|---|
| 1 | viewer.RefreshLayout | Hook target | grep shows method exists | PASS/FAIL |
| ... | ... | ... | ... | ... |

### Return Value Structure Verification
For C_Spell APIs, confirm the fields we access match documented return values:
- `C_Spell.GetSpellCooldown` → we access `.isOnGCD`, `.duration` — do these exist in docs?
- `C_Spell.GetSpellCharges` → we access `.currentCharges`, `.maxCharges` — do these exist in docs?

### Summary
- Total checks: N
- Passed: N
- Failed: N
- Notes on any failures or concerns

If ANY item is FAIL, clearly explain what is wrong and what the consequence would be at runtime.
  </action>
  <verify>SUMMARY file exists at .planning/quick/2-audit-codebase-to-verify-all-wow-api-cal/2-01-SUMMARY.md with all rows filled in</verify>
  <done>Complete pass/fail audit report with direct citations for every API call, event, internal function, and integration point</done>
</task>

</tasks>

<verification>
- SUMMARY.md exists and contains all audit tables
- Every WoW API has a Wowpedia or FrameXML citation URL
- Every internal function has a file:line definition reference
- Every row has an explicit PASS or FAIL status
- No source files were modified (read-only audit)
</verification>

<success_criteria>
- All WoW API calls verified against external documentation with URLs
- All internal BCM functions traced to definitions with file:line
- All WoW events verified as real events
- Return value structures confirmed to match our field access patterns
- Single clear pass/fail report produced
</success_criteria>

<output>
After completion, create `.planning/quick/2-audit-codebase-to-verify-all-wow-api-cal/2-01-SUMMARY.md`
</output>
