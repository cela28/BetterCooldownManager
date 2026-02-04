# External Integrations

**Analysis Date:** 2026-02-04

## APIs & External Services

**World of Warcraft Game Client API:**
- The addon integrates entirely with Blizzard's WoW API and FrameXML
- Core integration points:
  - Unit functions: `UnitClass()`, `GetSpecialization()`, `GetSpecializationInfo()`
  - Inventory functions: `GetInventoryItemID()`, `C_Item.IsUsableItem()`
  - UI functions: `InCombatLockdown()`, `UIParent`
  - Event system: `RegisterEvent()`, `CreateFrame()`
  - Timer system: `C_Timer.After()`
  - AddOn system: `C_AddOns.GetAddOnMetadata()`, `C_AddOns.IsAddOnLoaded()`
  - UI system: `C_UI.Reload()`

**CurseForge Distribution API:**
- Addon is distributed via CurseForge with project ID: `1435851`
- Referenced in `.pkgmeta`: `curse-id: 1435851`
- Build system uses CurseForge repository for external library fetching
- Libraries fetched from: `https://repos.curseforge.com/wow/`

**Wago Distribution:**
- Addon is also distributed on Wago with ID: `ANz030K4`
- Referenced in `.pkgmeta`: `wago-id: ANz030K4`
- Allows players to share profiles and configurations via Wago

**GitHub Repositories (Library Sources):**
- LibDeflate: https://github.com/SafeteeWoW/LibDeflate.git (tag: latest)
- LibCustomGlow-1.0: https://github.com/Stanzilla/LibCustomGlow.git (branch: master)
- LibDualSpec-1.0: https://github.com/AdiAddons/LibDualSpec-1.0.git (branch: master)
- LibEditModeOverride: https://github.com/plusmouse/LibEditModeOverride.git (branch: main)
- TaintLess: https://www.townlong-yak.com/addons.git/taintless (commit: default)

## Data Storage

**Saved Variables (Database):**
- Primary storage: `BCDMDB` global variable
- Location: WoW saved variables file (e.g., `World of Warcraft\_retail_\WTF\Account\[Account]\SavedVariables\BetterCooldownManager.lua`)
- Managed by: AceDB-3.0
- Contains: All user settings, profiles, cooldown configurations
- Persistence: Saved automatically by WoW client when addon settings change
- No backup: WoW handles backup of `.lua` files; addon relies entirely on this

**Profile Storage Structure:**
- `BCDMDB.profile` - Active character profile
- `BCDMDB.profiles` - Named profiles for different builds/specializations
- `BCDMDB.global` - Global settings shared across all characters
- Supports per-specialization configurations via LibDualSpec enhancement

**No External File Storage:**
- All data stored locally in WoW saved variables
- No remote database or cloud storage
- No API communication to store/sync settings

## Authentication & Identity

**No Authentication System:**
- Addon requires no login or external authentication
- Uses WoW's existing player authentication
- No API keys, tokens, or credentials needed
- All features available to any logged-in player

**Player Identity:**
- Player name and realm determined by WoW client via `UnitClass()`, `UnitName()` etc.
- No external identity validation
- No user accounts or registration

## Monitoring & Observability

**Error Tracking:**
- None detected - no external error reporting service
- Errors logged to WoW error frame (in-game)
- No telemetry or crash reporting

**Logging:**
- Local console logging via `print()` and `BCDM:PrettyPrint()` in `Core/Globals.lua`
- Messages prefixed with addon name and colored formatting
- Example: `"|cFF8080FFBetterCooldownManager:|r [message]"`
- No external log aggregation or remote logging

**Debug Output:**
- Conditional `CAST_BAR_TEST_MODE` flag in `Core/Globals.lua`
- Can be enabled for testing cast bar functionality
- No external debugging infrastructure

## CI/CD & Deployment

**Distribution Platforms:**
- CurseForge (Project ID: 1435851)
  - Primary distribution platform for WoW addons
  - Release tracking via curse-id
- Wago (Project ID: ANz030K4)
  - Secondary distribution for profiles and sharing
  - Wago-id for direct linking

**Release Process:**
- `release.sh` bash script handles packaging
- Version management via `@project-version@` token replacement
- Built-in support for creating distribution artifacts
- Manual release trigger by developer

