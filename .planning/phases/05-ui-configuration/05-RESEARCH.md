# Phase 5: UI Configuration - Research

**Researched:** 2026-02-12
**Domain:** WoW Addon GUI with AceGUI-3.0
**Confidence:** HIGH

## Summary

This phase adds a checkbox to the existing bar settings panel that toggles the HideWhenOffCooldown feature for Essential and Utility bars. The addon already uses AceGUI-3.0 for all settings UI, and the codebase shows consistent patterns for adding checkboxes with instant-apply callbacks.

The standard pattern is clear: create a CheckBox widget, set its label and value, wire an OnValueChanged callback that updates the database and refreshes the feature, then add it to the appropriate container. Tooltips are implemented via OnEnter/OnLeave callbacks using GameTooltip. All settings in the codebase apply instantly (no "apply on close" pattern exists).

**Primary recommendation:** Add the checkbox inline within the existing "Essential Settings" / "Utility Settings" InlineGroup container (lines 1658-1685 in GUI.lua), immediately after the CenterHorizontally checkbox. Use instant-apply pattern with RefreshHideWhenOffCooldown() callback. Implement tooltip via OnEnter/OnLeave callbacks matching existing button patterns (lines 1304-1305).

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Checkbox placement:**
- Place near existing visibility/show-hide options in the bar settings panel
- Only render for Essential and Utility bars — no checkbox for unsupported bar types
- Default to unchecked (matches Phase 1 default of `false`)
- Inline with existing options — no separator, header, or dedicated section

**Tooltip & labeling:**
- Checkbox label: "Hide When Off Cooldown"
- Tooltip: short, one line (e.g., "Hides spell icons that are not on cooldown")
- No mention of layout collapse in tooltip — users will see it naturally
- Match the existing addon's language style and tooltip conventions

**Visual feedback:**
- No visual indicator on the bar itself when the feature is active — hidden icons and collapsed layout are self-evident
- Bar stays visible (empty frame) even when all icons are hidden
- Instant restore when feature is toggled off — icons snap back immediately

### Claude's Discretion

- Whether toggling the checkbox applies live (instant preview) or on settings close — match existing addon behavior
- Exact tooltip wording — follow existing addon tone and patterns

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope.
</user_constraints>

## Standard Stack

The established libraries for WoW addon GUI in this project:

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| AceGUI-3.0 | Bundled | GUI widget framework | Already used for all settings UI in this addon |
| Lua 5.1 | WoW Embedded | Scripting language | WoW API standard |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| AceDB-3.0 | Bundled | Settings persistence | Already storing HideWhenOffCooldown setting |

**No new libraries needed** - all infrastructure already exists.

## Architecture Patterns

### Recommended Project Structure
```
Core/
└── GUI.lua          # Add checkbox in CreateCooldownViewerSettings function
```

Single file change - add checkbox widget to existing function that creates per-bar settings UI.

### Pattern 1: AceGUI CheckBox Creation
**What:** Standard pattern for creating checkboxes in BetterCooldownManager settings
**When to use:** Any per-bar boolean setting that needs UI control
**Example:**
```lua
-- Source: Core/GUI.lua lines 1665-1684 (existing CenterHorizontally checkbox)
local centerHorizontallyCheckbox = AG:Create("CheckBox")
centerHorizontallyCheckbox:SetLabel("Center Second Row (Horizontally) - |cFFFF4040Reload|r Required.")
centerHorizontallyCheckbox:SetValue(BCDM.db.profile.CooldownManager[viewerType].CenterHorizontally)
centerHorizontallyCheckbox:SetCallback("OnValueChanged", function(_, _, value)
    BCDM.db.profile.CooldownManager[viewerType].CenterHorizontally = value
    -- ... reload logic ...
end)
centerHorizontallyCheckbox:SetRelativeWidth(1)
toggleContainer:AddChild(centerHorizontallyCheckbox)
```

**Key details:**
- `AG:Create("CheckBox")` - AceGUI alias is `AG`
- `SetValue()` reads from `BCDM.db.profile.CooldownManager[viewerType].[Setting]`
- `OnValueChanged` callback receives `(self, event, value)` - use `(_, _, value)` pattern
- `SetRelativeWidth(1)` - full width for single checkbox per row
- Add to parent container with `AddChild()`

