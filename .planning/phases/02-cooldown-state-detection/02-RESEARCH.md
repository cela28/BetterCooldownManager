# Phase 2: Cooldown State Detection - Research

**Researched:** 2026-02-04
**Domain:** WoW API cooldown detection (C_Spell namespace)
**Confidence:** HIGH

## Summary

This phase implements reliable cooldown state detection for WoW spells using Blizzard's C_Spell API. The research investigated BCM's existing patterns for cooldown detection, GCD filtering, charge spell handling, and event-driven updates.

BCM already uses the modern C_Spell API (introduced Patch 11.0.0, July 2024) with event-driven updates via SPELL_UPDATE_COOLDOWN and SPELL_UPDATE_CHARGES. The codebase shows consistent patterns: check charges first (C_Spell.GetSpellCharges), fall back to regular cooldown (C_Spell.GetSpellCooldown), use minimal pcall protection only where API can throw, and rely on nil checks for error handling.

For GCD detection, the WoW API provides C_Spell.GetSpellCooldown which returns a SpellCooldownInfo structure. However, BCM's existing code doesn't show explicit isOnGCD field usage - instead, PROJECT.md documents that GCD filtering should use the isOnGCD field from GetSpellCooldown. The standard approach is to check spell ID 61304 (GCD dummy spell) or compare cooldown duration against GCD length (typically 1.5 seconds, modified by haste).

**Primary recommendation:** Follow BCM's existing cooldown detection pattern from CustomCooldownViewer.lua lines 104-112: check GetSpellCharges first for charge-based spells, fall back to GetSpellCooldown for regular spells, filter GCD using isOnGCD field, and update on SPELL_UPDATE_COOLDOWN/SPELL_UPDATE_CHARGES events.

## Standard Stack

### Core WoW APIs

| API | Purpose | Why Standard |
|-----|---------|--------------|
| C_Spell.GetSpellCooldown(spellID) | Get cooldown info with GCD flag | Modern API (Patch 11.0.0+), returns SpellCooldownInfo structure |
| C_Spell.GetSpellCharges(spellID) | Get charge spell info | Detects charge-based spells and recharge timers |
| GetSpellCooldown(spellID) | Legacy cooldown API | Deprecated in 11.0.0 - BCM uses C_Spell namespace |

### Supporting APIs

| API | Purpose | When to Use |
|-----|---------|-------------|
| C_Spell.GetSpellInfo(spellID) | Verify spell exists | Initial validation before setting up tracking |
| C_SpellBook.IsSpellInSpellBook(spellID) | Check if player knows spell | Used by BCM in CreateCustomIcon (line 58) |

### BCM Infrastructure (Already Exists)

| Component | Purpose | Location |
|-----------|---------|----------|
| BCDM:IsHideWhenOffCooldownEnabled(viewerName) | Check if hiding enabled for a bar | Core/Globals.lua:610 |
| BCDM.CooldownManagerViewerToDBViewer | Map viewer name to DB key | Core/Globals.lua:9-13 |
| BCDM:PrettyPrint(msg) | Error logging | Core/Globals.lua:37 |

**No external libraries needed** - WoW API and existing BCM infrastructure sufficient.

## Architecture Patterns

### Pattern 1: Event-Driven Cooldown Updates

**What:** Register for SPELL_UPDATE_COOLDOWN and SPELL_UPDATE_CHARGES events, update state in event handler.

**When to use:** All cooldown detection in BCM follows this pattern.

**Example from BCM:**
```lua
-- Source: Modules/CustomCooldownViewer.lua:72-113
customIcon:RegisterEvent("SPELL_UPDATE_COOLDOWN")
customIcon:RegisterEvent("PLAYER_ENTERING_WORLD")
customIcon:RegisterEvent("SPELL_UPDATE_CHARGES")

customIcon:SetScript("OnEvent", function(self, event, ...)
    if event == "SPELL_UPDATE_COOLDOWN" or event == "PLAYER_ENTERING_WORLD" or event == "SPELL_UPDATE_CHARGES" then
        local spellCharges = C_Spell.GetSpellCharges(spellId)
        if spellCharges then
            customIcon.Charges:SetText(tostring(spellCharges.currentCharges))
            customIcon.Cooldown:SetCooldown(spellCharges.cooldownStartTime, spellCharges.cooldownDuration)
        else
            local cooldownData = C_Spell.GetSpellCooldown(spellId)
            customIcon.Cooldown:SetCooldown(cooldownData.startTime, cooldownData.duration)
        end
    end
end)
```