**Hosting:**
- GitHub: https://github.com/dalehuntgb/BetterCooldownManager (referenced in GUI)
- No direct deployment automation detected
- Releases packaged and uploaded manually to CurseForge and Wago

## Environment Configuration

**No Required Environment Variables:**
- Addon requires no `.env` files or external configuration
- All configuration done through in-game GUI or profile import/export
- Default values hardcoded in `Core/Defaults.lua`

**In-Game Configuration:**
- Settings accessible via slash commands:
  - `/bcdm` - Open settings GUI
  - `/bettercooldownmanager` - Open settings GUI
  - `/cdm` - Open settings GUI
  - `/bcm` - Open settings GUI
  - `/rl` - Reload UI
- Configuration saved immediately to `BCDMDB`

**Optional Feature Toggles:**
- `BCDM.db.global.DisplayLoginMessage` - Show login message (configurable)
- `BCDM.db.global.UseGlobalProfile` - Share profile across characters (configurable)
- All toggles stored in saved variables

## Webhooks & Callbacks

**Incoming Webhooks:**
- None detected - addon is standalone, not a server

**Outgoing Webhooks:**
- None detected - no external notifications or event publishing

**AddOn Communication Callbacks:**
- CallbackHandler-1.0 registered for inter-addon communication
- Provides public API via `BCDMG:AddAnchors()` in `Core/API.lua`
- Allows other addons to register custom anchor points for UI elements
- Example in `Core/API.lua`:
  ```lua
  function BCDMG:AddAnchors(addOnName, addToTypes, anchorTable)
      if not C_AddOns.IsAddOnLoaded(addOnName) then return end
  ```

**Database Change Callbacks:**
- AceDB profile change callback in `Core/Core.lua`:
  ```lua
  BCDM.db.RegisterCallback(BCDM, "OnProfileChanged", function() BCDM:UpdateBCDM() end)
  ```
- Triggers UI refresh when player changes specialization or switches profiles

## Profile Import/Export

**Export Mechanism:**
- Serialization: AceSerializer-3.0 converts profile tables to strings
- Compression: LibDeflate compresses serialized data using Deflate algorithm
- Encoding: Encoded for clipboard/text compatibility
- Format: Prefixed with `!BCDM_` for identification
- Implementation: `Core/API.lua:BCDMG:ExportBCDM(profileKey)`

**Import Mechanism:**
- Decoding: Extracts base encoding from import string
- Decompression: LibDeflate decompresses Deflate data
- Deserialization: AceSerializer-3.0 reconstructs profile table
- Validation: Checks for valid data before importing
- Implementation: `Core/API.lua:BCDMG:ImportBCDM(importString, profileKey)`

**Use Cases:**
- Player sharing builds with others via Wago or Discord
- Backing up configurations manually
- Migrating profiles between accounts
- Sharing optimal cooldown tracking setups in raiding communities

## Social & Support Integration

**Community Platforms:**
- Discord: https://discord.gg/UZCgWRYvVE
  - Linked in README and GUI buttons
- Twitch: https://www.twitch.tv/unhaltedgb (subscribing)
  - Creator's Twitch channel for support
- Patreon: https://patreon.com/Unhalted
  - Patronage support
- Ko-Fi: https://ko-fi.com/unhalted
  - Donation platform
- StreamElements: https://streamelements.com/unhaltedgb/tip
  - Direct donation link

**URLs Configured in GUI:**
- Slash command `/bcdm` opens settings with support links
- Links stored in `Core/GUI.lua`
- Opens in player's default browser when clicked

## Third-Party AddOn Integration Points

**Public API:**
- `BCDMG:AddAnchors(addOnName, addToTypes, anchorTable)` in `Core/API.lua`
- Allows other WoW addons to register custom anchor points
- Supported anchor types:
  - "Utility" - Utility cooldown viewer
  - "Buffs" - Buff icon cooldown viewer
  - "Custom" - Custom cooldown viewer
  - "Item" - Custom item viewer
  - "Trinket" - Trinket bar
- Other addons can extend UI placement without modifying BetterCooldownManager code

**Shared Library Ecosystem:**
- Consumed by other addons via LibStub
- Provides examples of proper Ace3 patterns for WoW addon development
- All libraries are industry-standard and reused across WoW addon ecosystem

---

*Integration audit: 2026-02-04*
