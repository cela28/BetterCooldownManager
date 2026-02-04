# Codebase Structure

**Analysis Date:** 2026-02-04

## Directory Layout

```
BetterCooldownManager/
├── BetterCooldownManager.toc    # TOC manifest - declares load order and save variables
├── Core/                        # Core addon functionality
│   ├── Init.xml                # Load order for core files
│   ├── Globals.lua             # Global constants, library stubs, helper functions
│   ├── Defaults.lua            # Database schema and default settings
│   ├── Core.lua                # Ace3 initialization (OnInitialize, OnEnable)
│   ├── EventManager.lua        # Game event handling and update orchestration
│   ├── GUI.lua                 # In-game configuration interface
│   ├── API.lua                 # Public API for other addons
│   └── Share.lua               # Profile import/export functionality
├── Modules/                     # Feature modules - each extends addon functionality
│   ├── Init.xml               # Load order for all modules
│   ├── CooldownManager.lua     # Blizzard cooldown viewer customization
│   ├── CustomCooldownViewer.lua    # User-created cooldown bar
│   ├── AdditionalCustomCooldownViewer.lua  # Second custom cooldown bar
│   ├── CustomItemViewer.lua    # Item cooldown display
│   ├── CustomItemSpellViewer.lua   # Combined item/spell viewer
│   ├── PowerBar.lua            # Primary power (mana, rage, etc.) display
│   ├── SecondaryPowerBar.lua   # Secondary power (chi, combo points, etc.)
│   ├── CastBar.lua             # Cast time display
│   ├── TrinketBar.lua          # Trinket cooldown tracker
│   ├── CustomGlows.lua         # Spell glow effects
│   ├── DisableAuraOverlay.lua  # Aura texture removal
│   ├── Data.lua                # Static game data (class/spec spells)
│   └── EditMode.lua            # Edit mode integration
├── Libraries/                   # Third-party libraries (Ace3, custom)
│   ├── Init.xml               # Library load order
│   ├── Ace3/                  # Ace3 framework suite
│   ├── LibStub/               # Library dependency system
│   ├── LibCustomGlow-1.0/     # Glow effect library
│   ├── LibSharedMedia-3.0/    # Font/texture manager
│   ├── LibDualSpec-1.0/       # Specialization data handler
│   ├── LibDeflate/            # Compression library
│   ├── LibEditModeOverride/   # EditMode frame customization
│   ├── CallbackHandler-1.0/   # Event callback system
│   └── TaintLess/             # Taint avoidance helpers
├── Media/                       # Static assets
│   ├── Logo.png               # Addon icon
│   ├── InfoButton.png         # UI button texture
│   ├── BetterBlizzard.blp     # Status bar texture
│   ├── Glow.tga               # Glow effect texture
│   └── Support/               # Help/documentation images
└── .planning/                  # GSD documentation directory
    └── codebase/              # Codebase analysis documents
```

## Directory Purposes

**Core/:**
- Purpose: Main addon initialization, configuration, and event orchestration
- Contains: AceAddon lifecycle, database initialization, slash commands, GUI framework
- Key files: `Core.lua` (entry points), `Globals.lua` (constants), `Defaults.lua` (schema)

**Modules/:**
- Purpose: Individual features that extend the addon
- Contains: Frame creation, event handlers, update logic for each visual component
- Key files: `CooldownManager.lua` (Blizzard viewer skin), `CustomCooldownViewer.lua` (primary custom bar)

**Libraries/:**
- Purpose: External dependencies and frameworks
- Contains: Ace3 libraries, LibStub, media/data managers, utility libraries
- Key files: `Ace3/AceAddon-3.0` (addon lifecycle), `Ace3/AceDB-3.0` (database), `Ace3/AceGUI-3.0` (UI widgets)

**Media/:**
- Purpose: Static image and texture assets
- Contains: PNG icons, TGA textures, visual resources
- Key files: Logo, textures for bars and glows

## Key File Locations

**Entry Points:**
- `BetterCooldownManager.toc`: Blizzard manifest - defines load order (Libraries → Modules → Core)
- `Core/Core.lua`: Ace3 initialization - OnInitialize creates database, OnEnable creates UI
- `Core/Globals.lua`: Module initialization - sets up slash commands, media resolution

**Configuration:**
- `Core/Defaults.lua`: Database schema with all configurable settings per class/spec
- `Core/GUI.lua`: AceGUI-based settings panel (2870 lines - largest file)

**Core Logic:**
- `Core/EventManager.lua`: Game event listener triggers BCDM:UpdateBCDM()
- `Modules/CooldownManager.lua`: Blizzard viewer restyling and customization
- `Modules/Data.lua`: Class/spec/spell mapping for defensive cooldowns

**Testing:**
- No test framework present

## Naming Conventions

**Files:**
- PascalCase: `CooldownManager.lua`, `CustomCooldownViewer.lua`, `SecondaryPowerBar.lua`
- Rationale: Module names match their primary class/component

