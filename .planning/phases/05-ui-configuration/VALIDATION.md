---
phase: 5
slug: ui-configuration
status: green
nyquist_compliant: true
wave_0_complete: true
created: 2026-03-13
---

# Phase 5 — Validation Strategy

> Per-phase validation contract for the UI configuration checkbox phase.
> This is a WoW Lua addon — no automated unit test framework exists.
> All verification is grep-based static analysis of source files.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | None — grep/diff verification only |
| **Config file** | none |
| **Quick run command** | `grep -c "hideWhenOffCooldownCheckbox" Core/GUI.lua` |
| **Full suite command** | See Per-Task Verification Map below — run each grep in sequence |
| **Estimated runtime** | ~3 seconds |

---

## Sampling Rate

- **After every task commit:** Run quick grep verification (Check 1)
- **After every plan wave:** Run all 7 checks in sequence
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** ~3 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | Expected Result | Status |
|---------|------|------|-------------|-----------|-------------------|-----------------|--------|
| 05-01-01 | 01 | 1 | Checkbox exists in Essential/Utility settings | grep count | `grep -c "hideWhenOffCooldownCheckbox" Core/GUI.lua` | >= 1 (actual: 8) | green |
| 05-01-02 | 01 | 1 | Checkbox label is exactly "Hide When Off Cooldown" | grep match | `grep "Hide When Off Cooldown" Core/GUI.lua` | Matches line 1960 | green |
| 05-01-03 | 01 | 1 | Tooltip text is correct single line | grep match | `grep "Hides spell icons that are not on cooldown" Core/GUI.lua` | Matches line 1968 | green |
| 05-01-04 | 01 | 1 | OnValueChanged writes db setting and calls RefreshHideWhenOffCooldown | grep context | `grep -A3 'hideWhenOffCooldownCheckbox:SetCallback.*OnValueChanged' Core/GUI.lua` | Lines show db write + RefreshHideWhenOffCooldown call | green |
| 05-01-05 | 01 | 1 | No UpdateCooldownViewer in hideWhenOffCooldown callback | grep absent | `grep -A3 'hideWhenOffCooldownCheckbox:SetCallback.*OnValueChanged' Core/GUI.lua \| grep -c "UpdateCooldownViewer"` | 0 | green |
| 05-01-06 | 01 | 1 | Checkbox only exists inside Essential/Utility conditional block | grep location | `grep -n "HideWhenOffCooldown" Core/GUI.lua` | All occurrences between lines 1931-1974 (the Essential/Utility if block) | green |
| 05-01-07 | 01 | 1 | Default value is false in Defaults.lua (both Essential and Utility) | grep match | `grep "HideWhenOffCooldown" Core/Defaults.lua` | Two lines, both `= false` (lines 129 and 143) | green |

*Status: green = verified by grep at time of VALIDATION.md creation (2026-03-13)*

---

## Wave 0 Requirements

Existing grep infrastructure covers all phase requirements. No test framework needed.

All 7 checks were executed at VALIDATION.md creation time and returned expected results:

| Check | Command | Result |
|-------|---------|--------|
| 1 | `grep -c "hideWhenOffCooldownCheckbox" Core/GUI.lua` | 8 (>= 1 required) |
| 2 | `grep "Hide When Off Cooldown" Core/GUI.lua` | Match at line 1960 |
| 3 | `grep "Hides spell icons that are not on cooldown" Core/GUI.lua` | Match at line 1968 |
| 4 | Callback body grep | Lines 1963-1964: db write + RefreshHideWhenOffCooldown |
| 5 | Anti-pattern grep | 0 UpdateCooldownViewer calls in callback |
| 6 | `grep -n "HideWhenOffCooldown" Core/GUI.lua` | Lines 1961, 1963, 1964 — all inside if block at line 1931 |
| 7 | `grep "HideWhenOffCooldown" Core/Defaults.lua` | Lines 129, 143 — both `= false` |

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Checkbox visible in Essential bar settings panel | Visual appearance | AceGUI rendering requires WoW client | Open BCDM settings, navigate to Essential bar tab, confirm "Hide When Off Cooldown" checkbox appears below "Center Second Row (Horizontally)" checkbox |
| Checkbox visible in Utility bar settings panel | Visual appearance | AceGUI rendering requires WoW client | Open BCDM settings, navigate to Utility bar tab, confirm same checkbox appears |
| Checkbox unchecked by default on fresh profile | Default state | AceDB runtime initialization requires WoW client | Reset profile or use fresh character, open Essential/Utility settings, confirm checkbox is unchecked |
| Toggle ON hides off-cooldown icons instantly | Runtime behavior | Requires live cooldown state + alpha changes | Check the checkbox while spells are off cooldown; icons for those spells should disappear (alpha=0) immediately |
| Toggle OFF restores all icons instantly | Runtime behavior | Requires live RefreshHideWhenOffCooldown execution | Uncheck the checkbox; all previously hidden icons should reappear (alpha=1) immediately |
| No checkbox in Custom, Item, ItemSpell, Trinket panels | Negative visual test | Requires navigating multiple panels | Open each non-Essential/Utility bar settings panel and confirm "Hide When Off Cooldown" checkbox is absent |
| Tooltip appears on hover | GameTooltip rendering | Requires WoW tooltip system | Hover over the checkbox label; a one-line tooltip "Hides spell icons that are not on cooldown" should appear |

---

## Key Implementation References

For re-verification or future audits:

| Symbol | File | Lines | Role |
|--------|------|-------|------|
| `hideWhenOffCooldownCheckbox` | Core/GUI.lua | 1959-1973 | AceGUI CheckBox widget — full implementation |
| Essential/Utility conditional block | Core/GUI.lua | 1931-1974 | `if viewerType == "Essential" or viewerType == "Utility"` — guards checkbox rendering |
| `BCDM.db.profile.CooldownManager[viewerType].HideWhenOffCooldown` | Core/GUI.lua | 1961, 1963 | SetValue reads setting; OnValueChanged writes setting |
| `BCDM:RefreshHideWhenOffCooldown()` | Core/GUI.lua | 1964 | Instant-apply call on toggle — triggers Phase 3 alpha hiding |
| `HideWhenOffCooldown = false` | Core/Defaults.lua | 129 (Essential), 143 (Utility) | Default value — checkbox renders unchecked on fresh profile |

---

## Validation Sign-Off

- [x] All 7 tasks have automated grep commands
- [x] Sampling continuity: all checks runnable in ~3 seconds
- [x] Wave 0 covers all requirements — no missing references
- [x] No watch-mode flags
- [x] Feedback latency: ~3 seconds
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** green — all automated checks passed at creation time (2026-03-13)
