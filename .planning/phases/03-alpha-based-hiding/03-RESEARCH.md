# Phase 3: Alpha-Based Hiding - Research

**Researched:** 2026-02-04
**Domain:** WoW UI Frame Alpha Manipulation / Cooldown Icon Visibility
**Confidence:** HIGH

## Summary

This phase implements icon visibility toggling based on cooldown state. Research investigated the Blizzard CooldownViewer icon structure, event-driven update mechanisms, alpha manipulation patterns, and integration with the existing BCM codebase.

The key finding is that Blizzard's CooldownViewer icons store spell information in a `cooldownInfo` field (containing `spellID` and `overrideSpellID`), which BCM already accesses in `DisableAuraOverlay.lua:40-42`. This allows direct spell ID lookup for any icon in Essential/Utility viewers. For alpha-based hiding, the WoW API `frame:SetAlpha(0)` hides all child elements (icon texture, cooldown spiral, text) when applied to the parent frame. The pattern is well-established in WoW addon development.

For update timing, `SPELL_UPDATE_COOLDOWN` fires when cooldowns start but NOT when they finish. This requires either polling via OnUpdate, hooking into `RefreshLayout`, or using a combination approach. BCM already hooks `RefreshLayout` on Essential/Utility viewers for centering icons (CooldownManager.lua:386-387), providing a proven integration point.

**Primary recommendation:** Hook into each viewer's `RefreshLayout` method to apply alpha changes after Blizzard recalculates positions. Use `SPELL_UPDATE_COOLDOWN` and `SPELL_UPDATE_CHARGES` events for immediate show transitions (cooldown starts), with `RefreshLayout` hook handling all hide transitions when Blizzard detects cooldown completion.

## Standard Stack

### Core WoW APIs (Already in BCM)

| API | Purpose | Why Standard |
|-----|---------|--------------|
| `frame:SetAlpha(value)` | Control visibility (0=hidden, 1=visible) | Native WoW API, affects all children |
| `frame.cooldownInfo.spellID` | Get spell ID from Blizzard icon | BCM already uses this pattern (DisableAuraOverlay.lua:40-42) |
| `BCDM:IsSpellOnCooldown(spellID)` | Check cooldown state | Phase 2 deliverable, handles GCD filtering and charge spells |
| `hooksecurefunc(viewer, "RefreshLayout", fn)` | Hook into layout updates | BCM already uses this pattern (CooldownManager.lua:386-387) |

### Supporting APIs (Already in BCM)

| API | Purpose | When to Use |
|-----|---------|-------------|
| `SPELL_UPDATE_COOLDOWN` event | Detect when cooldown starts | For immediate show on cooldown start |
| `SPELL_UPDATE_CHARGES` event | Detect charge changes | For charge spell visibility updates |
| `BCDM:IsHideWhenOffCooldownEnabled(viewerName)` | Check per-bar setting | Phase 1 deliverable, guards feature per bar |
| `C_Timer.After(delay, fn)` | Schedule delayed checks | For edge case handling after events |

### No External Libraries Needed

BCM already has all required infrastructure from Phase 1 (settings) and Phase 2 (detection).

## Architecture Patterns

### Pattern 1: RefreshLayout Hook for Hide/Show Updates

**What:** Hook into Blizzard's `RefreshLayout` method on each viewer to apply alpha changes after layout recalculation.

**When to use:** Primary integration point for alpha visibility updates.

**Why this works:** RefreshLayout is called by Blizzard whenever icons change (cooldown starts, cooldown ends, spell learned/unlearned, etc.). BCM already hooks this for centering functionality.

