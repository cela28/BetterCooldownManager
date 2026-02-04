# Coding Conventions

**Analysis Date:** 2026-02-04

## Naming Patterns

**Files:**
- PascalCase for module files: `Core.lua`, `Globals.lua`, `EventManager.lua`, `PowerBar.lua`
- Consistent naming: module names reflect their purpose (e.g., `CooldownManager.lua`, `CustomGlows.lua`)

**Functions:**
- **Namespace functions (public):** Methods attached to main objects use colon notation: `function BCDM:UpdateBCDM()`, `function BCDM:AddBorder(parentFrame)`
- **API functions (public):** Global API exposed via namespace: `function BCDMG:ExportBCDM()`, `function BCDMG:ImportBCDM()`
- **Local functions (private):** Standard local keyword: `local function ShouldSkin()`, `local function FetchCooldownTextRegion(cooldown)`
- **Variable-assigned functions:** Used for callbacks and event handlers: `local function SetupSlashCommands()`, `updatePowerBarHeightEventFrame:SetScript("OnEvent", function(self, event, ...) ... end)`

**Variables:**
- **Database references:** Abbreviated but descriptive: `GeneralDB = BCDM.db.profile.General`, `CooldownManagerDB = BCDM.db.profile`
- **Frame/UI references:** PascalCase for major objects: `PowerBar`, `Viewer`, `HighLevelContainer`
- **Cached/extracted values:** Descriptive local variables: `powerCurrent`, `powerMax`, `playerClass`, `playerSpecialization`
- **Constants and lookups:** SCREAMING_SNAKE_CASE for globals, CamelCase for local constants: `BCDM.ADDON_NAME`, `BCDM.IS_DEATHKNIGHT`, `OVERLAY_COLOUR`
- **Boolean flags:** Clear naming: `isGUIOpen`, `isUnitDeathKnight`, `isUnitMonk`, `hasSecondary`, `shouldShow`

**Types:**
- No explicit type system (Lua). Types inferred from usage context.
- Table-based objects: `BCDM` namespace, `BCDMG` global API, `BCDMGUI` GUI module
- Event frame objects created with `CreateFrame()` and assigned to variables

## Code Style

**Formatting:**
- **Indentation:** 4 spaces (consistent throughout)
- **Line length:** No strict limit observed, some lines exceed 120 characters
- **Whitespace:**
  - Single space around operators: `local x = y + z`
  - No space before parentheses in function calls: `CreateFrame("Frame", ...)`
  - Space after `if`, `for`, `while`: `if not parentFrame then return end`
- **Brackets:** Opening brace on same line: `function Name() ... end`

**Linting:**
- No `.eslintrc` or automated linter detected
- Manual style maintained through conventions

## Import Organization

**Order:**
1. Local namespace extraction: `local _, BCDM = ...`
2. Library references: `local LEMO = BCDM.LEMO`, `local LSM = BCDM.LSM`
3. Serialization/compression: `local Serialize = LibStub:GetLibrary("AceSerializer-3.0")`
4. Local constants/tables: `local AnchorPoints = { ... }`, `local PowerNames = { ... }`
5. Local function definitions: `local function FetchPowerBarColour() ... `
6. Exported function definitions: `function BCDM:Method() ... `

**Ace Framework Integration:**
- Uses Ace3 libraries extensively: AceAddon, AceDB, AceGUI, AceSerializer
- LibStub for library loading: `LibStub("AceAddon-3.0")`, `LibStub("LibSharedMedia-3.0")`
- Custom libraries: LibDualSpec, LibCustomGlow, LibEditModeOverride

**Global Access:**
- `_G[frameName]` used to access frames by string name: `_G["EssentialCooldownViewer"]`, `_G[PowerBarDB.Layout[2]]`
- Direct global references: `C_Spell`, `C_Item`, `C_AddOns` (WoW API)

## Error Handling

**Patterns:**
- **Early return guards:** Primary pattern throughout codebase
  ```lua
  function BCDM:AddBorder(parentFrame)
      if not parentFrame then return end
      -- rest of function
  end
  ```
- **Type validation:** Basic checks before processing
  ```lua
  if type(addToTypes) ~= "table" or type(anchorTable) ~= "table" then return end
  if type(encodedInfo) ~= "string" or encodedInfo:sub(1, 6) ~= "!BCDM_" then
      BCDM:PrettyPrint("Invalid Import String.")
      return
  end
  ```
