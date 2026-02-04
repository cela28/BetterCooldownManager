# Technology Stack

**Analysis Date:** 2026-02-04

## Languages

**Primary:**
- Lua - World of Warcraft AddOn scripting language. All game logic, UI, and configuration implemented in Lua.

**Configuration:**
- XML - UI frame definitions and loading order configuration
- YAML - Package metadata and build configuration (`.pkgmeta`)

## Runtime

**Environment:**
- World of Warcraft Client - Supports patches 12.0.0 and 12.0.1 (as specified in `.toc` file: `Interface: 120000, 120001`)
- Blizzard FrameXML - WoW's native UI framework

**AddOn System:**
- WoW AddOn loader - Managed via `.toc` (Table of Contents) file at `/home/sntanavaras/random-projects/BetterCooldownManager/BetterCooldownManager.toc`
- Saved variables via `BCDMDB` global variable for persistent storage between sessions

## Frameworks & Libraries

**Core AddOn Framework:**
- Ace3 (AceAddon-3.0) - AddOn initialization and lifecycle management
  - Location: `Libraries/Ace3/`
  - Used in `Core/Core.lua` via `LibStub("AceAddon-3.0"):NewAddon("BetterCooldownManager")`

**Database & Configuration:**
- AceDB-3.0 - Profile-based database storage and management
  - Location: `Libraries/Ace3/AceDB-3.0/`
  - Stores addon settings in `BCDMDB` saved variable
  - Supports multiple profiles and character-specific configurations

**UI & GUI:**
- AceGUI-3.0 - GUI widget framework for configuration panels
  - Location: `Libraries/Ace3/AceGUI-3.0/`
  - Used in `Core/GUI.lua` for settings interface
- AceGUI-3.0-SharedMediaWidgets - Extended widgets for media selection
  - Location: `Libraries/Ace3/AceGUI-3.0-SharedMediaWidgets/`
  - Provides statusbar, border, font, sound, and background widgets

**LibStub:**
- LibStub - Library versioning and dependency management system
  - Location: `Libraries/LibStub/`
  - Core dependency for all other libraries

**Data & Serialization:**
- AceSerializer-3.0 - Serializes/deserializes data structures
  - Location: `Libraries/Ace3/AceSerializer-3.0/`
  - Used in `Core/API.lua` for profile import/export
- LibDeflate - Compression library for profile export/import
  - GitHub: https://github.com/SafeteeWoW/LibDeflate.git
  - Location: `Libraries/LibDeflate/`
  - Enables compact profile export strings

**Specialization Support:**
- LibDualSpec-1.0 - Handles separate configurations per specialization
  - GitHub: https://github.com/AdiAddons/LibDualSpec-1.0.git
  - Location: `Libraries/LibDualSpec-1.0/`
  - Enhanced database in `Core/Core.lua`: `BCDM.LDS:EnhanceDatabase(BCDM.db, "UnhaltedUnitFrames")`

**UI Customization:**
- LibSharedMedia-3.0 - Shared media registry for fonts, textures, sounds
  - CurseForge: https://www.curseforge.com/wow/addons/libsharedmedia-3-0
  - Location: `Libraries/LibSharedMedia-3.0/`
  - Used in `Core/Globals.lua` for media resolution

**Visual Effects:**
- LibCustomGlow-1.0 - Custom glow effects for cooldown indicators
  - GitHub: https://github.com/Stanzilla/LibCustomGlow.git
  - Location: `Libraries/LibCustomGlow-1.0/`
  - Used in `Core/Core.lua:BCDM:SetupCustomGlows()`

**Edit Mode Integration:**
- LibEditModeOverride - Secure edit mode layout management
  - GitHub: https://github.com/plusmouse/LibEditModeOverride.git
  - Location: `Libraries/LibEditModeOverride/`
  - Used in `Core/Core.lua:BCDM:SetupEditModeManager()`
- TaintLess - Taint detection and debugging
  - Location: `Libraries/TaintLess/`