**Example:**
```lua
-- Source: Based on CooldownManager.lua:386-387 existing pattern
local function UpdateIconVisibility(viewerName)
    local viewer = _G[viewerName]
    if not viewer then return end

    -- Check if feature enabled for this bar
    if not BCDM:IsHideWhenOffCooldownEnabled(viewerName) then return end

    for _, icon in ipairs({ viewer:GetChildren() }) do
        if icon and icon.cooldownInfo then
            local spellID = icon.cooldownInfo.overrideSpellID or icon.cooldownInfo.spellID
            if spellID then
                local isOnCooldown = BCDM:IsSpellOnCooldown(spellID)
                icon:SetAlpha(isOnCooldown and 1 or 0)
            end
        end
    end
end

-- Hook into RefreshLayout (called when layout changes)
if EssentialCooldownViewer and EssentialCooldownViewer.RefreshLayout then
    hooksecurefunc(EssentialCooldownViewer, "RefreshLayout", function()
        UpdateIconVisibility("EssentialCooldownViewer")
    end)
end
```

### Pattern 2: Event-Driven Immediate Show

**What:** Register for cooldown events to immediately show icons when cooldown starts.

**When to use:** For responsive feedback when player uses ability.

**Why needed:** RefreshLayout may not fire immediately when cooldown starts (event-to-layout delay). Direct event handling ensures instant show.

**Example:**
```lua
-- Source: Based on CustomCooldownViewer.lua:102-113 event pattern
local function SetupCooldownEvents()
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    eventFrame:RegisterEvent("SPELL_UPDATE_CHARGES")
    eventFrame:SetScript("OnEvent", function(_, event, eventSpellID, ...)
        -- Update all viewers with HideWhenOffCooldown enabled
        for _, viewerName in ipairs(BCDM.CooldownManagerViewers) do
            if BCDM:IsHideWhenOffCooldownEnabled(viewerName) then
                UpdateIconVisibility(viewerName)
            end
        end
    end)
end
```

### Pattern 3: Getting Spell ID from Blizzard Icons

**What:** Access the `cooldownInfo` field on Blizzard CooldownViewer icons.

**When to use:** Every time you need the spell ID for an Essential/Utility icon.

**Verified pattern from BCM:**
```lua
-- Source: Modules/DisableAuraOverlay.lua:40-42 (HIGH confidence - existing BCM code)
local function GetSpellID(frame)
    local info = frame and frame.cooldownInfo
    return info and (info.overrideSpellID or info.spellID)
end
```

**Key insight:** `overrideSpellID` takes precedence when present (for talent overrides, empowered spells, etc.).

### Pattern 4: Alpha on Parent Frame

**What:** Set alpha on the icon's root frame to hide all child elements at once.

**When to use:** Always - don't set alpha on individual textures.

**Why:** Per CONTEXT.md decision: "Hide everything together: icon, cooldown spiral, and text (set alpha on parent frame)"

**Example:**
```lua
-- CORRECT: Set alpha on parent frame
icon:SetAlpha(0)  -- Hides Icon, Cooldown spiral, ChargeCount text, etc.

-- WRONG: Setting alpha on individual elements
icon.Icon:SetAlpha(0)      -- Don't do this
icon.Cooldown:SetAlpha(0)  -- Don't do this
```

### Anti-Patterns to Avoid

- **OnUpdate polling:** Performance cost is too high for this use case. Use event-driven + RefreshLayout hook instead.
- **Setting alpha on child elements:** Always set on parent frame to hide all children together.
- **Caching spell visibility state:** Per CONTEXT.md, always re-check cooldown state each update for talent/buff changes.
- **Ignoring overrideSpellID:** Some spells have override IDs from talents - always check both.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Spell ID lookup from icon | Manual frame inspection | `frame.cooldownInfo.spellID` | BCM already uses this (DisableAuraOverlay.lua) |
| Cooldown state detection | Custom cooldown logic | `BCDM:IsSpellOnCooldown()` | Phase 2 handles GCD filtering, charges, edge cases |
| Per-bar setting check | Direct DB access | `BCDM:IsHideWhenOffCooldownEnabled()` | Phase 1 API, handles viewer-to-DB mapping |
| Layout update timing | Manual timer system | Hook `RefreshLayout` | Blizzard already manages when layout needs update |
| Charge spell detection | Manual charge tracking | Phase 2 handles inside `IsSpellOnCooldown` | Already handles currentCharges < maxCharges |