**Key insight:** Check GetSpellCharges first, fall back to GetSpellCooldown if nil (non-charge spell).

### Pattern 2: Charge Spell Detection

**What:** Charge spells return non-nil from GetSpellCharges. Any charge recharging means "on cooldown".

**When to use:** Every spell check - charges are a special case of cooldowns.

**BCM's approach:**
```lua
-- Source: Modules/DisableAuraOverlay.lua:51-80
local function TryApplyChargeCooldown(cd, spellID)
    if not (C_Spell and C_Spell.GetSpellCharges) then return false end

    local chargeInfo = C_Spell.GetSpellCharges(spellID)
    if not chargeInfo then return false end

    -- chargeInfo exists = charge spell
    -- Use cooldownStartTime and cooldownDuration for recharge timer
    if type(chargeInfo) == "table" then
        local chargeStart = chargeInfo.cooldownStartTime or chargeInfo.chargeStartTime or chargeInfo.chargeStart
        local chargeDuration = chargeInfo.cooldownDuration or chargeInfo.chargeDuration

        if chargeStart and chargeDuration then
            cd:SetCooldown(chargeStart, chargeDuration)
        else
            ClearCooldown(cd)
        end
        return true
    end
    return false
end
```

**Detection logic for our phase:**
- If GetSpellCharges returns nil → not a charge spell
- If GetSpellCharges returns table with currentCharges < maxCharges → on cooldown (recharging)
- If currentCharges == maxCharges → off cooldown (all charges available)

### Pattern 3: GCD Filtering

**What:** Filter out GCD-only cooldowns so icons don't flicker during GCD.

**BCM's documented approach (from PROJECT.md:92-98):**
```lua
-- Source: .planning/PROJECT.md example
local isOnGCD = nil
pcall(function()
    local cdInfo = C_Spell.GetSpellCooldown(spellID)
    if cdInfo and cdInfo.isOnGCD == true then
        isOnGCD = true
    end
end)
```

**CONTEXT.md decisions:**
- GCD-only states do NOT count as "on cooldown"
- When spell triggers both GCD and real cooldown, immediately count as "on cooldown" (duration > GCD)
- Use isOnGCD field from GetSpellCooldown

### Pattern 4: Minimal pcall Protection

**What:** BCM uses pcall sparingly, only where API can throw.

**When to use:** Around SetCooldownFromDurationObject and when calling APIs with invalid IDs.

**BCM's pattern from DisableAuraOverlay.lua:58-62, 101-109:**
```lua
-- pcall around SetCooldownFromDurationObject (can throw)
local success = pcall(function()
    cd:SetCooldownFromDurationObject(chargeInfo, false)
end)
if success then return true end

-- pcall around GetSpellCooldown when ID might be invalid
local success = pcall(function()
    local info = C_Spell.GetSpellCooldown(spellID)
    if info and info.startTime and info.duration then
        cd:SetCooldown(info.startTime, info.duration)
    end
end)
```

**Not wrapped in pcall:** Simple existence checks, nil returns, table field access.

### Pattern 5: Fail-Show Error Handling

**What:** When errors occur, show the icon (fail-safe behavior).

**BCM's approach:** No explicit fail-hide found in codebase. Icons default to visible. API errors return nil, handled as "no cooldown" → icon shown.

**Rationale:** Better to show an icon incorrectly than hide a critical cooldown due to transient error.

### Anti-Patterns to Avoid

- **Polling in OnUpdate:** BCM uses event-driven updates, not frame:SetScript("OnUpdate"). OnUpdate is expensive.
- **Caching max charges:** CONTEXT.md explicitly says "Always re-check charge count each update" to handle talent/buff changes.
- **pcall everything:** BCM only wraps calls that can throw. Excessive pcall hurts performance.
- **GCD threshold hardcoding:** Don't check `duration <= 1.5` - use isOnGCD field which accounts for haste.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| GCD detection | Compare duration to 1.5s, check spell 61304 | Use isOnGCD field from GetSpellCooldown | Handles haste scaling, Blizzard maintains it |
| Charge spell detection | Track max charges manually | GetSpellCharges returns currentCharges/maxCharges | Handles talent changes, buff effects |
| Cooldown events | OnUpdate polling loop | SPELL_UPDATE_COOLDOWN event | Event fires when needed, OnUpdate is continuous overhead |
| Error handling | Complex try/catch system | Minimal pcall + nil checks | WoW Lua APIs return nil on error, simpler and faster |

