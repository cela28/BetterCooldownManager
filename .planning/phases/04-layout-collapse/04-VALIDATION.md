---
phase: 4
slug: layout-collapse
status: green
nyquist_compliant: true
wave_0_complete: true
created: 2026-03-13
---

# Phase 4 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | None — WoW Lua addon, grep/diff verification |
| **Config file** | none |
| **Quick run command** | `grep -n "collapseEnabled\|GetAlpha\|IsHideWhenOffCooldownEnabled" Modules/CooldownManager.lua` |
| **Full suite command** | See Per-Task Verification Map below — run each command in sequence |
| **Estimated runtime** | ~3 seconds |

---

## Sampling Rate

- **After every task commit:** Run quick grep verification
- **After every plan wave:** Run all five grep checks
- **Before `/gsd:verify-work`:** All checks must return expected values
- **Max feedback latency:** 3 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | Expected Output | Status |
|---------|------|------|-------------|-----------|-------------------|-----------------|--------|
| 04-01-01 | 01 | 1 | Feature toggle guard present in CenterWrappedRows | grep | `grep -n "IsHideWhenOffCooldownEnabled(viewerName)" Modules/CooldownManager.lua` | Line 227 match | green |
| 04-01-02 | 01 | 1 | Alpha filtering uses `> 0` (not `== 1`) guarded by toggle | grep | `grep -n "not collapseEnabled or childFrame:GetAlpha() > 0" Modules/CooldownManager.lua` | Line 237 match | green |
| 04-01-03 | 01 | 1 | Sort by layoutIndex preserved for icon order restoration | grep | `grep -n "table.sort(visibleIcons" Modules/CooldownManager.lua` | Line 243 match | green |
| 04-01-04 | 01 | 1 | Early return on visibleCount == 0 (empty bar stays visible) | grep | `grep -n "if visibleCount == 0 then return end" Modules/CooldownManager.lua` | Line 246 match | green |
| 04-01-05 | 01 | 1 | Centering math unchanged — center-compacted rows | grep | `grep -n "startX = -rowWidth / 2 + iconWidth / 2" Modules/CooldownManager.lua` | Line 271 match | green |
| 04-01-06 | 01 | 1 | Bar container dimensions not modified in CenterWrappedRows | grep | `grep -n "SetWidth\|SetHeight\|SetSize" Modules/CooldownManager.lua` | Only lines 103, 345 (icon sizing in StyleIcons/UpdateCooldownViewer, not in CenterWrappedRows lines 220-280) | green |
| 04-01-07 | 01 | 1 | CenterWrappedRows wired to both viewers via CenterWrappedIcons | grep | `grep -n "CenterWrappedRows" Modules/CooldownManager.lua` | Lines 287 and 288 — EssentialCooldownViewer and UtilityCooldownViewer | green |

*Status: green · pending · red · flaky*

---

## Verification Commands (Copy-Paste Ready)

Run all checks in sequence from the repo root:

```bash
# CHECK 1: Feature toggle guard
grep -n "IsHideWhenOffCooldownEnabled(viewerName)" Modules/CooldownManager.lua
# Expected: Modules/CooldownManager.lua:227:    local collapseEnabled = BCDM:IsHideWhenOffCooldownEnabled(viewerName)

# CHECK 2: Alpha filter guard pattern
grep -n "not collapseEnabled or childFrame:GetAlpha() > 0" Modules/CooldownManager.lua
# Expected: line 237 match

# CHECK 3: layoutIndex sort preserved
grep -n "table.sort(visibleIcons" Modules/CooldownManager.lua
# Expected: line 243 match

# CHECK 4: Empty bar early return
grep -n "if visibleCount == 0 then return end" Modules/CooldownManager.lua
# Expected: line 246 match

# CHECK 5: Center-compacting math
grep -n "startX = -rowWidth / 2 + iconWidth / 2" Modules/CooldownManager.lua
# Expected: line 271 match

# CHECK 6: No bar frame resize in CenterWrappedRows (lines 220-280)
grep -n "SetWidth\|SetHeight\|SetSize" Modules/CooldownManager.lua
# Expected: only lines 103 and 345 (icon sizing) — no hits inside CenterWrappedRows

# CHECK 7: Both viewers wired
grep -n "CenterWrappedRows" Modules/CooldownManager.lua
# Expected: line 220 (definition), 287 (Essential), 288 (Utility)
```

---

## Wave 0 Requirements

No test framework exists for WoW Lua addons in this project. All verification is grep-based with deterministic expected outputs. All 7 checks above cover the full requirement set for this phase. No additional infrastructure needed.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Visible icons shift to fill gaps when icons go off cooldown | Layout reflow | Requires WoW client | Enable HideWhenOffCooldown for a bar, cast spells, confirm remaining icons compact toward center |
| Multi-row bar: row 2 icons move to row 1 when row 1 empties | Multi-row reflow | Requires WoW client | Configure a bar with more icons than fit in one row; hide row 1 icons; confirm row 2 shifts up |
| Icon returns to original configured position on reappearance | layoutIndex restoration | Requires WoW client | Let a hidden icon reappear (spell comes off cooldown); confirm it appears in its original slot |
| Bar frame stays at full dimensions when all icons hidden | Bar container unchanged | Requires WoW client | Hide all icons; confirm bar outline / frame remains same size |
| Layout collapse does NOT activate when feature is disabled | Feature toggle guard | Requires WoW client | Disable HideWhenOffCooldown for a bar; hide icons via other means; confirm layout does not reflow |

---

## Validation Sign-Off

- [x] All tasks have automated grep commands with expected outputs
- [x] Sampling continuity: single-task phase, all checks verified
- [x] Wave 0 covers all requirements — no automated test runner needed
- [x] No watch-mode flags
- [x] Feedback latency < 5s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** green — all 7 grep checks confirmed passing against current codebase