**Key insight:** Phases 1 and 2 built the detection infrastructure. Phase 3 is primarily about integration and alpha manipulation.

## Common Pitfalls

### Pitfall 1: SPELL_UPDATE_COOLDOWN Doesn't Fire on Completion

**What goes wrong:** Icons stay hidden after cooldown finishes because no event fires.

**Why it happens:** Per [Wowpedia documentation](https://wowpedia.fandom.com/wiki/SPELL_UPDATE_COOLDOWN): "this event does NOT fire when spells finish their cooldown!"

**How to avoid:** Hook into `RefreshLayout` which Blizzard calls when cooldown visual state changes. The hook will catch cooldown completion because Blizzard's internal logic triggers `RefreshLayout` when updating icon displays.

**Warning signs:** User reports icons not reappearing after cooldown ends.

### Pitfall 2: Alpha Change Not Affecting All Children

**What goes wrong:** Icon hides but cooldown spiral or text remains visible.

**Why it happens:** SetAlpha was called on a child element instead of parent frame.

**How to avoid:** Always call `SetAlpha()` on the icon frame itself (the parent), not on `icon.Icon`, `icon.Cooldown`, or other children.

**Warning signs:** Partial visibility - some elements visible when icon should be completely hidden.

### Pitfall 3: Override Spell IDs Ignored

**What goes wrong:** Spell shows as "not on cooldown" even when it is, because wrong spell ID is checked.

**Why it happens:** Talent overrides create new spell IDs. The `overrideSpellID` field takes precedence.

**How to avoid:**
```lua
-- Always check overrideSpellID first
local spellID = icon.cooldownInfo.overrideSpellID or icon.cooldownInfo.spellID
```

**Warning signs:** Specific talent-empowered spells don't hide/show correctly.

### Pitfall 4: Bar Opacity Interaction

**What goes wrong:** Hidden icons (alpha=0) still block or interact with bar fade effects.

**Why it happens:** Multiple alpha sources can compound (icon alpha * bar alpha).

**How to avoid (Claude's Discretion area):** Hidden icons at alpha=0 should not interfere with bar-level opacity. If bar has opacity=0.5, visible icons show at 0.5, hidden icons stay at 0 (0 * anything = 0). No special handling needed unless bar wants to ignore hidden icons for layout purposes (Phase 4 territory).

### Pitfall 5: Combat Lockdown

**What goes wrong:** Alpha changes fail or cause errors during combat.

**Why it happens:** SetAlpha is NOT protected, but some operations triggered indirectly might be.

**How to avoid:** BCM already gates many operations with `if InCombatLockdown() then return end`. Alpha manipulation itself is safe, but avoid triggering protected operations from the same code path.

**Warning signs:** Lua errors in combat, UI taint warnings.

## Code Examples

### Complete Icon Visibility Update Function

```lua
-- Source: Synthesized from BCM patterns (DisableAuraOverlay.lua, CooldownManager.lua)
-- Location: Recommended for new file Modules/HideWhenOffCooldown.lua

local function UpdateIconVisibility(viewerName)
    local viewer = _G[viewerName]
    if not viewer then return end

    -- Check if feature enabled for this bar
    if not BCDM:IsHideWhenOffCooldownEnabled(viewerName) then
        -- Feature disabled - ensure all icons are visible
        for _, icon in ipairs({ viewer:GetChildren() }) do
            if icon and icon.cooldownInfo then
                icon:SetAlpha(1)
            end
        end
        return
    end

    -- Feature enabled - apply visibility based on cooldown state
    for _, icon in ipairs({ viewer:GetChildren() }) do
        if icon and icon.cooldownInfo then
            -- Get spell ID (prefer override for talent-modified spells)
            local spellID = icon.cooldownInfo.overrideSpellID or icon.cooldownInfo.spellID

            if spellID and spellID ~= 0 then
                -- Use Phase 2's detection function
                local isOnCooldown = BCDM:IsSpellOnCooldown(spellID)
                -- Set alpha: 1 if on cooldown (show), 0 if off cooldown (hide)
                icon:SetAlpha(isOnCooldown and 1 or 0)
            else
                -- No valid spell ID - fail-show (don't hide)
                icon:SetAlpha(1)
            end
        end
    end
end
```

### Event Frame Setup

```lua
-- Source: Based on CustomCooldownViewer.lua event registration pattern
local function SetupHideWhenOffCooldownEvents()
    local eventFrame = CreateFrame("Frame", "BCDM_HideWhenOffCooldownFrame")

    eventFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    eventFrame:RegisterEvent("SPELL_UPDATE_CHARGES")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")

    eventFrame:SetScript("OnEvent", function(_, event, ...)
        -- Spec change: re-evaluate all icons (spells may have changed)
        -- Cooldown/charges update: check visibility state
        for _, viewerName in ipairs(BCDM.CooldownManagerViewers) do
            -- Only Essential and Utility per Phase 1 scope
            if viewerName == "EssentialCooldownViewer" or viewerName == "UtilityCooldownViewer" then
                UpdateIconVisibility(viewerName)
            end
        end
    end)

    return eventFrame
end
```

### RefreshLayout Hook Integration

```lua
-- Source: Based on CooldownManager.lua:386-387 existing hook pattern
local function SetupRefreshLayoutHooks()
    -- Hook EssentialCooldownViewer
    if EssentialCooldownViewer and EssentialCooldownViewer.RefreshLayout then
        hooksecurefunc(EssentialCooldownViewer, "RefreshLayout", function()
            UpdateIconVisibility("EssentialCooldownViewer")
        end)
    end

    -- Hook UtilityCooldownViewer
    if UtilityCooldownViewer and UtilityCooldownViewer.RefreshLayout then
        hooksecurefunc(UtilityCooldownViewer, "RefreshLayout", function()
            UpdateIconVisibility("UtilityCooldownViewer")
        end)
    end
end
```

### Charge Spell Visibility (Reference)

```lua
-- Note: This is handled by BCDM:IsSpellOnCooldown from Phase 2
-- Included for reference on how charge visibility works

-- Phase 2's IsSpellOnCooldown handles charges:
-- - currentCharges < maxCharges -> on cooldown (show icon)
-- - currentCharges == maxCharges -> off cooldown (hide icon)

-- Example for a 2-charge spell like Roll:
-- Charges: 2/2 -> IsSpellOnCooldown returns false -> hide
-- Charges: 1/2 -> IsSpellOnCooldown returns true -> show (recharging)
-- Charges: 0/2 -> IsSpellOnCooldown returns true -> show (both recharging)
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| OnUpdate polling for cooldowns | Event-driven + RefreshLayout hook | Best practice | Massive performance improvement |
| Hide individual textures | SetAlpha on parent frame | Always best practice | Ensures all children hidden together |
| Check only base spellID | Check overrideSpellID first | Talent system changes | Handles talent overrides correctly |
| Manual cooldown detection | Use Phase 2 IsSpellOnCooldown | Phase 2 completion | Centralized GCD/charge handling |

**Deprecated/outdated:**
- OnUpdate polling for cooldown state (performance cost too high)
- Direct alpha on textures instead of frames (leaves children visible)
- Ignoring `overrideSpellID` field (breaks talent-modified spells)

## Open Questions

### 1. RefreshLayout Timing Consistency

**What we know:** RefreshLayout is called by Blizzard when layout needs update. BCM already hooks it successfully.

**What's unclear:** Exact timing - does it fire immediately on cooldown completion or with delay?

**Recommendation:** Implement with RefreshLayout hook as primary mechanism. If user reports delay in showing, add `C_Timer.After(0.1, UpdateIconVisibility)` after events as fallback. Test in-game to verify.

### 2. Buff Bar Icons

**What we know:** Phase 1 scope limited to Essential and Utility bars. BuffIconCooldownViewer uses different logic (buff tracking, not cooldowns).

**What's unclear:** Whether BuffIconCooldownViewer icons have same `cooldownInfo` structure.

**Recommendation:** Skip BuffIconCooldownViewer for Phase 3 per scope. Can be added in future phase if requested.

### 3. Custom/Item/Trinket Bars

**What we know:** BCM has Custom, AdditionalCustom, Item, Trinket, and ItemSpell bars that manage their own icons differently (CreateFrame-based, not Blizzard templates).

**What's unclear:** Whether these bars should support HideWhenOffCooldown in Phase 3.

**Recommendation:** Per Phase 1 decision: "Essential and Utility bars only. Custom/Item/Trinket bars deferred to future phases." These custom bars create their own icons via CreateFrame, so they would need different integration patterns.

## Sources

### Primary (HIGH confidence)

- BCM Codebase Analysis:
  - `/home/sntanavaras/random-projects/BetterCooldownManager/Modules/DisableAuraOverlay.lua` (lines 40-42): GetSpellID pattern using cooldownInfo
  - `/home/sntanavaras/random-projects/BetterCooldownManager/Modules/CooldownManager.lua` (lines 386-387): RefreshLayout hook pattern
  - `/home/sntanavaras/random-projects/BetterCooldownManager/Modules/CooldownManager.lua` (lines 195-218): Iterating viewer children
  - `/home/sntanavaras/random-projects/BetterCooldownManager/Core/Globals.lua` (lines 629-674): IsSpellOnCooldown from Phase 2
  - `/home/sntanavaras/random-projects/BetterCooldownManager/Core/Globals.lua` (lines 610-613): IsHideWhenOffCooldownEnabled from Phase 1

### Secondary (MEDIUM confidence)

- [SPELL_UPDATE_COOLDOWN - Wowpedia](https://wowpedia.fandom.com/wiki/SPELL_UPDATE_COOLDOWN) - Event does NOT fire on cooldown completion
- [UIObject SetAlpha - WoWWiki](https://wowwiki-archive.fandom.com/wiki/API_UIObject_SetAlpha) - SetAlpha API documentation
- [hooksecurefunc - AddOn Studio](https://addonstudio.org/wiki/WoW:API_hooksecurefunc) - Hook function documentation
- [WoW Midnight API Changes](https://warcraft.wiki.gg/wiki/Patch_12.0.0/API_changes) - API restrictions (SetAlpha remains unrestricted)

### Tertiary (LOW confidence)

- WebSearch results about OnUpdate vs event-driven patterns
- Community addon patterns (ArcUI, CooldownManagerCustomizer) - general approach validation

## Metadata

**Confidence breakdown:**
- Icon structure access: HIGH - Verified in BCM's DisableAuraOverlay.lua
- Alpha manipulation: HIGH - Standard WoW API, extensively documented
- Event handling: HIGH - BCM already uses SPELL_UPDATE_COOLDOWN/CHARGES pattern
- RefreshLayout integration: HIGH - BCM already hooks this successfully
- Cooldown completion detection: MEDIUM - RefreshLayout should work, may need fallback

**Research date:** 2026-02-04
**Valid until:** 30 days (patterns are stable, WoW 12.x API changes already adopted)

**Phase 3 scope verification:**
- Hook into icon update cycle: YES (RefreshLayout hook + event frame)
- Check bar's hideWhenOffCooldown setting: YES (Phase 1 API)
- Set icon alpha to 0 when spell off cooldown: YES (frame:SetAlpha(0))
- Set icon alpha to normal when spell on cooldown: YES (frame:SetAlpha(1))
- Charge spell handling: YES (Phase 2 IsSpellOnCooldown handles this)
- Instant alpha change (no animation): YES (per CONTEXT.md decision)
- Hide parent frame (icon + cooldown + text): YES (SetAlpha on parent)

**Dependencies verified:**
- Phase 1: HideWhenOffCooldown setting and API - COMPLETE
- Phase 2: IsSpellOnCooldown detection function - COMPLETE

**Outputs for next phase:**
- Phase 4 will handle layout collapse (shifting icons to fill gaps)
- Phase 3 only sets alpha; Phase 4 will add logic to skip alpha=0 icons in layout calculation
