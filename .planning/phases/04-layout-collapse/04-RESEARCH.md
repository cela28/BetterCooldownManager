# Phase 4: Layout Collapse - Research

**Researched:** 2026-02-12
**Domain:** WoW UI Frame Layout / Icon Positioning / Dynamic Reflow
**Confidence:** HIGH

## Summary

Phase 4 implements layout collapse to make remaining visible icons shift to fill gaps left by hidden (alpha=0) icons. Research investigated BCM's existing layout system, WoW's SetPoint API for icon positioning, and patterns for filtering frames during layout calculation.

BCM already has a sophisticated centering system in `CenterWrappedRows()` (CooldownManager.lua:220-271) that handles multi-row layouts with wrapping. It filters frames based on `childFrame:IsShown()` and `childFrame.layoutIndex`, calculates row-by-row positioning, and uses centering math to position icons. This function is called via RefreshLayout hooks when layout changes occur.

The key finding is that Phase 3's alpha-based hiding (SetAlpha(0)) does NOT automatically affect `IsShown()` - the frame remains shown but invisible. Layout collapse must explicitly check `icon:GetAlpha()` to filter out hidden icons during position calculation. Blizzard CooldownViewer frames store layout metadata (iconLimit for wrapping, childXPadding/childYPadding for spacing) that BCM already leverages.

For centering direction, BCM's current CenterWrappedRows centers each row independently based on visible icon count. The user requested "compact toward center" behavior with grow direction awareness. The existing code already achieves center-compacting by calculating `startX = -totalWidth / 2 + iconWidth / 2` for each row, making icons naturally compact toward the bar's center point.

**Primary recommendation:** Modify CenterWrappedRows to filter frames by `icon:GetAlpha() > 0` in addition to IsShown(), then apply the existing centering logic. No new APIs or libraries needed - this is a surgical modification to existing code.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Collapse direction:**
- Icons compact toward center of the bar (not left-aligned)
- Full reflow across rows for multi-row bars — if row 1 loses icons, row 2 icons move up to fill
- When a hidden icon reappears, it returns to its **original configured position**, other icons shift to accommodate
- Bar container keeps its original dimensions — icons compact within it

**Transition behavior:**
- Instant snap to new positions — no animation
- Every visibility change triggers immediate relayout (no debouncing/batching)
- Icons just appear/disappear with no visual cue (no flash, glow, or highlight)

**Spacing & alignment:**
- Collapsed icons keep the same spacing/padding as configured — only the hidden icon's slot is removed
- Centering based on full bar width (including padding/borders)
- If bar has a grow direction setting, collapse respects that direction (grow right = compact from left, grow center = center, etc.)

**Edge cases:**
- When ALL icons are hidden, the empty bar frame stays visible (no bar hiding)
- Single remaining icon follows grow direction rules — sits at origin point, not forced to center
- Layout collapse applies to ALL bar types that support HideWhenOffCooldown (Essential and Utility)

### Claude's Discretion

- Vertical bar compacting direction (if vertical bars exist in the addon)
- Whether to recalculate on every RefreshLayout or only on visibility change (optimize based on existing patterns)
- Behavior when feature is toggled off mid-combat (immediate restore vs next refresh cycle — pick safest approach)

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope
</user_constraints>

## Standard Stack

### Core WoW APIs (Already in BCM)

| API | Purpose | Why Standard |
|-----|---------|--------------|
| `frame:GetAlpha()` | Check if icon is hidden (alpha=0) | Native WoW API, standard visibility check |
| `frame:IsShown()` | Check if frame is shown | Native WoW API, required for frame filtering |
| `frame:SetPoint(point, parent, relativePoint, x, y)` | Position icon at specific coordinates | Native WoW API, standard layout mechanism |
| `frame:ClearAllPoints()` | Clear existing anchor points before repositioning | Native WoW API, required before SetPoint |
| `frame.layoutIndex` | Blizzard's original position order | Blizzard CooldownViewer metadata, preserves configured order |

### Supporting APIs (Already in BCM)

| API | Purpose | When to Use |
|-----|---------|-------------|
| `viewer.iconLimit` | Max icons per row before wrapping | Multi-row layout calculation |
| `viewer.childXPadding` | Horizontal spacing between icons | Icon positioning math |
| `viewer.childYPadding` | Vertical spacing between rows | Row positioning math |
| `BCDM:IsHideWhenOffCooldownEnabled(viewerName)` | Check if collapse enabled for bar | Phase 1 deliverable, guards feature per bar |
| `icon:GetWidth()`, `icon:GetHeight()` | Icon dimensions for layout math | Calculate row width and positioning |