### Pattern 2: Instant-Apply Settings
**What:** All BetterCooldownManager settings apply immediately when changed
**When to use:** Every setting in this addon (no "apply on close" pattern exists)
**Example:**
```lua
-- Source: Core/GUI.lua line 503 (instant-apply checkbox)
scaleByIconSizeCheckbox:SetCallback("OnValueChanged", function(_, _, value)
    CooldownTextDB.ScaleByIconSize = value
    BCDM:UpdateCooldownViewers()
end)

-- Source: Core/GUI.lua line 1787 (instant-apply for Items)
hideZeroChargesCheckbox:SetCallback("OnValueChanged", function(_, _, value)
    BCDM.db.profile.CooldownManager[viewerType].HideZeroCharges = value
    BCDM:UpdateCooldownViewer(viewerType)
end)
```

**Standard callback structure:**
1. Update database: `BCDM.db.profile.CooldownManager[viewerType].[Setting] = value`
2. Refresh feature: Call appropriate update/refresh function
3. No confirmation dialogs (except for settings requiring reload)

**For HideWhenOffCooldown specifically:**
```lua
-- Phase 4 research recommended this pattern (from 04-RESEARCH.md line 459)
BCDM.db.profile.CooldownManager[viewerType].HideWhenOffCooldown = value
BCDM:RefreshHideWhenOffCooldown()  -- Updates visibility + triggers layout recalc
```

### Pattern 3: GameTooltip Implementation
**What:** Hover tooltips for widgets using WoW's GameTooltip system
**When to use:** When SetDescription would be too verbose or disrupt layout
**Example:**
```lua
-- Source: Core/GUI.lua lines 1304-1305 (button tooltip)
AddRacialsButton:SetCallback("OnEnter", function(widget)
    GameTooltip:SetOwner(widget.frame, "ANCHOR_CURSOR")
    GameTooltip:SetText("This will add all racials...", 1, 1, 1, 1, false)
    GameTooltip:Show()
end)
AddRacialsButton:SetCallback("OnLeave", function() GameTooltip:Hide() end)

-- Source: Core/GUI.lua lines 2093-2097 (slider tooltip with contextual info)
heightSlider:SetCallback("OnEnter", function(self)
    GameTooltip:SetOwner(self.frame, "ANCHOR_CURSOR")
    GameTooltip:AddLine("This height is used when the player does |cFFFF4040NOT|r have...")
    GameTooltip:Show()
end)
heightSlider:SetCallback("OnLeave", function() GameTooltip:Hide() end)
```

**Key methods:**
- `GameTooltip:SetOwner(frame, "ANCHOR_CURSOR")` - Position at cursor
- `GameTooltip:SetText(text, r, g, b, a, wrap)` - Single line tooltip (simple)
- `GameTooltip:AddLine(text)` - Multi-line tooltip (use for additional context)
- `GameTooltip:Show()` - Display tooltip
- `GameTooltip:Hide()` - Remove tooltip on leave

**Color coding in tooltips:**
- `|cFFFF4040` - Red (warnings, "NOT", "Reload")
- `|cFF8080FF` - Purple (addon name "Better")
- `|cFF00B0F7` - Blue (system names "Blizzard")
- `|cFFFFCC00` - Yellow (emphasis, section names)

### Pattern 4: Conditional Widget Rendering
**What:** Only render widgets for specific bar types
**When to use:** Settings that only apply to certain bars
**Example:**
```lua
-- Source: Core/GUI.lua lines 1658-1685 (Essential/Utility only)
if viewerType == "Essential" or viewerType == "Utility" then
    local toggleContainer = AG:Create("InlineGroup")
    toggleContainer:SetTitle(viewerType .. " Settings")
    toggleContainer:SetFullWidth(true)
    toggleContainer:SetLayout("Flow")
    ScrollFrame:AddChild(toggleContainer)

    -- Add checkboxes here
    local centerHorizontallyCheckbox = AG:Create("CheckBox")
    -- ... setup ...
    toggleContainer:AddChild(centerHorizontallyCheckbox)
end

-- Source: Core/GUI.lua lines 1781-1791 (Item/ItemSpell only)
if viewerType == "Item" or viewerType == "ItemSpell" then
    local hideZeroChargesCheckbox = AG:Create("CheckBox")
    -- ... setup ...
    iconContainer:AddChild(hideZeroChargesCheckbox)
end
```

