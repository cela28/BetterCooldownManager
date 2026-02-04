# Architecture

**Analysis Date:** 2026-02-04

## Pattern Overview

**Overall:** Modular WoW AddOn Architecture with Ace3 Framework

**Key Characteristics:**
- Ace3 framework (AceAddon-3.0, AceDB-3.0, AceGUI-3.0) for core addon management
- UI frame creation via CreateFrame API with secure event handling
- Configuration-driven behavior through database profiles (BCDM SavedVariables)
- Lazy initialization pattern with timed deferred setup
- Hook-based patching of Blizzard frames

## Layers

**Framework Layer:**
- Purpose: Base addon infrastructure and initialization
- Location: `Core/Core.lua`
- Contains: AceAddon initialization, database setup, event manager creation
- Depends on: Ace3 libraries, WoW global APIs
- Used by: All modules, configuration system

**Configuration Layer:**
- Purpose: Default profiles, database schema, and settings management
- Location: `Core/Defaults.lua`, `Core/Share.lua`
- Contains: Default database structure with class/spec-specific data, profile import/export
- Depends on: AceDB-3.0, AceSerializer-3.0, LibDeflate
- Used by: Core, GUI, all update functions

**Data Layer:**
- Purpose: Static game data (spell data, class configurations)
- Location: `Modules/Data.lua`
- Contains: Class/spec-specific spell lists with layout indices
- Depends on: None
- Used by: Modules that need spell information

**UI/Presentation Layer:**
- Purpose: Frame creation, rendering, styling, user interaction
- Location: `Modules/CustomCooldownViewer.lua`, `Modules/PowerBar.lua`, `Modules/CastBar.lua`, etc.
- Contains: CreateFrame calls, texture/font handling, layout management, event registration on frames
- Depends on: Core configuration, WoW frame APIs
- Used by: Event manager, GUI for updates

**GUI Configuration Layer:**
- Purpose: Settings interface for in-game configuration
- Location: `Core/GUI.lua`
- Contains: AceGUI widget setup, dropdown menus, checkboxes, color pickers
- Depends on: AceGUI-3.0, LibSharedMedia-3.0, configuration
- Used by: Slash commands, profile management

**Module Coordination Layer:**
- Purpose: Event handling and cross-module updates
- Location: `Core/EventManager.lua`, `Core/Globals.lua`
- Contains: Global event registration, update orchestration
- Depends on: WoW event system
- Used by: Modules when they need to respond to game events

## Data Flow

**Initialization Flow:**

1. TOC file loads libraries (`Libraries/Init.xml`) → Ace3 and LibStub libraries register
2. TOC file loads modules (`Modules/Init.xml`) → All module scripts parse/declare functions
3. TOC file loads core (`Core/Init.xml`) → Core scripts parse in order: Globals → Defaults → GUI → EventManager → Share → API → Core
4. Ace3 triggers `OnInitialize()` in `Core.lua`:
   - Database initialized with AceDB-3.0 using BCDMDB saved variable
   - Default settings merged into profile
   - Profile change callback registered
5. Ace3 triggers `OnEnable()` in `Core.lua`:
   - Slash commands registered
   - Media resolved (fonts/textures from LibSharedMedia)
   - EventManager setup (creates BCDMEventManagerFrame)
   - Module-level setup functions called in sequence
   - Timer-deferred additional setup at 0.1s delay
   - Edit mode manager initialized

**Update Flow:**

```
Game Event (PLAYER_SPECIALIZATION_CHANGED, etc.)
  ↓
BCDMEventManagerFrame OnEvent Script
  ↓
BCDM:UpdateBCDM() - orchestrates all updates
  ↓
BCDM:UpdateCooldownViewer()
BCDM:UpdatePowerBar()
BCDM:UpdateSecondaryPowerBar()
BCDM:UpdateCastBar()
BCDM:UpdateCustomCooldownViewer()
... (other viewers)
  ↓
Each module recreates/resizes/repositions frames based on db.profile
```

**Configuration Update Flow:**

```
User changes setting in GUI
  ↓
AceGUI callback updates BCDM.db.profile
  ↓
AceDB triggers "OnProfileChanged" callback
  ↓
BCDM:UpdateBCDM() called
  ↓
All frames updated from new profile values
```