**Directories:**
- PascalCase: `Core/`, `Modules/`, `Libraries/`, `Media/`
- Convention: Functional grouping

**Functions:**
- CamelCase with colon syntax: `BCDM:CreatePowerBar()`, `BCDM:UpdateCooldownViewer()`, `BCDM:ResolveLSM()`
- Pattern: All functions attached to BCDM addon object
- Prefixes used:
  - Setup: `BCDM:SetupEventManager()` - initial frame creation
  - Update: `BCDM:UpdatePowerBar()` - refresh from configuration
  - Create: `BCDM:CreateGUI()` - build UI elements
  - Fetch/Get: `FetchCooldownTextRegion()` - retrieve existing objects

**Variables:**
- camelCase for locals: `viewerDB`, `customIcon`, `powerType`
- UPPERCASE for constants: `BCDMG`, `DEFENSIVE_SPELLS`, `OVERLAY_COLOUR`
- Hungarian notation in DB keys: `db.profile`, `db.global`, `db.profiles`

**Types:**
- Not typed (Lua), but naming implies:
  - `...DB` = configuration table/section
  - `...Frame` or `Frame` suffix = WoW frame object
  - `...Colour` = {r, g, b, a} array

## Where to Add New Code

**New Feature (e.g., debuff tracker):**
- Primary code: `Modules/DebuffTracker.lua` (create new module file)
- Setup function: `BCDM:SetupDebuffTracker()` called from `Core/Core.lua` OnEnable
- Update function: `BCDM:UpdateDebuffTracker()` called from BCDM:UpdateBCDM()
- Configuration: Add keys to `Core/Defaults.lua` under `profile.DebuffTracker = {}`
- GUI options: Add widgets to `Core/GUI.lua` in settings panel
- Load declaration: Add `<Script file="DebuffTracker.lua"/>` to `Modules/Init.xml`

**New Viewer Type (e.g., AoE cooldowns):**
- Frame creation: `Modules/CustomAoEViewer.lua` following `Modules/CustomCooldownViewer.lua` pattern
  - Use CreateFrame with "BCDM_CustomAoEViewer" name
  - Create child icons with spell ID as identifier
  - Register event handlers (SPELL_UPDATE_COOLDOWN, etc.)
  - Store as `BCDM.CustomAoEViewer`
- Setup: `BCDM:SetupCustomAoEViewer()` in new file, call from Core OnEnable
- Update: `BCDM:UpdateCustomAoEViewer()` called from UpdateBCDM()
- Database: Add `profile.CooldownManager.CustomAoE = {}` with Layout, IconSize, etc.

**New Helper Function:**
- Utilities shared across modules: `Core/Globals.lua`
- Frame styling helpers: Add to `Core/Globals.lua:AddBorder()` section
- Module-specific helpers: Keep local within module file

**GUI Addition (new settings):**
- Source: `Core/GUI.lua`
- Pattern: Create AceGUI widget, set initial value from db.profile, register change callback to update db
- Organization: Group related settings in same section
- Trigger: Widget change → db.profile update → AceDB callback fires → BCDM:UpdateBCDM()

## Special Directories

**Libraries/Ace3/:**
- Purpose: Ace3 framework modules
- Generated: No (third-party library)
- Committed: Yes
- Contains: AceAddon-3.0, AceDB-3.0, AceGUI-3.0, AceSerializer-3.0, and other Ace3 modules
- Usage: LibStub("AceAddon-3.0"):NewAddon() in Core.lua

**Media/:**
- Purpose: Static image/texture assets
- Generated: No
- Committed: Yes
- Contains: Logo.png, textures (.blp, .tga files)
- Usage: Referenced in defaults.lua via LibSharedMedia

**.planning/:**
- Purpose: GSD documentation and planning
- Generated: Yes (by GSD tools)
- Committed: Yes
- Contains: Codebase analysis documents (ARCHITECTURE.md, STRUCTURE.md, etc.)

## Import Patterns

**Addon Object Access:**
- All files: `local _, BCDM = ...` to get BCDM addon object
- Libraries: `local LSM = BCDM.LSM` to access registered library instances from Globals
- Example: `Core/GUI.lua` line 2: `local LSM = BCDM.LSM`

**Library Usage:**
- Registered in Globals.lua: `BCDM.LSM = LibStub("LibSharedMedia-3.0")`
- Used throughout: `BCDM.LSM:Fetch("font", fontName)`
- Pattern: Always check BCDM.LSM exists before using

**Blizzard API:**
- Direct access: `C_AddOns.IsAddOnLoaded()`, `UnitClass()`, `CreateFrame()`
- Not imported, used globally from WoW environment
- Wrapped occasionally: `BCDM:StripTextures()` wraps texture removal logic

---

*Structure analysis: 2026-02-04*