**For HideWhenOffCooldown:** Only render inside the existing `if viewerType == "Essential" or viewerType == "Utility"` block (line 1658).

### Anti-Patterns to Avoid

**Don't use SetDescription for simple tooltips:**
- SetDescription adds text below the checkbox, consuming vertical space
- Only one checkbox in codebase uses SetDescription (line 2318, for multi-spec warning)
- Hover tooltips via GameTooltip are standard for feature descriptions

**Don't create new containers:**
- User specified "inline with existing options — no separator, header, or dedicated section"
- Add checkbox directly to existing `toggleContainer` (Essential/Utility Settings InlineGroup)

**Don't call UpdateCooldownViewer for this setting:**
- UpdateCooldownViewer refreshes layout/sizing/positioning (lines 312-355, CooldownManager.lua)
- HideWhenOffCooldown only affects icon visibility/alpha
- Use `RefreshHideWhenOffCooldown()` instead (line 158, HideWhenOffCooldown.lua)

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Tooltip positioning | Manual frame positioning | GameTooltip:SetOwner with ANCHOR_CURSOR | Handles screen edges, cursor following, z-order automatically |
| Settings persistence | Manual SavedVariables table | Existing BCDM.db.profile access | AceDB handles defaults, profiles, validation automatically |
| Widget creation | Raw CreateFrame | AceGUI:Create("CheckBox") | Handles styling, callbacks, layout, pooling automatically |
| Feature refresh | Manual icon iteration | BCDM:RefreshHideWhenOffCooldown() | Already implements per-viewer logic with proper guards |

**Key insight:** The infrastructure for this phase already exists. Adding the checkbox is a 10-line addition following existing patterns exactly.

## Common Pitfalls

### Pitfall 1: Wrong Refresh Function
**What goes wrong:** Calling `BCDM:UpdateCooldownViewer(viewerType)` instead of `BCDM:RefreshHideWhenOffCooldown()`
**Why it happens:** UpdateCooldownViewer is the common refresh pattern for most settings
**How to avoid:** HideWhenOffCooldown module has its own refresh function that:
- Updates all supported viewers (Essential + Utility) at once
- Checks per-viewer feature flags via IsHideWhenOffCooldownEnabled
- Handles instant restore when disabled (sets all icons alpha=1)
- Triggers layout recalculation via RefreshLayout hooks
**Warning signs:** Icons don't hide/show immediately, or layout doesn't collapse properly

**Correct usage:**
```lua
hideWhenOffCooldownCheckbox:SetCallback("OnValueChanged", function(_, _, value)
    BCDM.db.profile.CooldownManager[viewerType].HideWhenOffCooldown = value
    BCDM:RefreshHideWhenOffCooldown()  -- ✓ Correct
    -- NOT: BCDM:UpdateCooldownViewer(viewerType)  ✗ Wrong
end)
```

### Pitfall 2: Wrong Container for Checkbox
**What goes wrong:** Adding checkbox to ScrollFrame instead of toggleContainer
**Why it happens:** ScrollFrame is the outer container, visually looks like the right place
**How to avoid:** The Essential/Utility Settings InlineGroup (`toggleContainer`) is created specifically for these checkboxes (lines 1659-1663). Adding to ScrollFrame puts the checkbox outside the visual group, breaking layout.
**Warning signs:** Checkbox appears outside the "Essential Settings" / "Utility Settings" box

**Correct structure:**
```lua
if viewerType == "Essential" or viewerType == "Utility" then
    local toggleContainer = AG:Create("InlineGroup")
    -- ... setup ...
    ScrollFrame:AddChild(toggleContainer)  -- Container goes in ScrollFrame

    local checkbox = AG:Create("CheckBox")
    -- ... setup ...
    toggleContainer:AddChild(checkbox)  -- ✓ Checkbox goes in toggleContainer
    -- NOT: ScrollFrame:AddChild(checkbox)  ✗ Wrong
end
```