**Callback Management:**
- CallbackHandler-1.0 - Event callback system for inter-addon communication
  - Location: `Libraries/CallbackHandler-1.0/`

## Key Dependencies

**Critical:**
- Ace3 Suite - Required for addon initialization, database storage, and configuration UI
- LibStub - Dependency resolver; all libraries depend on this
- AceDB-3.0 - Persistent configuration storage; data is lost without it
- AceGUI-3.0 - Configuration interface depends entirely on this

**Media & Display:**
- LibSharedMedia-3.0 - Font and texture resolution; fallback to Blizzard defaults if missing
- LibDeflate - Profile import/export compression; profiles can't be exported without this

**Specialization & Layout:**
- LibDualSpec-1.0 - Per-spec profiles; fallback to single profile if missing
- LibEditModeOverride - EditMode support; frames still work without it but can't be customized via EditMode

## Configuration Files

**Metadata:**
- `.pkgmeta` - Package metadata including CurseForge and Wago IDs, external library dependencies
  - Defines all external library fetch URLs
  - Enables automated distribution packaging

**Manifest:**
- `BetterCooldownManager.toc` - AddOn manifest table
  - Defines interface version compatibility (12.0.0, 12.0.1)
  - Declares saved variable: `BCDMDB`
  - Specifies load order: Libraries → Modules → Core
  - Contains metadata tags for distribution

**Build & Release:**
- `release.sh` - Bash script for packaging releases to CurseForge and Wago
  - Creates distribution artifacts

## Loading Order

The addon loads in strict sequence defined by `BetterCooldownManager.toc`:

1. **Libraries** (via `Libraries/Init.xml`):
   - LibStub
   - CallbackHandler-1.0
   - LibSharedMedia-3.0
   - LibDeflate
   - Ace3 suite (AceAddon, AceDB, AceDBOptions, AceGUI, AceSerializer)
   - AceGUI-3.0-SharedMediaWidgets
   - TaintLess
   - LibCustomGlow-1.0
   - LibDualSpec-1.0
   - LibEditModeOverride

2. **Modules** (via `Modules/Init.xml`):
   - CastBar.lua
   - CooldownManager.lua
   - CustomGlows.lua
   - DisableAuraOverlay.lua
   - Data.lua (spell, item, racial data)
   - AdditionalCustomCooldownViewer.lua
   - CustomCooldownViewer.lua
   - CustomItemViewer.lua
   - CustomItemSpellViewer.lua
   - TrinketBar.lua
   - PowerBar.lua
   - SecondaryPowerBar.lua
   - EditMode.lua

3. **Core** (via `Core/Init.xml`):
   - Globals.lua - Global constants and helper functions
   - Defaults.lua - Default configuration values
   - GUI.lua - Settings UI implementation (~150KB)
   - EventManager.lua - Event registration and handling
   - Share.lua - Inter-addon communication
   - API.lua - Public API for other addons
   - Core.lua - Main addon lifecycle hooks (OnInitialize, OnEnable)

## Platform Requirements

**Development:**
- Git (for source control)
- Lua 5.1 syntax compatibility (WoW runs Lua 5.1)
- Understanding of WoW addon architecture and FrameXML
- CurseForge account (for distribution)
- Wago account (for distribution)

**Production (Player Runtime):**
- World of Warcraft client 12.0.0 or later
- Ability to load third-party addons
- Approximately 1-2MB disk space for addon files and saved variables
- Sufficient UI frame budget for cosmetic frames (power bars, custom viewers)

## Version Management

**Version Source:**
- `@project-version@` token in `.toc` file is replaced during build/release
- Actual version managed via release tags and build system
- Latest release: Referenced in git history (commit `4d81149`)

**Compatibility:**
- Single codebase supports WoW patch 12.0.0 and 12.0.1
- Uses Blizzard API from patch 12.0.0 forward
- No legacy patch compatibility layers needed

---

*Stack analysis: 2026-02-04*
