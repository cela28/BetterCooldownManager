---
phase: 01-settings-infrastructure
validated: 2026-03-13
validator: gsd-nyquist-auditor
status: PARTIAL
resolved: 4/5
escalated: 1/5
---

# Phase 01: Settings Infrastructure — Validation

**Phase Goal:** Add the per-bar setting to enable/disable hiding
**Validation Method:** grep/diff (WoW Lua addon — no automated test framework)

---

## Validation Map

| # | Requirement | Command | Expected | Actual | Status |
|---|-------------|---------|----------|--------|--------|
| 1 | HideWhenOffCooldown default in Essential section | `grep -n "HideWhenOffCooldown" Core/Defaults.lua` | 2 matches (lines ~129, ~143) | Line 129, Line 143 | GREEN |
| 2 | HideWhenOffCooldown default in Utility section | (same command as #1) | Match in Utility block | Line 143 | GREEN |
| 3 | Both defaults are `false` | `grep "HideWhenOffCooldown = false" Core/Defaults.lua` | 2 matches | 2 matches | GREEN |
| 4 | `BCDM:GetHideWhenOffCooldown` exists and uses correct db path | `grep -n "GetHideWhenOffCooldown\|CooldownManager\[barType\]" Core/Globals.lua` | Function def + db path usage | Lines 644, 646 | GREEN |
| 5 | `BCDM:SetHideWhenOffCooldown` exists | `grep -n "SetHideWhenOffCooldown" Core/Globals.lua` | Function definition present | No output — function ABSENT | RED |
| 6 | `BCDM:IsHideWhenOffCooldownEnabled` exists and uses mapping table | `grep -n "IsHideWhenOffCooldownEnabled\|CooldownManagerViewerToDBViewer" Core/Globals.lua` | Function def + mapping lookup | Lines 651, 652 | GREEN |

---

## Runnable Verification Commands

Run these from the repository root to reproduce all checks:

```bash
# Check 1 & 2: HideWhenOffCooldown present for both bar types
grep -n "HideWhenOffCooldown" Core/Defaults.lua
# Expected: exactly 2 lines — one in Essential block (~129), one in Utility block (~143)

# Check 3: Both default to false
grep -c "HideWhenOffCooldown = false" Core/Defaults.lua
# Expected: 2

# Check 4: Getter function exists with correct db path
grep -n "GetHideWhenOffCooldown\|CooldownManager\[barType\]" Core/Globals.lua
# Expected: 3 lines — function def, nil guard return, db path access

# Check 5: Setter function exists (CURRENTLY FAILING)
grep -n "SetHideWhenOffCooldown" Core/Globals.lua
# Expected: 1+ lines showing function definition
# Actual: no output

# Check 6: Helper function exists and uses mapping table
grep -n "IsHideWhenOffCooldownEnabled\|CooldownManagerViewerToDBViewer" Core/Globals.lua
# Expected: 3 lines — mapping table definition (~9), function def (~651), lookup usage (~652)
```

---

## Resolved Checks (4/5)

| Check | Requirement | Evidence |
|-------|-------------|----------|
| Defaults.lua Essential | `HideWhenOffCooldown = false` in Essential block | Line 129 |
| Defaults.lua Utility | `HideWhenOffCooldown = false` in Utility block | Line 143 |
| `GetHideWhenOffCooldown` | Function defined, uses `self.db.profile.CooldownManager[barType]` | Lines 644–648 |
| `IsHideWhenOffCooldownEnabled` | Function defined, uses `CooldownManagerViewerToDBViewer` mapping | Lines 651–654 |

---

## Escalated — Implementation Bug (1/5)

### MISSING: `BCDM:SetHideWhenOffCooldown`

**Requirement (01-01-PLAN.md):**
> `BCDM:SetHideWhenOffCooldown(barType, value)` — stores boolean setting value for a bar type

**Expected (from plan):**
```lua
function BCDM:SetHideWhenOffCooldown(barType, value)
    if not barType then return end
    local barSettings = self.db.profile.CooldownManager[barType]
    if barSettings then
        barSettings.HideWhenOffCooldown = value
    end
end
```

**Actual:** Function does not exist in `Core/Globals.lua`. The grep `grep -n "SetHideWhenOffCooldown" Core/Globals.lua` returns no output.

**Impact:**
- No module can currently write the setting. The GUI toggle (phase 01-02) has no way to persist user changes.
- `01-VERIFICATION.md` incorrectly recorded this as VERIFIED at "lines 600-607" — those lines contain anchor table data, not this function. The verification report was inaccurate.

**Recommended fix (implementation file — DO NOT modify in validation):**
Add `BCDM:SetHideWhenOffCooldown` to `Core/Globals.lua` after `GetHideWhenOffCooldown` (around line 649), following the exact body specified in 01-01-PLAN.md task 2.

---

## Notes

- `Core/Defaults.lua` line count is 516+ (AceDB handles persistence automatically — no additional wiring needed for storage).
- `Core/Globals.lua` current line count is 729 (grew beyond the 614 lines cited in VERIFICATION.md due to later phases adding code).
- The `CooldownManagerViewerToDBViewer` mapping table at lines 9–13 correctly maps `EssentialCooldownViewer` → `"Essential"` and `UtilityCooldownViewer` → `"Utility"`, satisfying the wiring requirement for `IsHideWhenOffCooldownEnabled`.
- Human verification still required for: addon loads without Lua errors in actual WoW client.