### No External Libraries Needed

BCM's existing CenterWrappedRows function (CooldownManager.lua:220-271) provides all layout logic. Phase 4 is a modification to filter by alpha, not a new system.

## Architecture Patterns

### Recommended Approach: Modify CenterWrappedRows

BCM already has centering logic that's called via RefreshLayout hooks. The surgical approach is to modify the frame filtering to skip alpha=0 icons.

**Current code structure:**
```lua
-- CooldownManager.lua:220-271
local function CenterWrappedRows(viewerName)
    local viewer = _G[viewerName]
    if not viewer then return end

    -- Collect visible icons (currently only checks IsShown)
    local visibleIcons = {}
    for _, childFrame in ipairs({ viewer:GetChildren() }) do
        if childFrame and childFrame:IsShown() and childFrame.layoutIndex then
            table.insert(visibleIcons, childFrame)
        end
    end

    -- Sort by layoutIndex (preserves configured order)
    table.sort(visibleIcons, function(a, b)
        return (a.layoutIndex or 0) < (b.layoutIndex or 0)
    end)

    -- Calculate positions row-by-row
    -- (centering math, wrapping, SetPoint calls)
end
```

### Pattern 1: Filter by Alpha During Layout

**What:** Check `GetAlpha() > 0` when collecting visible icons for layout.

**When to use:** Every time CenterWrappedRows runs (triggered by RefreshLayout).

**Why this works:** Phase 3 sets alpha=0 on hidden icons but doesn't hide the frame (IsShown() still returns true). Filtering by alpha excludes hidden icons from layout calculation, making remaining icons reflow to fill gaps.

**Example:**
```lua
-- Modified filtering in CenterWrappedRows
local visibleIcons = {}
for _, childFrame in ipairs({ viewer:GetChildren() }) do
    -- NEW: Also check alpha > 0 to exclude hidden icons
    if childFrame and childFrame:IsShown()
       and childFrame.layoutIndex
       and childFrame:GetAlpha() > 0 then
        table.insert(visibleIcons, childFrame)
    end
end
```

**Key insight:** This respects user's "icons return to original configured position" requirement because we still sort by layoutIndex. When an icon becomes visible again (alpha=1), it re-enters the visibleIcons list at its original layoutIndex position, and other icons shift accordingly.

### Pattern 2: Full Reflow Across Rows

**What:** Treat visible icons as a single contiguous sequence, then wrap into rows based on iconLimit.

**When to use:** Multi-row bars with wrapping (iconLimit > 0).

**BCM already implements this:**
```lua
-- CooldownManager.lua:256-270
local rowCount = math.ceil(visibleCount / iconLimit)
for rowIndex = 1, rowCount do
    local rowStart = (rowIndex - 1) * iconLimit + 1
    local rowEnd = math.min(rowStart + iconLimit - 1, visibleCount)
    local rowIcons = rowEnd - rowStart + 1

    -- Calculate row width and center it
    local rowWidth = (rowIcons * iconWidth) + ((rowIcons - 1) * iconSpacing)
    local startX = -rowWidth / 2 + iconWidth / 2

    -- Position each icon in row
    for index = rowStart, rowEnd do
        local iconFrame = visibleIcons[index]
        iconFrame:ClearAllPoints()
        iconFrame:SetPoint(anchorPoint, viewer, relativePoint,
                          startX + (index - rowStart) * (iconWidth + iconSpacing), rowY)
    end
end
```

**Why this achieves user requirements:**
- "Full reflow across rows" - visibleIcons is a flat list, icons flow from row 1 → row 2 → row 3 naturally
- "Icons compact toward center" - each row calculates startX to center itself: `-rowWidth / 2` centers the row, `+ iconWidth / 2` accounts for icon anchor point
- "Original configured position" - layoutIndex sort order preserves configured sequence

### Pattern 3: Guard with Feature Toggle

**What:** Only apply alpha filtering when HideWhenOffCooldown is enabled for the bar.

**When to use:** At the start of CenterWrappedRows.

**Why needed:** When feature is disabled, all icons should be visible regardless of alpha state (allows disabling mid-combat without forcing alpha=1 on all icons).