**Key insight:** Blizzard's APIs handle the complexity (haste scaling, talent changes, buff effects). Trust the API, don't replicate its internal logic.

## Common Pitfalls

### Pitfall 1: GCD Flickering

**What goes wrong:** Icons hide/show rapidly during GCD because addon treats GCD as a real cooldown.

**Why it happens:** Every spell triggers GCD. If you hide icons when duration > 0 without checking isOnGCD, all spells on GCD will flicker.

**How to avoid:**
```lua
local cdInfo = C_Spell.GetSpellCooldown(spellID)
if cdInfo and cdInfo.isOnGCD then
    -- This is GCD only, NOT a real cooldown
    return false  -- Not on cooldown
end
-- Now check if real cooldown exists
return cdInfo and cdInfo.duration and cdInfo.duration > 0
```

**Warning signs:** User reports icons "flashing" when casting any spell.

### Pitfall 2: Charge Spell Detection Timing

**What goes wrong:** At max charges, spell briefly shows as "on cooldown" when it shouldn't.

**Why it happens:** GetSpellCharges returns non-nil even at max charges. Need to check currentCharges vs maxCharges.

**How to avoid:**
```lua
local chargeInfo = C_Spell.GetSpellCharges(spellID)
if chargeInfo then
    -- Charge spell - check if any charge is recharging
    if chargeInfo.currentCharges < chargeInfo.maxCharges then
        return true  -- On cooldown (recharging)
    else
        return false  -- Off cooldown (all charges available)
    end
end
```

**Warning signs:** Multi-charge spells hide when they have all charges available.

### Pitfall 3: Event Handler Performance

**What goes wrong:** SPELL_UPDATE_COOLDOWN with nil spellID fires frequently. Checking all spells every time kills performance.

**Why it happens:** Per Warcraft Wiki, "nil value indicates that all cooldowns should be updated, rather than just a specific one."

**How to avoid:**
```lua
-- Only process spells on bars with HideWhenOffCooldown enabled
if not BCDM:IsHideWhenOffCooldownEnabled(viewerName) then
    return  -- Feature disabled for this bar
end

-- If event provides spellID, only check that spell
if spellID then
    UpdateSingleSpell(spellID)
else
    -- nil = update all tracked spells
    UpdateAllTrackedSpells()
end
```

**Warning signs:** Frame rate drops when casting spells, high CPU usage in profiler.

### Pitfall 4: SPELL_UPDATE_COOLDOWN Doesn't Fire on Completion

**What goes wrong:** Icon stays hidden after cooldown finishes.

**Why it happens:** Per research, "this event does NOT fire when spells finish their cooldown!"

**How to avoid:** Also register for SPELL_UPDATE_CHARGES (fires on completion for charge spells). May need additional mechanism for regular cooldown completion detection. BCM's existing code suggests polling might be needed for completion, or hooking into ability usage events.

**Warning signs:** Icons hide when cooldown starts but don't reappear when ready.

### Pitfall 5: Invalid Spell IDs

**What goes wrong:** GetSpellCooldown returns nil, addon treats as "off cooldown" and hides icon for invalid spell.

**Why it happens:** Spell might not exist, player doesn't know it, or ID is wrong.

**How to avoid:**
```lua
-- Validate spell exists before tracking
if not C_Spell.GetSpellInfo(spellID) then
    -- Invalid spell ID - don't track
    return nil  -- Error state
end

-- In cooldown check
local cdInfo = C_Spell.GetSpellCooldown(spellID)
if not cdInfo then
    -- API error - fail-show (keep icon visible)
    return false  -- Treat as "off cooldown" so it shows
end
```

**Warning signs:** Specific spell icons never appear, regardless of cooldown state.

## Code Examples

### IsSpellOnCooldown Function (Complete Implementation)