- **Nil checks:** Conditional access with `and` operator
  ```lua
  local secondaryPowerBarDB = BCDM.db and BCDM.db.profile and BCDM.db.profile.SecondaryPowerBar
  ```
- **Logical OR for defaults:** Used for fallback values
  ```lua
  local borderSize = BCDM.db.profile.CooldownManager.General.BorderSize or 1
  local keepAspect = viewerDB.KeepAspectRatio
  if keepAspect == nil then keepAspect = true end
  ```
- **No thrown exceptions:** Lua error handling relies on returning nil or early exit

## Logging

**Framework:** Built-in `print()` with addon prefix

**Patterns:**
- **User-facing messages:** Via `BCDM:PrettyPrint(message)` function (defined in `Core/Globals.lua` line 37)
  ```lua
  function BCDM:PrettyPrint(MSG)
      print(BCDM.ADDON_NAME .. ":|r " .. MSG)
  end
  ```
- **When to log:**
  - Invalid imports/configurations: "Invalid Import String."
  - User actions: Profile changes, feature toggles
  - Initialization: Login message if `DisplayLoginMessage` enabled
- **No debug logging:** No verbose/debug mode in current codebase

## Comments

**When to Comment:**
- **Spell IDs:** Always commented with spell/ability name (seen in `Core/Modules/Data.lua`)
  ```lua
  [115203] = { isActive = true, layoutIndex = 1 },        -- Fortifying Brew
  ```
- **Class/spec mappings:** Comments identify WoW game mechanics
  ```lua
  if specID == 268 then return true end  -- Mistweaver
  ```
- **Disabled code:** Commented-out code blocks preserved with explanation (large block in `CooldownManager.lua` lines 74-162)
- **Complex logic:** Minimal comments on complex calculations (rare)

**JSDoc/TSDoc:**
- No formal documentation system observed
- Comments are inline and brief

## Function Design

**Size:**
- Small focused functions common: `FetchCooldownTextRegion()`, `ShouldSkin()`, `NudgeViewer()`
- Larger aggregator functions: `CreatePowerBar()` (97 lines), `CreateGUI()` (2870 lines in GUI.lua)
- GUI functions can be large due to widget tree construction

**Parameters:**
- **Minimal parameters:** Prefer database lookups over parameters
  ```lua
  local function UpdatePowerValues()
      local PowerBar = BCDM.PowerBar
      local GeneralDB = BCDM.db.profile.General
      -- Uses globals/db instead of parameters
  end
  ```
- **When parameters used:** Passed to functions that create/modify objects
  ```lua
  local function CreateCustomIcon(spellId) ... end
  local function ApplyCooldownText(cooldownViewer) ... end
  local function FetchItemInformation(itemId) ... end
  ```

**Return Values:**
- **Single returns:** Most functions return one value or nil
  ```lua
  function BCDM:ExportSavedVariables()
      -- ... processing ...
      return EncodedInfo
  end
  ```
- **Early return on error:** Functions return nil/nothing on validation failure
  ```lua
  if not profile then return nil end
  if not decodedInfo then BCDM:PrettyPrint("Invalid Import String.") return end
  ```
- **Multiple returns rare:** Limited use of multiple return values

## Module Design

**Exports:**
- **Namespace pattern:** All public functions attached to `BCDM` table or `BCDMG` (global API)
  - `BCDM` = main addon object (private scope within module)
  - `BCDMG` = global namespace for public external API
- **Table registration:** Modules don't explicitly export; they add methods to global namespace
- **Event-driven:** Modules hook into event system via `RegisterEvent()` and `SetScript("OnEvent", ...)`

**Barrel Files:**
- No barrel/index files used
- Direct file inclusion via toc file manifest (`.pkgmeta`)
- Each module (`Core/`, `Modules/`) files loaded independently

## Commenting Best Practices

**Code flow documentation:**
- Comments focus on "why" not "what" (rare)
- Spell/item lookups always documented with names
- Complex calculations left mostly uncommented
- Disabled code preserved as-is with no cleanup

**Example patterns from codebase:**
```lua
-- Clear intent: spell ID with name
[115203] = { isActive = true, layoutIndex = 1 },        -- Fortifying Brew

-- No comment for straightforward code
if not parentFrame then return end

-- Complex nested condition with spec checks (uncommented)
if specID == 268 or specID == 269 then return true end
```

---

*Convention analysis: 2026-02-04*