### Pitfall 3: Forgetting Conditional Rendering
**What goes wrong:** Rendering the checkbox for all bar types (Custom, Item, Trinket, etc.)
**Why it happens:** The CreateCooldownViewerSettings function handles all bar types
**How to avoid:** HideWhenOffCooldown only supports Essential and Utility bars (per Phase 1 decision). The checkbox MUST be inside the `if viewerType == "Essential" or viewerType == "Utility"` block (line 1658).
**Warning signs:** Checkbox appears for Custom/Item/Trinket bars but doesn't work

### Pitfall 4: Tooltip Text Overload
**What goes wrong:** Multi-line tooltip explaining feature details, layout collapse, etc.
**Why it happens:** Developer wants to fully explain the feature
**How to avoid:** User specified "short, one line" and "No mention of layout collapse in tooltip — users will see it naturally". Existing tooltips in BCDM are concise functional descriptions.
**Warning signs:** Tooltip wraps to multiple lines, explains behavior in detail

**Good tooltip examples from codebase:**
- "This will add all racials to every single class & specialization on your profile." (line 1304)
- "This height is used when the player does |cFFFF4040NOT|r have a Secondary Power Bar..." (line 2094)

**For this feature:**
```lua
GameTooltip:SetText("Hides spell icons that are not on cooldown", 1, 1, 1, 1, false)
-- Or slightly more descriptive:
GameTooltip:SetText("Hide icons when their spell is off cooldown", 1, 1, 1, 1, false)
```

## Code Examples

Verified patterns from actual codebase:

### Complete Checkbox Implementation (Template for Phase 5)
```lua
-- Source: Synthesized from Core/GUI.lua patterns (lines 1658-1684, 1785-1788, 1304-1305)
-- Location: Core/GUI.lua, inside CreateCooldownViewerSettings function

if viewerType == "Essential" or viewerType == "Utility" then
    local toggleContainer = AG:Create("InlineGroup")
    toggleContainer:SetTitle(viewerType .. " Settings")
    toggleContainer:SetFullWidth(true)
    toggleContainer:SetLayout("Flow")
    ScrollFrame:AddChild(toggleContainer)

    -- Existing CenterHorizontally checkbox here (lines 1665-1684)

    -- NEW: HideWhenOffCooldown checkbox
    local hideWhenOffCooldownCheckbox = AG:Create("CheckBox")
    hideWhenOffCooldownCheckbox:SetLabel("Hide When Off Cooldown")
    hideWhenOffCooldownCheckbox:SetValue(BCDM.db.profile.CooldownManager[viewerType].HideWhenOffCooldown)
    hideWhenOffCooldownCheckbox:SetCallback("OnValueChanged", function(_, _, value)
        BCDM.db.profile.CooldownManager[viewerType].HideWhenOffCooldown = value
        BCDM:RefreshHideWhenOffCooldown()
    end)
    hideWhenOffCooldownCheckbox:SetCallback("OnEnter", function(widget)
        GameTooltip:SetOwner(widget.frame, "ANCHOR_CURSOR")
        GameTooltip:SetText("Hides spell icons that are not on cooldown", 1, 1, 1, 1, false)
        GameTooltip:Show()
    end)
    hideWhenOffCooldownCheckbox:SetCallback("OnLeave", function() GameTooltip:Hide() end)
    hideWhenOffCooldownCheckbox:SetRelativeWidth(1)
    toggleContainer:AddChild(hideWhenOffCooldownCheckbox)
end
```

### Existing API Usage
```lua
-- Source: Modules/HideWhenOffCooldown.lua lines 158-162
-- Call this when checkbox changes to refresh visibility + layout
function BCDM:RefreshHideWhenOffCooldown()
    if isEnabled then
        UpdateAllViewers()  -- Updates Essential + Utility viewers
    end
end
```