**State Management:**
- Global state: `BCDM` table (the main addon object, passed via `local _, BCDM = ...`)
- Database state: `BCDM.db` (AceDB-3.0 instance with profile/global/class storage)
- Runtime state: `BCDM.PowerBar`, `BCDM.SecondaryPowerBar`, etc. (frame references)
- UI state: `isGUIOpen` flag in GUI.lua

## Key Abstractions

**Addon Object (BCDM):**
- Purpose: Central namespace for all addon functions
- Examples: `Core/Core.lua`, `Core/Globals.lua`, `Core/API.lua`
- Pattern: All files do `local _, BCDM = ...` then define functions as `function BCDM:FunctionName()`

**Frame Creation Pattern:**
- Purpose: Consistent UI element creation with styling
- Examples: `Modules/CustomCooldownViewer.lua` (CreateCustomIcon), `Modules/PowerBar.lua` (BCDM:CreatePowerBar)
- Pattern: CreateFrame with parent, backdrop template, sizes, points, event registration, then child elements

**Module Setup/Update Pattern:**
- Purpose: Repeatable initialization and update logic
- Examples: `BCDM:SetupCustomCooldownViewer()` → `BCDM:UpdateCustomCooldownViewer()`
- Pattern: Setup function creates frames/resources, update function reconfigures from db.profile and refreshes display

**Database Schema Pattern:**
- Purpose: Profile-specific configuration organized by feature
- Location: `Core/Defaults.lua`
- Pattern: Nested tables: `profile.CooldownManager.Custom`, `profile.PowerBar`, etc. with layout coordinates and appearance settings

**Anchor Parent System:**
- Purpose: Allow UI elements to anchor to various frame references
- Location: `Core/Globals.lua` (BCDM.AnchorParents table)
- Pattern: Dictionary of viewer types → allowed anchor parents → display names

## Entry Points

**TOC File:**
- Location: `BetterCooldownManager.toc`
- Triggers: Blizzard load system
- Responsibilities: Declares dependencies, save variables, entry points

**Core.lua OnInitialize:**
- Location: `Core/Core.lua`
- Triggers: Ace3 addon system after all scripts load
- Responsibilities: Database initialization, profile setup, callback registration

**Core.lua OnEnable:**
- Location: `Core/Core.lua`
- Triggers: Ace3 addon system after OnInitialize
- Responsibilities: Slash command setup, media resolution, full UI creation

**EventManager:**
- Location: `Core/EventManager.lua`
- Triggers: BCDMEventManagerFrame listens to game events
- Responsibilities: Detect specialization/world changes, trigger BCDM:UpdateBCDM()

**Slash Commands:**
- Location: `Core/Globals.lua` (SetupSlashCommands function, called from Core.lua:Init)
- Triggers: `/bcdm`, `/bettercooldownmanager`, `/cdm`, `/bcm` chat commands
- Responsibilities: Open settings GUI via BCDM:CreateGUI()

## Error Handling

**Strategy:** Defensive coding with nil checks and conditional execution

**Patterns:**
- `if not frame then return end` - abort early if frame doesn't exist
- `if not BCDM.db.profile[setting] then ... end` - handle missing config
- `C_AddOns.IsAddOnLoaded(name)` - check for competing addons before applying skins
- InCombatLockdown check before frame modifications
- Safe get functions like `FetchCooldownTextRegion()` that return nil on failure

## Cross-Cutting Concerns

**Logging:**
- Pattern: `BCDM:PrettyPrint(message)` wraps print() with addon name prefix
- Usage: Configuration errors, import/export status

**Validation:**
- Database import validation in `Share.lua`: deserialize → type check → profile structure check
- Spell validation: `C_SpellBook.IsSpellInSpellBook(spellId)` before creating icons

**Authentication:**
- Not applicable (single-player addon)

**Configuration Hierarchy:**
- Global settings in `BCDM.db.global` (persists across profiles)
- Profile settings in `BCDM.db.profile` (per-profile customization)
- Automatic merge of defaults during OnInitialize if keys missing

---

*Architecture analysis: 2026-02-04*