```lua
-- Source: Based on BCM patterns and CONTEXT.md decisions
-- Location: Core/Globals.lua (add near other API functions)

function BCDM:IsSpellOnCooldown(spellID)
    if not spellID or spellID == 0 then
        return false  -- Invalid ID, fail-show
    end

    -- Validate spell exists
    if not C_Spell.GetSpellInfo(spellID) then
        return false  -- Unknown spell, fail-show
    end

    -- Check charge spells first
    local chargeInfo = C_Spell.GetSpellCharges(spellID)
    if chargeInfo then
        -- Charge spell: on cooldown if any charge is recharging
        -- currentCharges < maxCharges means at least one charge is recharging
        if chargeInfo.currentCharges and chargeInfo.maxCharges then
            return chargeInfo.currentCharges < chargeInfo.maxCharges
        end
        -- Fallback if fields missing
        return false
    end

    -- Regular spell cooldown check
    local cdInfo = C_Spell.GetSpellCooldown(spellID)
    if not cdInfo then
        return false  -- API error, fail-show
    end

    -- Filter out GCD-only states
    if cdInfo.isOnGCD then
        return false  -- GCD doesn't count as cooldown
    end

    -- Check if real cooldown exists
    if cdInfo.duration and cdInfo.duration > 0 then
        return true  -- On cooldown
    end

    return false  -- Off cooldown
end
```

### Event-Driven State Update Pattern

```lua
-- Source: Based on CustomCooldownViewer.lua pattern
-- For use in Phase 3 when hooking icon updates

local function UpdateSpellVisibility(icon, spellID)
    local viewerName = icon:GetParent():GetName()

    -- Only run detection if feature enabled for this bar
    if not BCDM:IsHideWhenOffCooldownEnabled(viewerName) then
        icon:SetAlpha(1)  -- Feature disabled, show all icons
        return
    end

    -- Check cooldown state
    local isOnCooldown = BCDM:IsSpellOnCooldown(spellID)

    -- Set visibility: hide if off cooldown, show if on cooldown
    if isOnCooldown then
        icon:SetAlpha(1)  -- On cooldown, show
    else
        icon:SetAlpha(0)  -- Off cooldown, hide
    end
end

-- Register on icon creation
icon:RegisterEvent("SPELL_UPDATE_COOLDOWN")
icon:RegisterEvent("SPELL_UPDATE_CHARGES")
icon:SetScript("OnEvent", function(self, event, eventSpellID)
    -- If event provides specific spell, only update if it matches
    if eventSpellID and eventSpellID ~= spellID then
        return
    end
    UpdateSpellVisibility(self, spellID)
end)
```

### Charge Spell Detection Detail

```lua
-- Example showing charge state detection logic
-- Source: Based on GetSpellCharges API structure

local function GetChargeState(spellID)
    local chargeInfo = C_Spell.GetSpellCharges(spellID)

    if not chargeInfo then
        return "not_charge_spell"
    end

    -- chargeInfo structure (typical):
    -- {
    --     currentCharges = 2,
    --     maxCharges = 2,
    --     cooldownStartTime = GetTime() - 5,
    --     cooldownDuration = 20
    -- }

    if chargeInfo.currentCharges >= chargeInfo.maxCharges then
        return "all_charges_available"  -- Off cooldown
    else
        return "recharging"  -- On cooldown
    end
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| GetSpellCooldown(spellID) | C_Spell.GetSpellCooldown(spellID) | Patch 11.0.0 (July 2024) | New API returns structured table, includes isOnGCD field |
| Duration comparison for GCD | Use isOnGCD field | Patch 11.0.0 | Handles haste scaling automatically |
| Polling with OnUpdate | Event-driven with SPELL_UPDATE_COOLDOWN | Always best practice | Massive performance improvement |
| Manual GCD spell check (61304) | isOnGCD field | Patch 11.0.0 | Simpler, more reliable |

**Deprecated/outdated:**
- GetSpellCooldown (global): Removed in Patch 11.0.0, use C_Spell.GetSpellCooldown
- GetSpellCharges (global): Still exists but C_Spell.GetSpellCharges preferred for consistency
- Hardcoded 1.5s GCD checks: Doesn't account for haste, use isOnGCD field

**BCM's current state:** Already uses modern C_Spell API throughout (lines 104-112 in CustomCooldownViewer.lua, lines 52-109 in DisableAuraOverlay.lua). No migration needed.

## Open Questions

### 1. SPELL_UPDATE_COOLDOWN Completion Detection

**What we know:** SPELL_UPDATE_COOLDOWN fires when cooldown *starts* but NOT when it *finishes*.

**What's unclear:** How to detect cooldown completion for regular (non-charge) spells reliably.

**Recommendation:**
- Option A: Add UNIT_SPELLCAST_SUCCEEDED listener to detect spell usage (cooldown definitely finished)
- Option B: Minimal OnUpdate with throttling (check every 0.5s) for edge case detection
- Option C: Accept limitation - icons update when next SPELL_UPDATE_COOLDOWN fires (good enough for v1)

**Planner should:** Start with Option C (simplest), add Option A if users report issues.

### 2. GCD isOnGCD Field Reliability

**What we know:** PROJECT.md documents isOnGCD field. Web search confirms spell 61304 is GCD dummy spell but doesn't confirm isOnGCD field usage.

**What's unclear:** Whether isOnGCD field exists in all WoW versions BCM supports, or if it's retail-only.

**Recommendation:** Implement isOnGCD check with fallback to duration-based detection (duration <= 1.5). Add logging if isOnGCD is nil to detect in testing.

```lua
if cdInfo.isOnGCD then
    return false