### Database Access Pattern
```lua
-- Source: Core/Defaults.lua lines 129, 143
-- Setting already exists in database (added in Phase 1)
CooldownManager = {
    Essential = {
        HideWhenOffCooldown = false,  -- Default: disabled
        -- ...
    },
    Utility = {
        HideWhenOffCooldown = false,  -- Default: disabled
        -- ...
    },
}

-- Source: Core/Globals.lua lines 600-607
-- Getter function already exists (added in Phase 1)
function BCDM:GetHideWhenOffCooldown(barType)
    if not barType then return false end
    local barSettings = self.db.profile.CooldownManager[barType]
    return barSettings and barSettings.HideWhenOffCooldown or false
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| AceConfig options table | Direct AceGUI widget creation | Pre-project (established pattern) | More flexibility but requires manual widget management |
| Reload-required settings | Instant-apply where possible | Ongoing trend in WoW addons | Better UX, already standard in BCDM |
| SetDescription for all tooltips | GameTooltip for hover info | AceGUI-3.0 best practice | Cleaner layouts, tooltips on-demand |

**Current state:** BetterCooldownManager uses modern WoW addon patterns. Direct AceGUI widget creation (not AceConfig) is intentional for this addon's complex nested UI. Instant-apply is the norm for all settings except those requiring UI reloads (like CenterHorizontally).

**Deprecated/outdated:**
- None identified - the codebase follows current WoW addon best practices

## Open Questions

None - all questions resolved:

1. **Apply instant or on close?** → RESOLVED: Instant-apply is the standard pattern in BCDM (Claude's discretion, matched to existing behavior)
2. **Tooltip via SetDescription or GameTooltip?** → RESOLVED: GameTooltip via OnEnter/OnLeave callbacks (standard pattern for feature descriptions in BCDM)
3. **Which bar types?** → RESOLVED: Essential and Utility only (user locked decision)
4. **Exact wording?** → RESOLVED: Label "Hide When Off Cooldown", tooltip "Hides spell icons that are not on cooldown" (user locked decision with minor phrasing flexibility)

## Sources

### Primary (HIGH confidence)
- BetterCooldownManager codebase (local files analyzed directly)
  - Core/GUI.lua - Checkbox patterns, tooltip patterns, instant-apply callbacks
  - Core/Defaults.lua - Setting structure (HideWhenOffCooldown already exists)
  - Core/Globals.lua - Viewer mappings, getter/setter APIs
  - Modules/HideWhenOffCooldown.lua - RefreshHideWhenOffCooldown API
  - Libraries/Ace3/AceGUI-3.0/widgets/AceGUIWidget-CheckBox.lua - CheckBox widget implementation
- Phase 1 research (.planning/phases/01-settings-infrastructure/01-RESEARCH.md) - Settings infrastructure patterns
- Phase 4 research (.planning/phases/04-layout-collapse/04-RESEARCH.md) - Refresh function usage

### Secondary (MEDIUM confidence)
- [AceGUI-3.0 Widgets Documentation](https://www.wowace.com/projects/ace3/pages/ace-gui-3-0-widgets) - CheckBox widget API reference (certificate issue prevented direct fetch, but verified via local widget code)
- [GameTooltip Documentation - Wowpedia](https://wowpedia.fandom.com/wiki/UIOBJECT_GameTooltip) - GameTooltip API methods

### Tertiary (LOW confidence)
- Web search results for WoW addon patterns 2026 - General addon development information, not specific to this implementation

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - All libraries already in use, verified in codebase
- Architecture: HIGH - Patterns extracted directly from existing code
- Pitfalls: HIGH - Identified from code analysis and phase requirements
- Code examples: HIGH - All examples from actual codebase or synthesized from verified patterns

**Research date:** 2026-02-12
**Valid until:** 60 days (stable WoW addon APIs, mature libraries)

**Research scope:**
- ✓ AceGUI-3.0 CheckBox widget API (verified via local widget code)
- ✓ GameTooltip implementation patterns (verified in GUI.lua)
- ✓ Instant-apply callback patterns (verified across 20+ examples)
- ✓ Conditional rendering patterns (verified for bar-specific settings)
- ✓ Existing HideWhenOffCooldown API integration (verified in Modules/)
- ✓ User constraints from CONTEXT.md (locked decisions honored)

**Out of scope:**
- Alternative UI frameworks (user locked AceGUI-3.0 via existing codebase)
- Apply-on-close patterns (not used in BCDM, instant-apply is standard)
- Multi-line descriptions via SetDescription (user specified short one-line tooltip)