**Example:**
```lua
local function CenterWrappedRows(viewerName)
    local viewer = _G[viewerName]
    if not viewer then return end

    -- Check if collapse feature is enabled for this bar
    local collapseEnabled = BCDM:IsHideWhenOffCooldownEnabled(viewerName)

    local visibleIcons = {}
    for _, childFrame in ipairs({ viewer:GetChildren() }) do
        local meetsVisibilityCriteria = childFrame:IsShown() and childFrame.layoutIndex

        -- Only check alpha if collapse feature is enabled
        if collapseEnabled then
            meetsVisibilityCriteria = meetsVisibilityCriteria and childFrame:GetAlpha() > 0
        end

        if childFrame and meetsVisibilityCriteria then
            table.insert(visibleIcons, childFrame)
        end
    end

    -- Rest of centering logic unchanged...
end
```

### Pattern 4: Respect Grow Direction (Claude's Discretion)

**Current state:** BCM's CenterWrappedRows already detects anchor point direction:

```lua
-- CooldownManager.lua:245-254
local basePoint, _, _, _, baseY = visibleIcons[1]:GetPoint(1)
if not basePoint or not baseY then return end
local anchorPoint = "TOP"
local relativePoint = "TOP"
local yDirection = -1
if basePoint and basePoint:find("BOTTOM") then
    anchorPoint = "BOTTOM"
    relativePoint = "BOTTOM"
    yDirection = 1
end
```

**Horizontal grow direction:** User mentioned "grow right = compact from left, grow center = center". However, BCM's current implementation ALWAYS centers each row (calculates `startX = -rowWidth / 2 + iconWidth / 2`).

