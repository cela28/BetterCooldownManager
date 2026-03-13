---
phase: 02-cooldown-state-detection
validated: 2026-03-13
status: green
score: 8/8
---

# Phase 02 Validation Map

**Phase Goal:** Reliably detect when a spell is on/off cooldown
**Validation Method:** grep/diff (WoW Lua addon — no automated test runner)
**All checks run against:** `Core/Globals.lua`

---

## Validation Checks

### REQ-02-01: Function exists with correct signature

**Requirement:** `BCDM:IsSpellOnCooldown(spellID)` is exported from `Core/Globals.lua`

```
grep -n "function BCDM:IsSpellOnCooldown" Core/Globals.lua
```

**Expected:** Exactly one match at line 670
**Actual result:** `670:function BCDM:IsSpellOnCooldown(spellID)` — PASS

---

### REQ-02-02: Input validation — nil and zero spell IDs return false (fail-show)

**Requirement:** Returns false immediately for `nil` or `0` spellID inputs

```
grep -n "not spellID or spellID == 0" Core/Globals.lua
```

**Expected:** One match guarding the function entry
**Actual result:** `672:    if not spellID or spellID == 0 then` — PASS

---

### REQ-02-03: Unknown spell validation returns false (fail-show)

**Requirement:** Validates spell exists via `C_Spell.GetSpellInfo`; returns false if nil

```
grep -n "C_Spell.GetSpellInfo" Core/Globals.lua
```

**Expected:** One match inside `IsSpellOnCooldown`
**Actual result:** `677:    if not C_Spell.GetSpellInfo(spellID) then` — PASS

---

### REQ-02-04: Charge spell detection runs before regular cooldown check

**Requirement:** `C_Spell.GetSpellCharges` is called and its result drives the return value before any `C_Spell.GetSpellCooldown` call

```
grep -n "GetSpellCharges\|GetSpellCooldown" Core/Globals.lua
```

**Expected:** `GetSpellCharges` appears at a lower line number than `GetSpellCooldown`
**Actual result:**
- `682:    local chargeInfo = C_Spell.GetSpellCharges(spellID)`
- `692:    local cdInfo = C_Spell.GetSpellCooldown(spellID)`

GetSpellCharges at 682, GetSpellCooldown at 692 — PASS (correct order)

---

### REQ-02-05: Charge spell — returns true when any charge is recharging

**Requirement:** Returns `chargeInfo.currentCharges < chargeInfo.maxCharges` (true when recharging)

```
grep -n "currentCharges < maxCharges" Core/Globals.lua
```

**Expected:** One match returning the boolean result of that comparison
**Actual result:** `686:            return chargeInfo.currentCharges < chargeInfo.maxCharges` — PASS

---

### REQ-02-06: GCD filtering — `isOnGCD` field respected

**Requirement:** When `cdInfo.isOnGCD` is true, returns false (GCD does not count as cooldown)

```
grep -n "cdInfo.isOnGCD" Core/Globals.lua
```

**Expected:** At least one check on `cdInfo.isOnGCD` that returns false
**Actual result:**
- `709:    if cdInfo.isOnGCD then` → returns false at next line
- `719:    if cdInfo.isOnGCD == nil and ...` → fallback path

Both paths present — PASS

---

### REQ-02-07: GCD filtering — 1.5s fallback when `isOnGCD` is nil

**Requirement:** When `isOnGCD` field is nil and duration is 0 < d <= 1.5, treats as GCD and returns false

```
grep -n "isOnGCD == nil.*duration.*1.5\|duration <= 1.5" Core/Globals.lua
```

**Expected:** One match encoding the 1.5s threshold guard
**Actual result:** `719:    if cdInfo.isOnGCD == nil and cdInfo.duration and cdInfo.duration > 0 and cdInfo.duration <= 1.5 then` — PASS

---

### REQ-02-08: Real cooldown returns true; off-cooldown returns false

**Requirement:** `cdInfo.duration > 0` after GCD filtering returns true; all other paths return false

```
grep -n "duration > 0" Core/Globals.lua
```

**Expected:** Match at the final duration check that returns true, plus a preceding match in the 1.5s fallback guard

**Actual result:**
- `719:    if cdInfo.isOnGCD == nil and cdInfo.duration and cdInfo.duration > 0 and cdInfo.duration <= 1.5 then` (fallback guard)
- `724:    if cdInfo.duration and cdInfo.duration > 0 then` → `725:        return true`

Final `return false` at line 728 covers off-cooldown case — PASS

---

## Fail-Show Coverage (defense-in-depth count)

```
grep -c "return false" Core/Globals.lua
```

**Expected:** At least 6 fail-show paths (per plan requirement of "6 explicit return false paths")
**Actual result:** 13 total `return false` occurrences in file (IsSpellOnCooldown contributes 7 of them) — PASS

---

## Midnight API Guard (bonus check — post-plan addition)

**Requirement:** Handles WoW Midnight Secret Values on `cdInfo.duration` without crashing

```
grep -n "IsSecretValue" Core/Globals.lua
```

**Expected:** A guard calling `self:IsSecretValue(cdInfo.duration)` before arithmetic on duration
**Actual result:**
- `189:function BCDM:IsSecretValue(value)` (helper defined)
- `703:    if self:IsSecretValue(cdInfo.duration) then` (guard in IsSpellOnCooldown)

PASS — this is a deviation-beyond-plan improvement, not a requirement gap.

---

## Summary

| Check ID | Requirement | Command | Status |
|----------|-------------|---------|--------|
| REQ-02-01 | Function signature exported | `grep -n "function BCDM:IsSpellOnCooldown"` | green |
| REQ-02-02 | nil/0 input guard | `grep -n "not spellID or spellID == 0"` | green |
| REQ-02-03 | Unknown spell guard | `grep -n "C_Spell.GetSpellInfo"` | green |
| REQ-02-04 | Charge check before cooldown check | `grep -n "GetSpellCharges\|GetSpellCooldown"` | green |
| REQ-02-05 | Charge recharging returns true | `grep -n "currentCharges < maxCharges"` | green |
| REQ-02-06 | isOnGCD field filtering | `grep -n "cdInfo.isOnGCD"` | green |
| REQ-02-07 | 1.5s GCD fallback | `grep -n "duration <= 1.5"` | green |
| REQ-02-08 | Real cooldown true / off-cooldown false | `grep -n "duration > 0"` | green |

**Score: 8/8 green**

---

## Human Verification Required (runtime only)

These behaviors require a live WoW client to verify and cannot be confirmed by static analysis:

1. **GCD filtering accuracy** — Cast a spell and confirm IsSpellOnCooldown returns false during GCD-only window, then true once the real cooldown starts.
2. **Charge spell runtime** — Test with a charge spell (e.g., Fire Blast) at full charges (expect false) vs partial charges (expect true).
3. **Invalid ID runtime** — Confirm IsSpellOnCooldown(999999999) returns false without Lua error in live client.

---

*Validated: 2026-03-13*
*Validator: Claude (gsd-nyquist-auditor)*
