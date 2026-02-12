---
phase: 05-ui-configuration
verified: 2026-02-12T08:40:06Z
status: human_needed
score: 7/7 must-haves verified
human_verification:
  - test: "Open Essential bar settings and verify checkbox appears"
    expected: "Checkbox labeled 'Hide When Off Cooldown' is visible in Essential Settings panel"
    why_human: "Visual appearance requires in-game verification"
  - test: "Open Utility bar settings and verify checkbox appears"
    expected: "Checkbox labeled 'Hide When Off Cooldown' is visible in Utility Settings panel"
    why_human: "Visual appearance requires in-game verification"
  - test: "Check that checkbox is unchecked by default"
    expected: "Checkbox is unchecked when opening settings on a fresh profile"
    why_human: "Default state requires runtime verification with AceDB"
  - test: "Toggle checkbox ON and verify icons hide"
    expected: "Spell icons that are off cooldown immediately disappear (alpha=0)"
    why_human: "Real-time behavior and visual effect require in-game testing"
  - test: "Toggle checkbox OFF and verify icons restore"
    expected: "All spell icons immediately reappear (alpha=1)"
    why_human: "Real-time behavior and visual effect require in-game testing"
  - test: "Verify no checkbox in Custom/Item/ItemSpell/Trinket settings"
    expected: "HideWhenOffCooldown checkbox does NOT appear in these bar types"
    why_human: "Negative verification across multiple settings panels requires in-game navigation"
  - test: "Hover over checkbox and verify tooltip"
    expected: "Tooltip displays 'Hides spell icons that are not on cooldown' on cursor position"
    why_human: "GameTooltip rendering and hover behavior require in-game testing"
---

# Phase 5: UI Configuration - Verification Report

**Phase Goal:** Let users toggle the feature per-bar via checkbox in settings panel  
**Verified:** 2026-02-12T08:40:06Z  
**Status:** human_needed  
**Re-verification:** No - initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | User sees a 'Hide When Off Cooldown' checkbox in Essential bar settings panel | ✓ VERIFIED | Checkbox code exists at lines 1686-1700 inside Essential/Utility conditional (line 1658) |
| 2 | User sees a 'Hide When Off Cooldown' checkbox in Utility bar settings panel | ✓ VERIFIED | Same conditional block handles both Essential and Utility (line 1658: `if viewerType == "Essential" or viewerType == "Utility"`) |
| 3 | Checkbox is unchecked by default (matches Phase 1 default of false) | ✓ VERIFIED | SetValue reads from `BCDM.db.profile.CooldownManager[viewerType].HideWhenOffCooldown` (line 1688), which defaults to false in Core/Defaults.lua lines 129 and 143 |
| 4 | Toggling checkbox on instantly hides off-cooldown spell icons | ✓ VERIFIED | OnValueChanged callback (lines 1689-1692) writes setting and calls `BCDM:RefreshHideWhenOffCooldown()` which triggers Phase 3 alpha hiding |
| 5 | Toggling checkbox off instantly restores all icons to visible | ✓ VERIFIED | Same OnValueChanged callback handles both true/false values via `BCDM:RefreshHideWhenOffCooldown()` |
| 6 | No checkbox appears for Custom, Item, ItemSpell, or Trinket bar types | ✓ VERIFIED | Checkbox is inside `if viewerType == "Essential" or viewerType == "Utility"` block (line 1658), grep confirms no hideWhenOffCooldown in Custom/Item/Trinket blocks |
| 7 | Hovering the checkbox shows a one-line tooltip | ✓ VERIFIED | OnEnter callback (lines 1693-1697) shows GameTooltip with text "Hides spell icons that are not on cooldown", OnLeave hides it (line 1698) |

**Score:** 7/7 truths verified (automated checks passed)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `Core/GUI.lua` | HideWhenOffCooldown checkbox in Essential/Utility settings | ✓ VERIFIED | EXISTS (3127 lines), SUBSTANTIVE (checkbox code spans lines 1686-1700, 15 lines), WIRED (imported 8 times in file, used in OnValueChanged callback) |

#### Artifact Level Verification: Core/GUI.lua

**Level 1: Existence** - ✓ PASSED
- File exists at `/home/sntanavaras/random-projects/BetterCooldownManager/Core/GUI.lua`
- File length: 3127 lines (well above minimum)

**Level 2: Substantive** - ✓ PASSED
- Contains `hideWhenOffCooldownCheckbox` variable (8 occurrences)
- No stub patterns detected (0 TODO/FIXME/placeholder comments)
- No empty returns or console.log-only implementations
- Full implementation with:
  - CheckBox widget creation (AG:Create)
  - Label: "Hide When Off Cooldown"
  - SetValue reading from database
  - OnValueChanged callback with database write + refresh call
  - OnEnter/OnLeave callbacks for tooltip
  - SetRelativeWidth for layout
  - AddChild to add to container

