# BetterCooldownManager - Hide Spells When Off Cooldown

## Project Overview

Add a per-bar option to hide spells that are not currently on cooldown. When a spell comes off cooldown, it should instantly disappear from the bar, and remaining icons should collapse to fill the gap.

## Requirements

### Core Feature
- **Per-bar toggle**: Each CDM bar (Essential, Utility, Custom, etc.) can individually enable/disable this feature
- **Instant hide**: When a spell comes off cooldown, hide it immediately (no fade)
- **Collapse layout**: Remaining visible spells shift to fill gaps left by hidden spells
- **Alpha-based hiding**: Setting alpha to 0 is acceptable (simplest approach for v1)

### Scope
- Applies to BCM's cooldown manager bars: Essential, Utility, Custom, etc.
- Does NOT apply to WoW's native action bars
- Does NOT apply to buff/aura icon bars (those already have separate logic)

## Research Findings

### Existing Addon Analysis

#### ArcUI (v3.4.5)
- Has dynamic layout collapsing for aura icons, but NOT for regular CDM spell bars
- Uses `cooldownStateVisuals.cooldownState.alpha` - if ≤ 0.01, icon treated as invisible
- Key insight: `IsIconInvisible()` checks alpha to determine gaps for collapsing
- Uses Duration API with `pcall()` wrappers for WoW 12.0 compatibility
- Relevant files:
  - `CDM_Module/CDM_Enhance/ArcUI_CooldownState.lua` - cooldown state visuals
  - `CDM_Module/CDM_Groups/ArcUI_CDMGroups_DynamicLayout.lua` - layout collapsing

#### CooldownManagerCustomizer
- Hooks `C_CooldownViewer.GetCooldownViewerCategorySet` to filter spells
- Uses STATIC hiding (user manually toggles), not dynamic cooldown-based
- Key pattern for filtering spells from CDM:
```lua
local originalGetCategorySet = C_CooldownViewer.GetCooldownViewerCategorySet
local function HookedGetCooldownViewerCategorySet(category)
    local results = { originalGetCategorySet(category) }
    -- Filter spells...
    return filteredIDsTable
end
C_CooldownViewer.GetCooldownViewerCategorySet = HookedGetCooldownViewerCategorySet
```
- Refresh viewers after changes:
```lua
local viewerNames = {"EssentialCooldownViewer", "UtilityCooldownViewer", "BuffIconCooldownViewer", "BuffBarCooldownViewer"}
for _, frameName in ipairs(viewerNames) do
    local frame = _G[frameName]
    if frame and frame.RefreshLayout then
        frame:RefreshLayout()
    end
end
```

#### TweaksUI: Cooldowns
- Does NOT have "hide when off cooldown" feature for CDM bars

#### WildUI
- Still in beta, no downloadable files

### WoW 12.0 (Midnight) API Restrictions

**Key Changes:**
- "Black box" API design limits addon access to combat information
- Addons can modify visual presentation but cannot inject/extract gameplay logic
- Duration objects have "secret" values that cannot be directly compared
- Must use `pcall()` for cooldown API calls due to potential errors

**What Still Works:**
- `C_Spell.GetSpellCooldown(spellID)` - returns cooldown info
- `C_Spell.GetSpellCooldownDuration(spellID)` - returns Duration object
- `C_Spell.GetSpellCharges(spellID)` - returns charge info
- `C_Spell.GetSpellChargeDuration(spellID)` - returns Duration object for charges
- `Duration:EvaluateRemainingPercent(curve)` - evaluate remaining time against curve
- Frame alpha manipulation (SetAlpha, Show/Hide)
- RefreshLayout on CDM viewers

**Recommended Pattern (from ArcUI):**
```lua
local function GetSpellCooldownState(spellID)
    if not spellID then return nil, nil, false, nil end

    local chargeInfo = nil
    local isChargeSpell = false
    pcall(function()
        chargeInfo = C_Spell.GetSpellCharges(spellID)
        isChargeSpell = chargeInfo ~= nil
    end)

    local isOnGCD = nil
    pcall(function()
        local cdInfo = C_Spell.GetSpellCooldown(spellID)
        if cdInfo and cdInfo.isOnGCD == true then
            isOnGCD = true
        end
    end)

    local durationObj = nil
    pcall(function()
        durationObj = C_Spell.GetSpellCooldownDuration(spellID)
    end)

    local chargeDurObj = nil
    if isChargeSpell then
        pcall(function()
            chargeDurObj = C_Spell.GetSpellChargeDuration(spellID)
        end)
    end

    return isOnGCD, durationObj, isChargeSpell, chargeDurObj
end
```

## Implementation Approach

### Option A: Alpha-Based Hiding (Recommended for v1)
1. Hook into CDM's icon update cycle
2. Check if spell is on cooldown using `C_Spell.GetSpellCooldownDuration()`
3. If Duration is nil/zero (off cooldown), set icon alpha to 0
4. If Duration exists (on cooldown), set icon alpha to 1
5. Call `RefreshLayout()` to trigger collapse

**Pros:**
- Simple, follows existing patterns (ArcUI uses similar approach)
- Works with existing CDM layout system
- No need to filter at the API level

**Cons:**
- Icons still exist in memory, just invisible

### Option B: API Hooking (More Complex)
1. Hook `C_CooldownViewer.GetCooldownViewerCategorySet`
2. Filter out spells that are off cooldown before returning
3. CDM naturally excludes them

**Pros:**
- True removal from the bar

**Cons:**
- Need to continuously re-check and refresh
- More complex state management
- Risk of taint issues

### Recommended: Option A for v1
Use alpha-based hiding as it's simpler and proven to work (ArcUI pattern). Can upgrade to Option B later if needed.

## Technical Implementation Plan

### Phase 1: Core Infrastructure
1. Add per-bar setting: `hideWhenOffCooldown` (boolean, default false)
2. Create function to check if spell is on cooldown
3. Hook into icon update cycle

### Phase 2: Alpha-Based Hiding
1. In icon update, check cooldown state
2. Set alpha based on cooldown (0 when off, normal when on)
3. Mark icon as "invisible" for layout purposes

### Phase 3: Layout Collapse
1. Integrate with existing layout system
2. When calculating positions, skip icons with alpha ≤ 0.01
3. Shift remaining icons to fill gaps

### Phase 4: Per-Bar Configuration
1. Add UI toggle in bar settings
2. Store setting in saved variables
3. Apply setting per-viewer

## Key APIs

| API | Purpose |
|-----|---------|
| `C_Spell.GetSpellCooldownDuration(spellID)` | Get Duration object for cooldown |
| `C_Spell.GetSpellCooldown(spellID)` | Get cooldown info (includes isOnGCD) |
| `C_Spell.GetSpellCharges(spellID)` | Get charge spell info |
| `frame:SetAlpha(value)` | Control icon visibility |
| `viewer:RefreshLayout()` | Trigger layout recalculation |

## Risk Mitigation

1. **WoW 12.0 API Issues**: Wrap all Duration API calls in `pcall()`
2. **Taint**: Use frame alpha manipulation instead of direct API hooking
3. **Performance**: Only check cooldown state when needed (on cooldown events)
4. **GCD Flickering**: Filter out GCD-only cooldowns (check `isOnGCD` flag)

## Success Criteria

- [ ] Per-bar toggle to enable/disable feature
- [ ] Spells instantly hidden when off cooldown
- [ ] Remaining icons collapse to fill gaps
- [ ] No flickering during GCD
- [ ] Works in WoW 12.0 (Midnight) without errors
- [ ] Settings persist across sessions
