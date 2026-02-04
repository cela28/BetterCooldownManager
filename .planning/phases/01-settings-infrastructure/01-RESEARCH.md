# Phase 1: Settings Infrastructure - Research

**Researched:** 2026-02-04
**Domain:** WoW Addon Settings with AceDB-3.0
**Confidence:** HIGH

## Summary

This phase involves adding a per-bar boolean setting (`hideWhenOffCooldown`) to the existing BetterCooldownManager addon. The addon already has a well-established settings infrastructure using AceDB-3.0 for SavedVariables persistence, with per-bar settings defined in `Core/Defaults.lua` and accessed via `BCDM.db.profile.CooldownManager.[BarType].[Setting]`.

The codebase follows consistent patterns for per-bar boolean settings. Examples include `CenterHorizontally` (for Essential/Utility bars) and `CenterBuffs` (for Buffs bar). These patterns show exactly how to:
1. Define defaults in `Defaults.lua`
2. Access settings via `BCDM.db.profile.CooldownManager.[BarType].[Setting]`
3. Wire settings to GUI checkboxes in `GUI.lua`

**Primary recommendation:** Follow the existing `CenterHorizontally` pattern exactly - add the setting to the same three bar types (Essential, Utility, Buffs) in Defaults.lua, then access via `BCDM.db.profile.CooldownManager.[BarType].HideWhenOffCooldown`.

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| AceDB-3.0 | Bundled | SavedVariables management | Already used by BCDM, provides profile support |
| AceGUI-3.0 | Bundled | GUI widget framework | Already used for all settings UI |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| LibDualSpec-1.0 | Bundled | Profile switching by spec | Already integrated, automatic |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| AceDB-3.0 | Raw SavedVariables | AceDB already in use, no reason to change |
| Per-bar setting | Global setting | User requested per-bar toggle |

**No new libraries needed** - all infrastructure already exists.

## Architecture Patterns

### Recommended Project Structure
```
Core/
├── Defaults.lua     # Add HideWhenOffCooldown to Essential, Utility, Buffs
├── GUI.lua          # Add checkbox widget (Phase 5, not this phase)
└── Globals.lua      # Viewer mappings (no changes needed)
```

### Pattern 1: Per-Bar Boolean Setting Definition
**What:** Define a boolean setting that applies individually to each bar type
**When to use:** Any setting that users should toggle per-bar
**Example:**
```lua
-- Source: Core/Defaults.lua lines 123-148 (existing pattern)
CooldownManager = {
    Essential = {
        IconSize = 42,
        CenterHorizontally = false,  -- Existing example
        HideWhenOffCooldown = false, -- NEW: Add here
        -- ...other settings
    },
    Utility = {
        IconSize = 36,
        CenterHorizontally = false,  -- Existing example
        HideWhenOffCooldown = false, -- NEW: Add here
        -- ...other settings
    },
    Buffs = {
        IconSize = 32,
        CenterBuffs = false,         -- Existing example
        HideWhenOffCooldown = false, -- NEW: Add here
        -- ...other settings
    },
}
```

### Pattern 2: Setting Access Pattern
**What:** How to read/write per-bar settings at runtime
**When to use:** Any code that needs to check or modify the setting
**Example:**
```lua
-- Source: Modules/CooldownManager.lua lines 305-307 (existing pattern)
local function CheckHideWhenOffCooldown(barType)
    local barSettings = BCDM.db.profile.CooldownManager[barType]
    if barSettings.HideWhenOffCooldown then
        -- Setting is enabled for this bar
    end
end
```

### Pattern 3: Getter/Setter Function Pattern
**What:** Wrapper functions for consistent access
**When to use:** When multiple modules need to access the same setting
**Example:**
```lua
-- NEW: Add to Core/Globals.lua or new file
function BCDM:GetHideWhenOffCooldown(barType)
    local barSettings = BCDM.db.profile.CooldownManager[barType]
    return barSettings and barSettings.HideWhenOffCooldown or false
end

function BCDM:SetHideWhenOffCooldown(barType, value)
    local barSettings = BCDM.db.profile.CooldownManager[barType]
    if barSettings then
        barSettings.HideWhenOffCooldown = value
    end
end
```

### Anti-Patterns to Avoid
- **Global variable for per-bar setting:** Don't use a single global toggle; the spec requires per-bar control
- **Hardcoding bar names in conditionals:** Use the existing mapping tables (`BCDM.CooldownManagerViewerToDBViewer`)
- **Bypassing AceDB:** Always go through `BCDM.db.profile`, never write directly to SavedVariables

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| SavedVariables persistence | Custom serialization | AceDB-3.0 | Already integrated, handles profiles |
| Default values | nil checks everywhere | AceDB defaults table | Automatic fallback handling |
| Profile switching | Manual tracking | LibDualSpec-1.0 | Already integrated |

**Key insight:** The addon already has all the infrastructure. This phase is about adding one field to existing structures, not building new systems.

## Common Pitfalls

### Pitfall 1: Forgetting to Add Default Value
**What goes wrong:** Setting returns `nil` instead of `false`, causing errors
**Why it happens:** New field added to schema without default
**How to avoid:** Always add the field to the `Defaults` table with explicit `false`
**Warning signs:** Errors like "attempt to index nil value" on first run