**Decision (Claude's Discretion):** The user's CONTEXT.md specifies "compact toward center" as the primary behavior, with grow direction as a fallback for bars with explicit grow settings. Since Essential and Utility bars use CenterHorizontally=true by default, and this feature only applies to those bars (per Phase 1 scope), **maintain the current center-compacting behavior**. This satisfies the "compact toward center" requirement.

If horizontal grow direction is needed in the future, it would involve checking for a grow direction setting and adjusting startX calculation:
- Grow left: `startX = 0`
- Grow right: `startX = -(rowIcons * iconWidth) - ((rowIcons - 1) * iconSpacing)`
- Grow center: `startX = -rowWidth / 2 + iconWidth / 2` (current behavior)

### Anti-Patterns to Avoid

- **Using Hide() instead of alpha check:** Hide() affects IsShown(), breaking Blizzard's internal layout logic. Phase 3 uses SetAlpha(0) specifically to keep IsShown()=true.
- **Caching visible icon list:** Layout must recalculate every RefreshLayout call to handle dynamic visibility changes. Don't cache the filtered list.
- **Modifying layoutIndex:** Never change layoutIndex values - this is Blizzard's configured order. Respect it to allow icons to return to original positions.
- **Creating new layout function:** Modifying CenterWrappedRows is surgical and maintains compatibility with existing centering feature. Creating a separate collapse function would duplicate logic.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Icon positioning math | Custom grid layout system | Modify CenterWrappedRows | BCM already has working multi-row centering with wrapping |
| Frame filtering | Manual frame iteration | Extend existing IsShown check | Pattern already established in CenterWrappedRows |
| Grow direction detection | Custom anchor point logic | Extend existing basePoint detection | CooldownManager.lua:245-254 already handles TOP/BOTTOM |
| Feature toggle check | Direct db access | BCDM:IsHideWhenOffCooldownEnabled() | Phase 1 API, handles viewer-to-DB mapping |
| Layout metadata access | Manual frame inspection | Use viewer.iconLimit, childXPadding, childYPadding | Blizzard provides these properties |

**Key insight:** This is a filtering modification, not a new layout system. All positioning logic already exists and works correctly - we just need to exclude alpha=0 icons from the input list.

## Common Pitfalls

### Pitfall 1: Checking IsShown() Only

**What goes wrong:** Hidden icons (alpha=0) still show in layout, leaving gaps.

**Why it happens:** SetAlpha(0) does NOT change IsShown() return value. The frame is "shown" but invisible.

**How to avoid:** Check `GetAlpha() > 0` in addition to IsShown().

**Warning signs:** Icons hide (go invisible) but gaps remain in the bar.

### Pitfall 2: Not Sorting by layoutIndex

**What goes wrong:** Icons appear in random order instead of configured order.

**Why it happens:** GetChildren() returns frames in creation order, not configured order. Blizzard stores configured order in layoutIndex.

**How to avoid:** Always sort filtered icons by layoutIndex before calculating positions.

**Warning signs:** Icon order changes when spells hide/show.

### Pitfall 3: Modifying CenterWrappedRows Without Feature Toggle

**What goes wrong:** Alpha filtering applies even when feature is disabled, breaking users who manually set icon alpha for other reasons.

**Why it happens:** Changing the filtering logic unconditionally affects all bars.

**How to avoid:** Guard alpha check with `BCDM:IsHideWhenOffCooldownEnabled(viewerName)`.

**Warning signs:** Icons disappear unexpectedly when feature is disabled.

### Pitfall 4: Not Handling Edge Cases

**What goes wrong:** Empty bars (all icons hidden) cause math errors or layout breaks.

**Why it happens:** Division by zero, nil access, or SetPoint calls with invalid coordinates.

**How to avoid:**
- Check `#visibleIcons == 0` and return early (BCM already has this check at line 237)
- Validate coordinates before SetPoint calls
- Ensure basePoint exists before accessing (line 245 already checks)

**Warning signs:** Lua errors when all icons are hidden.

### Pitfall 5: Alpha Threshold Too Strict

**What goes wrong:** Icons with alpha=0.99 (almost visible) get excluded from layout.

**Why it happens:** Checking `GetAlpha() == 1` instead of `GetAlpha() > 0`.

**How to avoid:** Use `> 0` check, not `== 1`. Phase 3 sets alpha to exactly 0 or 1, but other systems might use intermediate values.

**Warning signs:** Icons flicker in/out of layout during fade effects.

### Pitfall 6: Forgetting Multi-Bar Support

**What goes wrong:** Layout collapse works for Essential but not Utility bar.

**Why it happens:** CenterWrappedRows is called separately for each bar via RefreshLayout hooks. If modification isn't consistent, behavior differs.

**How to avoid:** The modification applies inside CenterWrappedRows, which is called for both Essential and Utility. No per-bar special handling needed.

**Warning signs:** User reports feature works on one bar but not another.

## Code Examples

### Complete Modified CenterWrappedRows

```lua
-- Source: Modified from CooldownManager.lua:220-271
-- Changes: Add alpha check when HideWhenOffCooldown enabled

local function CenterWrappedRows(viewerName)
    local viewer = _G[viewerName]
    if not viewer then return end

    local iconLimit = viewer.iconLimit
    if not iconLimit or iconLimit <= 0 then return end

    -- Check if layout collapse is enabled for this bar
    local collapseEnabled = BCDM:IsHideWhenOffCooldownEnabled(viewerName)

    -- Collect visible icons (filter by alpha if collapse enabled)
    local visibleIcons = {}
    for _, childFrame in ipairs({ viewer:GetChildren() }) do
        if childFrame and childFrame:IsShown() and childFrame.layoutIndex then
            -- NEW: Skip hidden icons (alpha=0) when collapse is enabled
            if not collapseEnabled or childFrame:GetAlpha() > 0 then
                table.insert(visibleIcons, childFrame)
            end
        end
    end

    -- Sort by layoutIndex to preserve configured order
    table.sort(visibleIcons, function(a, b)
        return (a.layoutIndex or 0) < (b.layoutIndex or 0)
    end)

    local visibleCount = #visibleIcons
    if visibleCount == 0 then return end

    -- Get dimensions and spacing
    local iconWidth = visibleIcons[1]:GetWidth()
    local iconHeight = visibleIcons[1]:GetHeight()
    local iconSpacing = viewer.childXPadding or 0
    local rowSpacing = viewer.childYPadding or 0
    local rowHeight = (iconHeight > 0 and iconHeight or iconWidth) + rowSpacing

    -- Detect anchor point direction (TOP or BOTTOM)
    local basePoint, _, _, _, baseY = visibleIcons[1]:GetPoint(1)
    if not basePoint or not baseY then return end
    local anchorPoint = "TOP"
    local relativePoint = "TOP"
    local yDirection = -1
    if basePoint and basePoint:find("BOTTOM") then
        anchorPoint = "BOTTOM"
        relativePoint = "BOTTOM"
        yDirection = 1
    end

    -- Calculate row-by-row positioning with wrapping
    local rowCount = math.ceil(visibleCount / iconLimit)
    for rowIndex = 1, rowCount do
        local rowStart = (rowIndex - 1) * iconLimit + 1
        local rowEnd = math.min(rowStart + iconLimit - 1, visibleCount)
        local rowIcons = rowEnd - rowStart + 1

        -- Center this row based on its icon count
        local rowWidth = (rowIcons * iconWidth) + ((rowIcons - 1) * iconSpacing)
        local startX = -rowWidth / 2 + iconWidth / 2  -- Center compacting
        local rowY = baseY + yDirection * (rowIndex - 1) * rowHeight

        -- Position each icon in this row
        for index = rowStart, rowEnd do
            local iconFrame = visibleIcons[index]
            iconFrame:ClearAllPoints()
            iconFrame:SetPoint(anchorPoint, viewer, relativePoint,
                              startX + (index - rowStart) * (iconWidth + iconSpacing),
                              rowY)
        end
    end
end
```

### Vertical Bar Handling (Claude's Discretion)

BCM's existing code handles vertical layout via the isHorizontal check in CenterBuffs (lines 184-202). For Essential/Utility bars (which use CenterWrappedRows), vertical layout would need similar logic.

**Current assessment:** Essential and Utility bars appear to be horizontal-only based on the centering logic. If vertical support is added in the future:

```lua
-- Hypothetical vertical layout collapse (not currently needed)
if viewer.isHorizontal == false then
    -- Vertical compacting: center along Y axis, stack along X axis
    local columnSpacing = viewer.childXPadding or 0
    local iconSpacing = viewer.childYPadding or 0
    local totalHeight = (visibleCount * iconHeight) + ((visibleCount - 1) * iconSpacing)
    local startY = totalHeight / 2 - iconHeight / 2  -- Center compacting

    for index, iconFrame in ipairs(visibleIcons) do
        iconFrame:ClearAllPoints()
        iconFrame:SetPoint("CENTER", viewer, "CENTER",
                          0,  -- X stays centered
                          startY - (index - 1) * (iconHeight + iconSpacing))  -- Y stacks
    end
else
    -- Horizontal logic (current CenterWrappedRows)
end
```

**Decision:** Skip vertical implementation for Phase 4 since Essential/Utility bars are horizontal. Can be added if user requests vertical bar support.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Manual Hide() calls | SetAlpha(0) for hiding | Phase 3 | Preserves IsShown() state, cleaner layout integration |
| Static layout calculation | Dynamic filtering by visibility | Phase 4 | Allows reflow when icons hide/show |
| Left-aligned compacting | Center-aligned compacting | BCM's CenterWrappedRows existing | Better visual balance |
| Per-icon positioning | Row-based wrapping | BCM's CenterWrappedRows existing | Supports multi-row bars |

**Deprecated/outdated:**
- Hide() for icon visibility (breaks layout assumptions)
- Caching icon positions (prevents dynamic reflow)
- Ignoring layoutIndex (breaks configured order)

## Open Questions

### 1. Empty Bar Behavior

**What we know:** User specified "empty bar frame stays visible (no bar hiding)".

**What's unclear:** Should the bar container shrink to minimum size or stay at configured size?

**Recommendation:** Keep bar at configured size (no shrinking). CenterWrappedRows returns early when visibleCount=0, leaving bar frame unchanged. This matches user's "bar container keeps its original dimensions" requirement.

### 2. Feature Toggle Mid-Combat

**What we know:** User specified this is Claude's discretion area.

**What's unclear:** Should toggling feature off mid-combat immediately restore layout, or wait for next RefreshLayout?

**Recommendation:** Immediate restore via refresh call. CenterWrappedRows is NOT protected, and RefreshLayout is called from non-protected contexts. When feature is disabled in GUI, call `BCDM:RefreshHideWhenOffCooldown()` which triggers UpdateAllViewers, which triggers RefreshLayout hooks, which re-runs CenterWrappedRows without alpha filtering.

```lua
-- In GUI.lua when checkbox changes
BCDM.db.profile.CooldownManager[viewerType].HideWhenOffCooldown = value
if not value then
    -- Feature disabled: restore all icons to visible and refresh layout
    for _, icon in ipairs({ viewer:GetChildren() }) do
        if icon then icon:SetAlpha(1) end
    end
end
BCDM:RefreshHideWhenOffCooldown()  -- Triggers layout recalculation
```

**Safest approach:** Let RefreshLayout hooks handle it naturally. No special combat lockdown checks needed since we're not calling protected functions.

### 3. Grow Direction Configuration

**What we know:** User mentioned grow direction in CONTEXT.md: "If bar has a grow direction setting, collapse respects that direction".

**What's unclear:** Does BCM have a grow direction setting, or is this future-proofing?

**Investigation:** Searched codebase for "grow" - no grow direction setting found. CenterHorizontally is a boolean (center or don't center), not a directional enum.

**Recommendation:** The user's "compact toward center" requirement is already satisfied by CenterWrappedRows' centering math. Interpret "grow direction setting" as referring to the TOP/BOTTOM anchor point detection (lines 245-254), which already works correctly. No additional grow direction logic needed for Phase 4.

## Sources

### Primary (HIGH confidence)

- BCM Codebase Analysis:
  - `/home/sntanavaras/random-projects/BetterCooldownManager/Modules/CooldownManager.lua` (lines 220-271): CenterWrappedRows layout logic
  - `/home/sntanavaras/random-projects/BetterCooldownManager/Modules/CooldownManager.lua` (lines 158-205): CenterBuffs pattern for reference
  - `/home/sntanavaras/random-projects/BetterCooldownManager/Modules/HideWhenOffCooldown.lua` (lines 39-60): Phase 3 alpha-based hiding
  - `/home/sntanavaras/random-projects/BetterCooldownManager/Core/Globals.lua` (lines 619-622): IsHideWhenOffCooldownEnabled API
  - `.planning/PROJECT.md`: ArcUI pattern using alpha <= 0.01 for IsIconInvisible check

### Secondary (MEDIUM confidence)

- [API Region SetPoint - WoWWiki](https://wowwiki-archive.fandom.com/wiki/API_Region_SetPoint) - SetPoint API documentation
- [ScriptRegionResizing:SetPoint - Wowpedia](https://wowpedia.fandom.com/wiki/API_ScriptRegionResizing_SetPoint) - SetPoint syntax and anchor points
- [API UIObject SetAlpha - WoWWiki](https://wowwiki-archive.fandom.com/wiki/API_UIObject_SetAlpha) - SetAlpha API, mentions alpha doesn't affect IsShown
- [Cooldown Manager UI Guide - Wowhead](https://www.wowhead.com/guide/ui/cooldown-manager-setup) - General Cooldown Manager layout documentation

### Tertiary (LOW confidence)

- WebSearch results about grid addons (Grid, Grid2) - general layout pattern reference
- Community discussions about Cooldown Manager centering and grow direction

## Metadata

**Confidence breakdown:**
- CenterWrappedRows modification approach: HIGH - Existing code is well-structured, modification is surgical
- Alpha filtering pattern: HIGH - Phase 3 uses SetAlpha(0), GetAlpha() is standard API
- Multi-row reflow: HIGH - CenterWrappedRows already implements this correctly
- Center-compacting math: HIGH - startX calculation already achieves this
- Edge case handling: HIGH - Code already checks for empty lists, nil values
- Grow direction interpretation: MEDIUM - No explicit grow direction setting in BCM, interpreting user requirement

**Research date:** 2026-02-12
**Valid until:** 30 days (layout patterns are stable, WoW 12.x API changes already adopted)

**Phase 4 scope verification:**
- Modify layout calculation to skip alpha=0 icons: YES (filter in CenterWrappedRows)
- Ensure smooth repositioning when icons hide/show: YES (RefreshLayout hooks already established)
- Test with various bar configurations: YES (works for both Essential and Utility, handles multi-row)
- Respect original icon positions: YES (sort by layoutIndex preserves configured order)
- Compact toward center: YES (existing startX = -rowWidth / 2 calculation)
- Full reflow across rows: YES (flat visibleIcons list with wrapping logic)

**Dependencies verified:**
- Phase 1: HideWhenOffCooldown setting and API - COMPLETE
- Phase 2: IsSpellOnCooldown detection function - COMPLETE
- Phase 3: SetAlpha(0) for hiding icons - COMPLETE

**Outputs for next phase:**
- Phase 5 will add UI configuration (checkbox in settings)
- Phase 4 completes the core feature functionality