**Level 3: Wired** - ✓ PASSED
- Reads from: `BCDM.db.profile.CooldownManager[viewerType].HideWhenOffCooldown` (line 1688)
- Writes to: `BCDM.db.profile.CooldownManager[viewerType].HideWhenOffCooldown` (line 1690)
- Calls: `BCDM:RefreshHideWhenOffCooldown()` (line 1691) - function exists in Modules/HideWhenOffCooldown.lua:158
- Added to: `toggleContainer` (line 1700) which is an InlineGroup created at line 1659
- GameTooltip integration: SetOwner, SetText, Show, Hide (lines 1694-1698)

### Key Link Verification

| From | To | Via | Status | Details |
|------|-----|-----|--------|---------|
| Core/GUI.lua | `BCDM.db.profile.CooldownManager[viewerType].HideWhenOffCooldown` | SetValue reads setting (line 1688), OnValueChanged writes setting (line 1690) | ✓ WIRED | Pattern found at lines 1688 and 1690, exact match for must_have pattern `BCDM\.db\.profile\.CooldownManager\[viewerType\]\.HideWhenOffCooldown` |
| Core/GUI.lua | `BCDM:RefreshHideWhenOffCooldown()` | OnValueChanged callback triggers visibility refresh (line 1691) | ✓ WIRED | Pattern found at line 1691, exact match for must_have pattern `BCDM:RefreshHideWhenOffCooldown`, function definition exists in Modules/HideWhenOffCooldown.lua:158 |

#### Detailed Link Analysis

**Link 1: Checkbox ↔ Database Setting**
- **Read path (line 1688):** `hideWhenOffCooldownCheckbox:SetValue(BCDM.db.profile.CooldownManager[viewerType].HideWhenOffCooldown)`
  - Status: ✓ WIRED - Checkbox initial state reads from AceDB profile
- **Write path (line 1690):** `BCDM.db.profile.CooldownManager[viewerType].HideWhenOffCooldown = value`
  - Status: ✓ WIRED - OnValueChanged updates database setting
- **Default value:** Core/Defaults.lua lines 129 (Essential) and 143 (Utility) both set to `false`

**Link 2: Checkbox → Refresh Function**
- **Call site (line 1691):** `BCDM:RefreshHideWhenOffCooldown()`
- **Definition:** Modules/HideWhenOffCooldown.lua:158
- **Status:** ✓ WIRED - Callback directly invokes refresh function after setting update
- **Anti-pattern check:** No `UpdateCooldownViewer` call in callback (grep returned 0 occurrences)

**Link 3: Checkbox → Tooltip**
- **OnEnter (lines 1693-1697):** Sets GameTooltip owner, text, and shows tooltip
- **OnLeave (line 1698):** Hides GameTooltip
- **Status:** ✓ WIRED - Standard GameTooltip pattern (24 uses of GameTooltip in GUI.lua)

### Requirements Coverage

No REQUIREMENTS.md exists or no requirements mapped to Phase 5.

### Anti-Patterns Found

**Scan Results:** 0 anti-patterns detected

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| (none) | - | - | - | - |

**Detailed Scan:**
- No TODO/FIXME/XXX/HACK comments in GUI.lua (0 occurrences)
- No placeholder text in checkbox implementation
- No empty returns or null returns
- No console.log-only implementations
- Follows existing AceGUI checkbox pattern (matches CenterHorizontally checkbox at lines 1665-1684)
- Proper GameTooltip usage (OnEnter/OnLeave callbacks)
- Correct refresh function called (RefreshHideWhenOffCooldown, not UpdateCooldownViewer)

### Human Verification Required

All automated structural checks passed. The following items require in-game testing to fully verify goal achievement:

#### 1. Visual Appearance: Essential Bar Checkbox

**Test:** Open BetterCooldownManager settings, navigate to Essential bar settings panel.  
**Expected:** A checkbox labeled "Hide When Off Cooldown" appears in the Essential Settings section, below the "Center Second Row (Horizontally)" checkbox.  
**Why human:** Visual rendering and positioning within AceGUI framework requires runtime verification. The code structure is correct (inside Essential/Utility conditional, added to toggleContainer), but actual appearance depends on AceGUI rendering.

#### 2. Visual Appearance: Utility Bar Checkbox

**Test:** Navigate to Utility bar settings panel in BetterCooldownManager settings.  
**Expected:** A checkbox labeled "Hide When Off Cooldown" appears in the Utility Settings section, below the "Center Second Row (Horizontally)" checkbox.  
**Why human:** Same as test 1 - visual rendering requires in-game verification for Utility bar type.

#### 3. Default State

**Test:** On a fresh profile or after resetting settings, open Essential/Utility bar settings.  
**Expected:** The "Hide When Off Cooldown" checkbox is unchecked (default state).  
**Why human:** While the code reads from a setting that defaults to false in Defaults.lua, AceDB's runtime initialization and the checkbox's SetValue call must be verified in-game.