### Pitfall 2: Wrong Bar Type Key
**What goes wrong:** Setting saved but not read correctly
**Why it happens:** Using viewer frame name instead of DB key
**How to avoid:** Use `BCDM.CooldownManagerViewerToDBViewer` mapping table
**Warning signs:** Setting works in GUI but not in code

### Pitfall 3: Checking Setting Before DB Initialized
**What goes wrong:** Nil errors during addon load
**Why it happens:** Accessing `BCDM.db.profile` before `OnInitialize`
**How to avoid:** Only access settings in or after `OnEnable`, not at load time
**Warning signs:** Errors only on fresh install or first login

### Pitfall 4: Missing Bar Types
**What goes wrong:** Feature works for some bars but not others
**Why it happens:** Setting added to Essential but not Utility/Buffs
**How to avoid:** Add to ALL applicable bar types in Defaults.lua
**Warning signs:** Users report inconsistent behavior across bars

## Code Examples

### Adding the Setting to Defaults.lua
```lua
-- Source: Core/Defaults.lua (based on existing structure)
-- Add HideWhenOffCooldown = false to each bar section:

Essential = {
    IconSize = 42,
    IconWidth = 42,
    IconHeight = 42,
    KeepAspectRatio = true,
    CenterHorizontally = false,
    HideWhenOffCooldown = false,  -- NEW
    Layout = {"CENTER", "CENTER", 0, -275.1},
    -- ...
},
Utility = {
    IconSize = 36,
    IconWidth = 36,
    IconHeight = 36,
    KeepAspectRatio = true,
    CenterHorizontally = false,
    HideWhenOffCooldown = false,  -- NEW
    Layout = {"TOP", "EssentialCooldownViewer", "BOTTOM", 0, -1.1},
    -- ...
},
Buffs = {
    IconSize = 32,
    IconWidth = 32,
    IconHeight = 32,
    KeepAspectRatio = true,
    CenterBuffs = false,
    HideWhenOffCooldown = false,  -- NEW
    Layout = {"BOTTOM", "BCDM_SecondaryPowerBar", "TOP", 0, 1.1},
    -- ...
},
```

### Getter/Setter Functions (Optional but Recommended)
```lua
-- Source: Add to Core/Globals.lua
-- These provide a clean API for other phases to use

function BCDM:GetHideWhenOffCooldown(barType)
    if not barType then return false end
    local barSettings = self.db.profile.CooldownManager[barType]
    return barSettings and barSettings.HideWhenOffCooldown or false
end

function BCDM:SetHideWhenOffCooldown(barType, value)
    if not barType then return end
    local barSettings = self.db.profile.CooldownManager[barType]
    if barSettings then
        barSettings.HideWhenOffCooldown = value
        -- Future phases may add refresh calls here
    end
end

-- Helper to check by viewer frame name
function BCDM:IsHideWhenOffCooldownEnabled(viewerFrameName)
    local barType = self.CooldownManagerViewerToDBViewer[viewerFrameName]
    return self:GetHideWhenOffCooldown(barType)
end
```

### Accessing the Setting (Usage Example for Later Phases)
```lua
-- Source: How other phases will use this setting
local function ShouldHideIcon(viewerName, spellID)
    local barType = BCDM.CooldownManagerViewerToDBViewer[viewerName]
    if not BCDM:GetHideWhenOffCooldown(barType) then
        return false  -- Feature disabled for this bar
    end
    -- Phase 2 will add cooldown state check here
    return true
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Raw SavedVariables | AceDB-3.0 | ~2008 | Standard for WoW addons |
| Manual default handling | AceDB defaults table | AceDB 3.0 | Automatic fallback |

**Deprecated/outdated:**
- Direct SavedVariables manipulation without AceDB (no migration needed, BCDM already uses AceDB)

## Open Questions

1. **Should Custom/AdditionalCustom bars also get this setting?**
   - What we know: PROJECT.md mentions "Essential, Utility, Custom, etc." but these are user-defined bars
   - What's unclear: Custom bars have different structure (per-class/spec spells)
   - Recommendation: Start with Essential, Utility, Buffs (the built-in CDM bars). Custom bars can be added later if requested.

2. **Should the setting name be `HideWhenOffCooldown` or `hideWhenOffCooldown`?**
   - What we know: Existing settings use PascalCase (e.g., `CenterHorizontally`, `KeepAspectRatio`)
   - What's unclear: None - PascalCase is clearly the convention
   - Recommendation: Use `HideWhenOffCooldown` (PascalCase)

## Sources

### Primary (HIGH confidence)
- Codebase analysis: `Core/Defaults.lua` - existing per-bar settings structure
- Codebase analysis: `Core/Core.lua` - AceDB initialization pattern
- Codebase analysis: `Modules/CooldownManager.lua` - setting access patterns
- Codebase analysis: `Core/GUI.lua` lines 1389-1416 - checkbox widget wiring

### Secondary (MEDIUM confidence)
- [AceDB-3.0 Tutorial - WowAce](https://www.wowace.com/projects/ace3/pages/ace-db-3-0-tutorial) - SavedVariables patterns
- [Ace3 for Dummies - Wowpedia](https://wowpedia.fandom.com/wiki/Ace3_for_Dummies) - General patterns

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Analyzed actual codebase, no external dependencies
- Architecture: HIGH - Patterns extracted from existing code
- Pitfalls: HIGH - Based on WoW addon experience and code review

**Research date:** 2026-02-04
**Valid until:** 90 days (stable patterns, no external API changes expected)
