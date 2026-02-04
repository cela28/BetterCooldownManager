# Testing Patterns

**Analysis Date:** 2026-02-04

## Test Framework

**Runner:**
- **Not detected** - No primary testing framework configured
- Test files exist only in `Libraries/LibStub/tests/` (external library tests)
- No custom test framework for addon code

**Assertion Library:**
- Not applicable - no testing framework installed

**Run Commands:**
```bash
# No automated test runner available
# Manual testing via WoW game client required
```

## Test File Organization

**Location:**
- Not applicable for main addon code
- Test files present only in library code: `/Libraries/LibStub/tests/test.lua`, `test2.lua`, `test3.lua`, `test4.lua`
- No unit test files for Core or Modules

**Naming:**
- LibStub tests follow pattern: `test.lua`, `test2.lua`, `test3.lua`, `test4.lua`
- No consistent naming convention for addon-specific tests

**Structure:**
```
BetterCooldownManager/
├── Core/           # No tests
├── Modules/        # No tests
├── Libraries/
│   └── LibStub/
│       └── tests/  # External library tests only
```

## Test Structure

**Manual Testing Approach:**
The addon relies on manual testing within the WoW game client. Code is validated through:

1. **In-game functionality testing:**
   - Load addon via WoW client
   - Verify frames appear and position correctly
   - Test UI interactions (drag, resize, configure)
   - Test event handlers fire correctly

2. **Configuration persistence testing:**
   - Change settings via GUI
   - Reload UI (`/rl` command)
   - Verify settings persist in saved variables

3. **Cross-addon compatibility testing:**
   - Verify compatibility checks with: ElvUI, MasqueBlizzBars, Blizzard_CooldownViewer
   - Check interaction with Ace3 framework

4. **Class/spec-specific testing:**
   - Test secondary power bar detection across all classes
   - Verify spell lists and cooldown display per specialization

## Mocking

**Framework:**
- Not applicable - no testing framework

**Patterns:**
- No test mocks needed due to manual testing approach
- Conditional logic tested via in-game state changes:
  ```lua
  -- Example: DetectSecondaryPower() function validated by:
  -- 1. Loading addon on different character classes
  -- 2. Switching specializations in-game
  -- 3. Observing secondary power bar display
  ```

**What to Mock (if testing framework were added):**
- WoW API functions: `UnitClass()`, `GetSpecialization()`, `UnitPower()`, etc.
- Ace3 database operations: `BCDM.db` and profile access
- Frame methods: `CreateFrame()`, `SetPoint()`, `RegisterEvent()`, etc.
- LibStub library lookups

**What NOT to Mock:**
- Core business logic for layout calculations
- Event handling system (test with real events where possible)
- Frame positioning and sizing logic

## Fixtures and Factories

**Test Data:**
- Spell and item data hardcoded in `Modules/Data.lua` (417 lines)
  ```lua
  local DEFENSIVE_SPELLS = {
      ["MONK"] = {
          ["BREWMASTER"] = {
              [115203] = { isActive = true, layoutIndex = 1 },        -- Fortifying Brew
              [1241059] = { isActive = true, layoutIndex = 2 },       -- Celestial Infusion
          },
      },
      -- ... extensive class/spec/spell combinations
  }
  ```
- Power type color mappings in `Core/Defaults.lua` (lines 37-75)
- Anchor parent configurations in `Core/Globals.lua` (lines 452-589)

**Location:**
- `Modules/Data.lua` - Primary spell and class-spec data
- `Core/Defaults.lua` - Default configuration and color mappings
- `Core/Globals.lua` - Frame anchor parents and constants

## Coverage

**Requirements:**
- **Not enforced** - No coverage tools configured

**Current State:**
- No automated coverage metrics
- Manual validation of:
  - All public API functions (via GUI interactions)
  - Event handlers (via in-game events)
  - Database read/write (via settings persistence)
  - UI rendering (visual inspection)

## Test Types

**Unit Tests:**
- **Not implemented** - Would require testing individual functions in isolation
- Candidates for unit testing (if framework added):
  - `BCDM:GetIconDimensions()` - calculates icon dimensions
  - `BCDM:GetIconTexCoords()` - calculates texture coordinates
  - `BCDM:CopyTable()` - deep table copying logic
  - Export/import functions in `Core/Share.lua`

**Integration Tests:**
- **Manual via game client** - Performed by loading addon and interacting with features
- **Profile creation and switching** - Test `BCDM.db:SetProfile()` workflow
- **Cross-module interaction** - Power bars, cooldown viewers, glow effects working together
- **Ace3 framework integration** - Database callbacks, GUI widget creation

**E2E Tests:**
- **Not formalized** - Equivalent to manual testing session
- Would involve:
  - Starting WoW client with addon
  - Creating character (or using existing)
  - Opening configuration GUI
  - Changing multiple settings
  - Reloading UI
  - Verifying all changes persisted and visual updates applied

## Common Patterns

**Validation in Production Code:**
Functions validate inputs before processing (defensive coding):

```lua
-- Type checking before iteration
function BCDMG:AddAnchors(addOnName, addToTypes, anchorTable)
    if not C_AddOns.IsAddOnLoaded(addOnName) then return end
    if type(addToTypes) ~= "table" or type(anchorTable) ~= "table" then return end
    for _, typeName in ipairs(addToTypes) do
        if BCDM.AnchorParents[typeName] then
            -- safe to process
        end
    end
end
```

**Nil guards:**
```lua
-- Early exit pattern prevents nil access
if not textureToStrip then return end
if not textureParent then return end

-- Conditional chaining
local secondaryPowerBarDB = BCDM.db and BCDM.db.profile and BCDM.db.profile.SecondaryPowerBar
```

**Async/Deferred Execution:**
```lua
-- Using C_Timer.After for deferred initialization
C_Timer.After(0.1, function()
    BCDM:SetupCustomCooldownViewer()
    BCDM:SetupAdditionalCustomCooldownViewer()
    -- ... more setup
end)
```

**Event-Driven Testing Points:**
Addon listens to these events (test by triggering):
- `PLAYER_ENTERING_WORLD` - Login, zone change
- `PLAYER_SPECIALIZATION_CHANGED` - Spec swap
- `SPELL_UPDATE_COOLDOWN` - Cooldown changes
- `SPELL_UPDATE_CHARGES` - Charge/stack changes
- `UPDATE_SHAPESHIFT_FORM` - Form changes
- `TRAIT_CONFIG_UPDATED` - Talent changes

---

## Recommendations for Adding Testing

If a testing framework were to be added, recommended approach:

1. **Adopt Busted or LÖVE test framework** - Suitable for Lua projects
2. **Mock WoW API** - Create stubs for `UnitClass()`, frame methods, etc.
3. **Focus on core utilities first:**
   - `BCDM:GetIconTexCoords()` - Pure calculation logic
   - `BCDM:CopyTable()` - Well-defined inputs/outputs
   - Export/import serialization in `Core/Share.lua`
4. **Add integration tests** for multi-function workflows
5. **Document test requirements** for new features during development

Current manual testing is effective for visual UI addons, but automated tests would catch regressions and support refactoring with confidence.

---

*Testing analysis: 2026-02-04*