#### 4. Toggle ON Behavior

**Test:** 
1. Ensure Essential or Utility bar has spell icons visible
2. Check the "Hide When Off Cooldown" checkbox
3. Observe spell icons that are currently off cooldown

**Expected:** Spell icons that are not on cooldown immediately disappear (set to alpha=0). The layout should collapse to fill gaps (Phase 4 behavior).  
**Why human:** Requires real-time cooldown state detection, alpha changes, and layout adjustments. This tests the integration of Phase 3 (alpha hiding) and Phase 4 (layout collapse) triggered by the checkbox.

#### 5. Toggle OFF Behavior

**Test:**
1. With "Hide When Off Cooldown" checked and some icons hidden
2. Uncheck the checkbox
3. Observe all spell icons

**Expected:** All spell icons immediately reappear (alpha=1), including those that were hidden. Layout restores to full grid.  
**Why human:** Requires verifying that RefreshHideWhenOffCooldown() correctly restores visibility when setting is false.

#### 6. Negative Test: Other Bar Types

**Test:** Navigate to Custom, Item, ItemSpell, and Trinket bar settings panels.  
**Expected:** The "Hide When Off Cooldown" checkbox does NOT appear in any of these panels.  
**Why human:** Requires navigating through multiple settings panels to verify the conditional block correctly excludes non-Essential/Utility bar types. While code analysis shows the checkbox is inside the Essential/Utility conditional, in-game verification ensures no rendering edge cases.

#### 7. Tooltip Behavior

**Test:** Hover mouse cursor over the "Hide When Off Cooldown" checkbox label or checkbox itself.  
**Expected:** A GameTooltip appears near the cursor with the text "Hides spell icons that are not on cooldown" in white text.  
**Why human:** GameTooltip rendering, positioning (ANCHOR_CURSOR), and hover event triggering require in-game testing. While the OnEnter/OnLeave callbacks are correctly implemented, the actual tooltip display depends on WoW's tooltip system.

---

## Summary

**Automated Verification: PASSED**

All 7 observable truths have been verified through code analysis:

1. ✓ Checkbox code exists in Essential/Utility settings (lines 1686-1700)
2. ✓ Conditional block ensures only Essential and Utility bar types render the checkbox (line 1658)
3. ✓ Default value is false in Core/Defaults.lua (lines 129, 143)
4. ✓ OnValueChanged callback writes setting and calls RefreshHideWhenOffCooldown() (lines 1689-1692)
5. ✓ Same callback handles both toggle-on and toggle-off (single function handles true/false)
6. ✓ Checkbox does not appear in Custom/Item/ItemSpell/Trinket blocks (verified via grep)
7. ✓ Tooltip implementation exists via GameTooltip OnEnter/OnLeave callbacks (lines 1693-1698)

**Structural Integrity: VERIFIED**

- Artifact exists (Core/GUI.lua, 3127 lines)
- Implementation is substantive (15 lines of complete checkbox code, no stubs)
- All key links are wired (database read/write, refresh function call, tooltip callbacks)
- No anti-patterns detected (no TODOs, placeholders, empty returns)
- Follows existing codebase patterns (matches CenterHorizontally checkbox style)
- Correct API usage (RefreshHideWhenOffCooldown, not UpdateCooldownViewer)

**Phase Goal Status: LIKELY ACHIEVED**

The phase goal "Let users toggle the feature per-bar via checkbox in settings panel" appears to be fully achieved based on code analysis. The checkbox:

- ✓ Exposes the HideWhenOffCooldown setting added in Phase 1
- ✓ Appears only in Essential and Utility bar settings
- ✓ Reads the current setting value on render
- ✓ Writes the setting and triggers visibility refresh on toggle
- ✓ Provides user guidance via tooltip
- ✓ Integrates seamlessly with existing GUI patterns

**Human Verification Required:**

While all structural and logical checks pass, the following aspects require in-game testing to confirm the feature works as intended:

1. Visual appearance and layout of the checkbox
2. Default unchecked state on fresh profile
3. Instant hiding of off-cooldown icons when toggled on
4. Instant restoration of all icons when toggled off
5. Absence of checkbox in non-supported bar types
6. Tooltip display on hover

These are inherent limitations of static code verification - the checkbox is correctly implemented and wired, but the runtime behavior (WoW addon environment, AceGUI rendering, cooldown state detection, alpha animation) must be verified by a human playing the game.

**Recommendation:** Proceed with human verification testing. If all 7 human verification tests pass, Phase 5 and the entire hide-when-off-cooldown feature (Phases 1-5) are complete.

---

_Verified: 2026-02-12T08:40:06Z_  
_Verifier: Claude (gsd-verifier)_