elseif cdInfo.isOnGCD == nil then
    -- Fallback: GCD is typically 1.5s or less
    -- This is less accurate but covers older clients
    BCDM:PrettyPrint("Warning: isOnGCD field not available")
    return cdInfo.duration > 1.5
end
```

**Planner should:** Test on user's WoW version, add fallback if needed.

### 3. Performance Impact Measurement

**What we know:** BCM already tracks cooldowns. Adding IsSpellOnCooldown checks should be minimal overhead.

**What's unclear:** Actual performance impact when feature is enabled on multiple bars with many spells.

**Recommendation:** Phase 2 creates the detection function. Phase 3 integrates it and can measure impact. If issues arise, add caching with TTL (cache result for 0.1s, refresh on events).

**Planner should:** Note that optimization can be deferred to Phase 3 or later.

## Sources

### Primary (HIGH confidence)

- BCM Codebase Analysis:
  - /home/sntanavaras/random-projects/BetterCooldownManager/Modules/CustomCooldownViewer.lua (lines 72-113): Event-driven cooldown updates
  - /home/sntanavaras/random-projects/BetterCooldownManager/Modules/DisableAuraOverlay.lua (lines 51-109): Charge spell and pcall patterns
  - /home/sntanavaras/random-projects/BetterCooldownManager/Core/Globals.lua (lines 9-13, 610-613): API infrastructure
  - .planning/PROJECT.md (lines 85-113): Documented GCD detection approach

### Secondary (MEDIUM confidence)

- [C_Spell.GetSpellCooldown - Warcraft Wiki](https://warcraft.wiki.gg/wiki/API_C_Spell.GetSpellCooldown) - API signature (WebSearch, wiki inaccessible via WebFetch)
- [SPELL_UPDATE_COOLDOWN - Warcraft Wiki](https://warcraft.wiki.gg/wiki/SPELL_UPDATE_COOLDOWN) - Event documentation
- [GetSpellCharges - Warcraft Wiki](https://warcraft.wiki.gg/wiki/API_GetSpellCharges) - Charge spell API
- Community patterns from [Ready Cooldown Alert](https://www.curseforge.com/wow/addons/readycooldownalert) and [PingCooldowns](https://github.com/Jacuv01/PingCooldowns) addons

### Tertiary (LOW confidence)

- WebSearch results about WoW addon development practices (general patterns, not specific to APIs)
- Forum discussions about GCD detection approaches (pre-11.0.0 methods may be outdated)

## Metadata

**Confidence breakdown:**
- API usage patterns: HIGH - Verified in BCM codebase, consistent across multiple files
- GCD detection: MEDIUM - isOnGCD field documented in PROJECT.md but not verified in live code
- Event handling: HIGH - BCM extensively uses SPELL_UPDATE_COOLDOWN throughout codebase
- Error handling: HIGH - Clear patterns in DisableAuraOverlay.lua and minimal pcall usage

**Research date:** 2026-02-04
**Valid until:** 30 days (WoW APIs are stable, Patch 11.0.0 changes already adopted by BCM)

**Phase 2 scope verification:**
- Creates IsSpellOnCooldown(spellID) function: YES
- Handles charge spells correctly: YES (check currentCharges < maxCharges)
- Filters GCD-only states: YES (use isOnGCD field)
- pcall protection scope: YES (minimal, only where API can throw)
- Event-driven updates: YES (SPELL_UPDATE_COOLDOWN, SPELL_UPDATE_CHARGES)
- Performance optimization: PARTIAL (conditional execution if feature enabled, full optimization deferred to Phase 3)

**Dependencies on earlier phases:**
- Phase 1 (Settings Infrastructure): COMPLETE - BCDM:IsHideWhenOffCooldownEnabled() exists and tested
- No external dependencies

**Outputs for next phase:**
- Phase 3 will consume BCDM:IsSpellOnCooldown(spellID) function
- Phase 3 will integrate with existing event handlers in BCM viewers
