# Codebase Concerns

**Analysis Date:** 2026-02-04

## Tech Debt

**Unprotected GetSpecializationInfo Chain:**
- Issue: Multiple calls to `select(2, GetSpecializationInfo(GetSpecialization()))` followed by `:gsub()` can crash if GetSpecialization() returns nil or GetSpecializationInfo returns nil
- Files: `Core/Globals.lua` (lines 347, 408), `Core/GUI.lua` (line 1057), `Modules/CustomCooldownViewer.lua` (line 128), `Modules/AdditionalCustomCooldownViewer.lua` (line 131), `Modules/Data.lua` (lines 296, 334)
- Impact: Crash with error "attempt to index a nil value" during specialization detection on startup or specialization changes
- Fix approach: Add nil checks before calling `:gsub()` on the result. Use pattern: `local specName = GetSpecializationInfo(GetSpecialization()); if specName then specName:gsub(...) end`

**Unprotected Unpack Operations:**
- Issue: Multiple `unpack()` calls on database tables without verifying table existence (e.g., `unpack(CooldownTextDB.Colour)`)
- Files: `Core/GUI.lua` (lines 253, 358, 412, 476, 547, 630, 649, 667, 686, 855, 1044), `Modules/CustomCooldownViewer.lua` (line 29), `Modules/SecondaryPowerBar.lua` (line 352)
- Impact: Crash if database table structure changes or migration fails, or if nested paths return nil
- Fix approach: Verify tables exist before unpacking: `if CooldownTextDB.Colour then local r,g,b = unpack(CooldownTextDB.Colour) ...`

**Direct Nested Table Access Without Nil Checks:**
- Issue: Code accesses deeply nested database paths like `BCDM.db.profile.General.Colours.SecondaryPower[powerType]` without checking intermediate values
- Files: `Modules/SecondaryPowerBar.lua` (lines 74, 87, 389, 457), `Core/GUI.lua` (lines 627, 646, 664, 683)
- Impact: Crash if profile data is corrupted, partially loaded, or migrated incompletely
- Fix approach: Add existence checks at each level: `if BCDM.db and BCDM.db.profile and BCDM.db.profile.General and BCDM.db.profile.General.Colours ...`

**No Error Handling for WoW API Calls:**
- Issue: Calls to `C_Spell.GetSpellInfo()`, `C_Item.GetItemInfo()`, `C_SpellBook.IsSpellInSpellBook()` assume valid returns without validation
- Files: `Modules/CustomCooldownViewer.lua` (line 121: `C_Spell.GetSpellInfo(spellId).iconID`), `Core/GUI.lua` (lines 135-136, 143-145), `Modules/CooldownManager.lua` (line 19)
- Impact: Crash with "attempt to index a nil value" if spell/item IDs are invalid or removed from game
- Fix approach: Check return values: `local spellInfo = C_Spell.GetSpellInfo(spellId); if spellInfo then ... end`

## Known Bugs

**Specialization Detection on Login:**
- Symptoms: Possible nil error on first login if GetSpecialization() returns nil before specialization data is available
- Files: `Core/Globals.lua` (line 347), `Modules/CustomCooldownViewer.lua` (line 128)
- Trigger: Login before specialization data fully loads from server
- Workaround: None. Addon will error if timing is poor

**Missing Database Migration on Version Upgrades:**
- Symptoms: Old profile structures not upgraded when addon updates
- Files: `Core/Core.lua` (lines 7-11: basic profile migration only for missing top-level keys)
- Impact: New features may reference database paths that don't exist in old profiles
- Risk: Silent failures or crashes when accessing newly added config sections

## Security Considerations

**Import String Validation:**
- Risk: `API.lua` line 20-22 decodes and deserializes user-provided strings with minimal validation
- Files: `Core/API.lua` (lines 19-32)
- Current mitigation: Basic check for "!BCDM_" prefix, but no size limit or deep validation of deserialized data
- Recommendations: Add maximum string length validation, validate table structure after deserialization before assigning to profiles

**SavedVariables in BCDMDB:**
- Risk: Player-facing settings exposed in unencrypted SavedVariables file
- Impact: Not a security issue for this addon type, but users should know saved data is plaintext
- Current mitigation: Standard WoW addon storage

## Performance Bottlenecks

**Large GUI.lua File:**
- Problem: `Core/GUI.lua` is 2870 lines, making it difficult to navigate and maintain
- Files: `Core/GUI.lua`
- Cause: All GUI creation and management in single file
- Improvement path: Split into separate files for different sections (PowerBar, CooldownText, ProfileManagement, etc.)

**Repeated Specialization Detection:**
- Problem: Specialization detection logic duplicated across multiple files (Globals, CustomCooldownViewer, Data, AdditionalCustomCooldownViewer)
- Files: `Core/Globals.lua` (lines 346-352, 407-413), `Modules/CustomCooldownViewer.lua` (lines 127-128), `Modules/AdditionalCustomCooldownViewer.lua` (lines 130-131), `Modules/Data.lua` (lines 295-296, 333-334)
- Impact: Code duplication, maintenance burden, risk of inconsistency
- Improvement path: Extract into single `GetPlayerSpecializationName()` function in Globals, reuse everywhere

**Commented-Out Code in CooldownManager.lua:**
- Problem: Lines 27-150 contain extensive commented-out BuffBar styling code
- Files: `Modules/CooldownManager.lua` (lines 27-150)
- Cause: Dead code not removed during feature deprecation
- Improvement path: Delete commented code if BuffBar is truly deprecated, or restore if planned

## Fragile Areas

**Event Handler in CustomCooldownViewer:**
- Files: `Modules/CustomCooldownViewer.lua` (lines 102-113)
- Why fragile: Assumes `C_Spell.GetSpellCharges()` and `C_Spell.GetSpellCooldown()` always return valid data. If either API changes or returns unexpected structure, SetCooldown() could receive invalid parameters
- Safe modification: Verify return values before passing to SetCooldown(): `if spellCharges then ... end` and `if cooldownData and cooldownData.startTime then ...`
- Test coverage: No unit tests visible; no event handler testing for edge cases

**Database Profile Migration (Core.lua):**
- Files: `Core/Core.lua` (lines 7-11)
- Why fragile: Only checks if `BCDM.db.profile[k] == nil` and copies from defaults. If structure changed (keys removed/renamed), old data remains orphaned and new keys won't be initialized
- Safe modification: Implement deep merge with version tracking in defaults, migrate entire structures
- Test coverage: No migration tests; likely breaks on cross-version updates

**Power Type Lookups in SecondaryPowerBar:**
- Files: `Modules/SecondaryPowerBar.lua` (lines 63-104, 349-389)
- Why fragile: Uses raw Enum values as table keys without validation. If Enum structure changes in future WoW patch, lookups fail silently
- Safe modification: Add fallback colors, validate enum values exist before indexing
- Test coverage: None; changes to WoW Enum values could silently break without error

**Import/Export Serialization (API.lua):**
- Files: `Core/API.lua` (lines 19-32)
- Why fragile: Deserialized tables directly assigned to `BCDM.db.profiles[profileKey]`. No validation that imported data has required structure before use
- Safe modification: Validate imported profile structure matches defaults, merge instead of replace
- Test coverage: No round-trip import/export tests

## Scaling Limits

**Profile Count Scalability:**
- Current capacity: No explicit limit on profile count
- Limit: SavedVariables file size grows linearly with profiles. Each large profile (with full customization) ~5-10KB
- Scaling path: Implement profile size limits UI warning, add compression for exported strings

**Custom Spell/Item Bar Items:**
- Current capacity: No explicit limit on custom items added
- Limit: Frame creation for each item (CustomCooldownViewer, CustomItemViewer, etc.) creates unmanaged frame objects
- Scaling path: Implement pooling or lazy loading for icons beyond reasonable count (e.g., >100)

## Dependencies at Risk

**LibEditModeOverride-1.0 (LEMO):**
- Risk: Custom library with single developer. Edit Mode is intrinsically fragile as it depends on Blizzard internals
- Impact: Any WoW UI changes could break LEMO and this addon's edit mode
- Current mitigation: LEMO:ApplyChanges() wrapped in OnEvent
- Migration plan: Have fallback for when edit mode unavailable, reduce reliance on LEMO

**AceGUI-3.0 and Ace3 Libraries:**
- Risk: Third-party libraries might lag behind WoW patches
- Current mitigation: Code includes fallbacks for missing Enum.StatusBarInterpolation (line 13-16 of SecondaryPowerBar.lua)
- Migration plan: Monitor Ace3 updates, have UI graceful degradation if widgets fail

## Missing Critical Features

**No Addon Communication Protocol:**
- Problem: Other addons can't query state or request actions programmatically
- Blocks: Cross-addon integration (ElvUI skins, Masque themes, etc.) must hardcode UI manipulation
- Files: `Core/API.lua` only exports profile import/export, no event system
- Recommendation: Add `BCDM_EVENT` custom event system for state changes

**No Logging/Debugging Framework:**
- Problem: Errors use `BCDM:PrettyPrint()` only; no structured logging
- Impact: Users cannot diagnose issues, developers can't trace state
- Files: All modules
- Recommendation: Implement log level system, write to SavedVariables for debugging

## Test Coverage Gaps

**Specialization Detection Functions:**
- What's not tested: Edge cases where GetSpecialization() returns nil, invalid spec IDs, race-condition between GetSpecialization() and GetSpecializationInfo()
- Files: `Core/Globals.lua` (DetectSecondaryPower not shown but related logic), `Modules/SecondaryPowerBar.lua` (lines 20-52)
- Risk: Silent spec detection failures that go unnoticed until player switches specs
- Priority: High - affects core feature visibility

**Database Migration and Profile Loading:**
- What's not tested: Old profile import, missing keys in profiles, corrupted profile data
- Files: `Core/Core.lua` (OnInitialize), `Core/API.lua` (ImportBCDM)
- Risk: Crashes on profile switches, lost settings on addon updates
- Priority: High - data integrity

**Event Handler Robustness:**
- What's not tested: Rapid spec changes, frame destruction during event, in-combat changes
- Files: `Core/EventManager.lua` (SetupEventManager), `Modules/CustomCooldownViewer.lua` (OnEvent)
- Risk: Event handlers could crash if called during frame cleanup or invalid game states
- Priority: Medium - reliability

**Import/Export Round-Trip:**
- What's not tested: Export → import → export produces identical string, profile functionality unchanged
- Files: `Core/API.lua` (ExportBCDM, ImportBCDM)
- Risk: Data corruption on profile sharing between players
- Priority: Medium - user-facing feature

---

*Concerns audit: 2026-02-04*
