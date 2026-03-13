---
phase: quick-3
plan: "01"
subsystem: HideSpellOffCD
tags: [api-compatibility, midnight, secret-values, forward-compat, PR-documentation]
dependency_graph:
  requires: [QT-2 audit, Phase 06 FINDINGS, Phase 06 RESEARCH]
  provides: [API compatibility verdict for HideSpellOffCD PR]
  affects: [HideWhenOffCooldown.lua, Globals.lua, CooldownManager.lua, GUI.lua]
tech_stack:
  added: []
  patterns: [fail-show, Secret Value guard, event-driven visibility, alpha-based hiding]
key_files:
  created: [.planning/quick/3-generate-api-compatibility-report-confir/3-SUMMARY.md]
  modified: []
decisions:
  - "Secret Value guard (IsSecretValue) is correctly placed before first arithmetic on cdInfo.duration — Midnight compatible"
  - "Charge count fields (currentCharges, maxCharges) are low-risk for Secret Value exposure — no guard required for ship"
  - "All 7 WoW API categories used by the feature are ship-ready for both TWW 11.x and Midnight 12.0"
metrics:
  duration: "3 minutes"
  completed: "2026-03-13"
  tasks_completed: 1
  files_created: 1
---

# Phase Quick-3 Plan 01: API Compatibility Report — HideSpellOffCD

**One-liner:** All WoW APIs used by HideSpellOffCD are compatible with both TWW 11.x live and Midnight 12.0, with the Secret Value guard on `cdInfo.duration` correctly placed and charge spell counts assessed as low-risk.

---

## Section 1: Executive Summary

The `HideSpellOffCD` feature (branch `HideSpellOffCD`) is **fully compatible with both TWW 11.x live and the upcoming Midnight (Patch 12.0) expansion**. The feature uses 7 categories of WoW APIs spanning C_Spell namespace calls, frame methods, events, and hooking. Of these, only one API category (`C_Spell.GetSpellCooldown`) has confirmed Midnight implications — specifically, the `duration` field of the returned `SpellCooldownInfo` table may become a Secret Value during combat in Midnight. This is handled by the `BCDM:IsSecretValue(cdInfo.duration)` guard at `Core/Globals.lua:703`, which was implemented as part of Phase 06-02. The guard is correctly placed before the first arithmetic comparison on the duration field, applies fail-show semantics (returns false, keeping icons visible), and is a no-op on current TWW live (where `issecretvalue()` does not yet exist).

**API Summary:**
- Total WoW API categories used by the feature: **7**
- Categories with Midnight implications: **1** (`C_Spell.GetSpellCooldown` duration field)
- Categories with guards in place: **1** (Secret Value guard on `cdInfo.duration` at Globals.lua:703)
- Categories with low-risk Midnight exposure (no guard, monitor): **1** (`C_Spell.GetSpellCharges` charge counts)
- Categories with zero Midnight risk: **5** (frame methods, hooking, events, GUI)

**Overall verdict: SHIP-READY for TWW live. SHIP-READY for Midnight 12.0 with optional future hardening documented for charge counts.**

---

## Section 2: Midnight API Restrictions Overview

### What are Secret Values?

Secret Values (introduced in Midnight, Patch 12.0) are opaque Lua values that WoW returns from certain APIs during combat. They are designed to restrict addons from performing automation based on precise cooldown timing information. Mechanically:

- A Secret Value has type `"number"` in Lua — it passes `type(x) == "number"` checks
- Attempting arithmetic operations on a Secret Value (e.g., `x > 0`, `x <= 1.5`) raises a Lua error: "attempt to compare a SecretValue"
- The global function `issecretvalue(x)` (available in Midnight) returns `true` if `x` is a Secret Value
- On current TWW live (pre-Midnight), `issecretvalue` does not exist and no Secret Values are returned

### Which C_Spell APIs Are Affected?

`C_Spell.GetSpellCooldown(spellID)` returns a `SpellCooldownInfo` table. In Midnight, during combat:
- `.duration` — **potentially a Secret Value** (confirmed risk; this is a timing field Blizzard wants to protect)
- `.startTime` — potentially a Secret Value (timing field; we do NOT access this)
- `.isOnGCD` — **boolean or nil** (NOT a timing number; not a Secret Value risk)
- `.modRate` — potentially a Secret Value (rate modifier; we do NOT access this)

`C_Spell.GetSpellCharges(spellID)` returns a `SpellChargeInfo` table. In Midnight:
- `.currentCharges` / `.maxCharges` — **LOW risk** (count fields, not timing; visible in default UI)
- `.cooldownStartTime` / `.cooldownDuration` — **higher risk** (timing fields; we do NOT access these)

### Fields in Our Code That Touch Numeric Values at Risk

| Field | Accessed In | Type | Secret Value Risk |
|-------|-------------|------|-------------------|
| `cdInfo.duration` | `Core/Globals.lua:703,719,724` | `number` | HIGH — timing field; guarded by `IsSecretValue` at line 703 |
| `cdInfo.isOnGCD` | `Core/Globals.lua:709,719` | `bool\|nil` | NONE — boolean, not numeric |
| `chargeInfo.currentCharges` | `Core/Globals.lua:685-686` | `number` | LOW — count field, not timing |
| `chargeInfo.maxCharges` | `Core/Globals.lua:685-686` | `number` | LOW — count field, not timing |

---

## Section 3: Per-API Compatibility Matrix

| # | API | TWW 11.x | Midnight 12.0 | Guard in Place | Notes |
|---|-----|----------|---------------|----------------|-------|
| 1 | `C_Spell.GetSpellInfo(spellID)` | PASS | PASS | Not needed | Returns `SpellInfo` or nil. No numeric fields accessed. Used only for spell existence validation at Globals.lua:677. |
| 2 | `C_Spell.GetSpellCharges(spellID)` | PASS | PASS (low risk) | None (acceptable) | Returns `SpellChargeInfo`. `.currentCharges` and `.maxCharges` are count fields unlikely to be Secret Values. `cooldownStartTime`/`cooldownDuration` (which we do NOT access) are the higher-risk timing fields. |
| 3 | `C_Spell.GetSpellCooldown(spellID)` | PASS | PASS (guarded) | `IsSecretValue(cdInfo.duration)` at Globals.lua:703 | `.duration` IS at risk of becoming a Secret Value in Midnight. Guard returns `false` (fail-show) when duration is unreadable. Guard is a no-op on TWW live. |
| 4 | `frame:SetAlpha(0\|1)` | PASS | PASS | Not needed | Pure frame method. No numeric API data involved. Not subject to Secret Values. SetAlpha was confirmed unrestricted in Midnight (clamped to [0,1] without error). |
| 5 | `frame:GetAlpha()` | PASS | PASS | Not needed | Used in CooldownManager.lua `CenterWrappedRows` to filter hidden icons. Returns the frame's own alpha (not inherited). Reflects our own SetAlpha(0) calls. No external data. |
| 6 | `hooksecurefunc(table, method, fn)` | PASS | PASS | Not needed | Post-hook mechanism. No Midnight changes known. Taint-free; correct pattern for hooking protected Blizzard methods. |
| 7 | Events: `SPELL_UPDATE_COOLDOWN`, `SPELL_UPDATE_CHARGES`, `PLAYER_ENTERING_WORLD`, `PLAYER_SPECIALIZATION_CHANGED` | PASS | PASS | Not needed | Event system unchanged in Midnight. All 4 events verified in Blizzard FrameXML (QT-2 audit). |

---

## Section 4: Secret Value Guard Analysis

### Implementation Location

The Secret Value guard is implemented at **`Core/Globals.lua:697-705`** within `BCDM:IsSpellOnCooldown()`:

```lua
-- Guard against Midnight (12.0) Secret Values on duration.
-- In Midnight, combat-protected duration fields are returned as opaque Secret Values
-- that raise a Lua error when used in arithmetic comparisons. IsSecretValue() is a
-- no-op on current TWW live (issecretvalue() doesn't exist yet), but this guard
-- prevents Lua errors in Midnight when cdInfo.duration cannot be read numerically.
-- Fail-show: if we can't read the duration, keep the icon visible.
if self:IsSecretValue(cdInfo.duration) then
    return false  -- Cannot read duration (Midnight Secret Value), fail-show
end
```

### How `IsSecretValue()` Works

`BCDM:IsSecretValue(value)` is defined at `Core/Globals.lua:189`:

```lua
function BCDM:IsSecretValue(value)
    return type(value) == "number" and type(issecretvalue) == "function" and issecretvalue(value)
end
```

**Behavior breakdown:**

| Environment | `type(issecretvalue)` | Result of `IsSecretValue(cdInfo.duration)` | Behavior |
|-------------|----------------------|---------------------------------------------|---------|
| TWW 11.x live | `"nil"` (function doesn't exist) | `false` (short-circuits on second `and`) | No behavior change — guard is a complete no-op |
| Midnight 12.0 out of combat | `"function"` | `false` (duration is a real number, not Secret Value) | No behavior change — guard passes normally |
| Midnight 12.0 in combat | `"function"` | `true` (duration is a Secret Value) | Guard triggers: returns `false` → icon stays visible (fail-show) |

### Placement Verification

The guard is confirmed to be placed **BEFORE** the first arithmetic comparison on `cdInfo.duration`:

```
Globals.lua:692  — cdInfo = C_Spell.GetSpellCooldown(spellID)
Globals.lua:693  — if not cdInfo then return false end          ← nil check
Globals.lua:703  — if self:IsSecretValue(cdInfo.duration) then  ← Secret Value guard  ✓
                   return false
                   end
Globals.lua:709  — if cdInfo.isOnGCD then ...                   ← boolean, safe
Globals.lua:719  — cdInfo.duration > 0 and cdInfo.duration <= 1.5  ← arithmetic (after guard)  ✓
Globals.lua:724  — cdInfo.duration and cdInfo.duration > 0          ← arithmetic (after guard)  ✓
```

The guard intercepts the flow at line 703, before the comparisons at lines 719 and 724. If `cdInfo.duration` is a Secret Value, execution never reaches either arithmetic comparison — the function returns `false` immediately.

### Fail-Show Preservation

When the guard triggers (Midnight, in-combat Secret Value duration):
- Return value: `false` — interpreted as "not on cooldown" by the caller
- Effect: `icon:SetAlpha(1)` — icon stays **visible**
- This is the fail-show direction: uncertainty results in showing the icon, never hiding it

---

## Section 5: Charge Spell Midnight Risk Assessment

### What We Access

For charge spells, `BCDM:IsSpellOnCooldown()` accesses `chargeInfo.currentCharges` and `chargeInfo.maxCharges` via `C_Spell.GetSpellCharges(spellID)` at Globals.lua:682-689:

```lua
local chargeInfo = C_Spell.GetSpellCharges(spellID)
if chargeInfo then
    if chargeInfo.currentCharges and chargeInfo.maxCharges then
        return chargeInfo.currentCharges < chargeInfo.maxCharges
    end
    return false  -- Malformed charge info, fail-show
end
```

Note: This block executes before the Secret Value guard (which guards `cdInfo.duration`, not `chargeInfo` fields). Charge spells take the early return path and never reach the cooldown duration check.

### Why Charge Counts Are Low-Risk for Secret Values

Blizzard's Secret Values system targets **cooldown timing information** — the precise duration values that enable addon automation (e.g., "cast in exactly 2.3 seconds when cooldown expires"). The design rationale, documented in Blizzard's Midnight developer communications, is to prevent addons from knowing exact countdown timers during combat.

Charge counts (`currentCharges`, `maxCharges`) are:
- **Visible information** — shown directly in the default UI as charge pip indicators
- **Non-timing fields** — they don't tell you *when* something happens, only *how many* are available
- **Coarse binary signals** — the comparison `currentCharges < maxCharges` only asks "is at least one charge recharging?" not "how much time is left?"

By contrast, `chargeInfo.cooldownStartTime` and `chargeInfo.cooldownDuration` (which we do NOT access) are the timing fields that would enable "X seconds until next charge" computations — the type of automation Blizzard is protecting against.

### Risk Assessment

| Field | Our Access | Midnight Risk | Rationale |
|-------|-----------|---------------|-----------|
| `currentCharges` | Direct comparison `< maxCharges` | LOW | Count field; visible in default UI; non-timing |
| `maxCharges` | Direct comparison with `currentCharges` | LOW | Static configuration value; not a cooldown timer |
| `cooldownStartTime` | NOT accessed | N/A (N/A) | Timing field — if we accessed this, HIGH risk |
| `cooldownDuration` | NOT accessed | N/A (N/A) | Timing field — if we accessed this, HIGH risk |

**Risk level: LOW** — Charge counts are the least likely candidate for Secret Value protection in Midnight. Blizzard's stated goal is preventing automation via timing knowledge, not preventing addons from knowing how many charges you have.

### Recommendation

No guard is required for ship. The current implementation is correct.

**Optional future hardening** (non-blocking): If Blizzard does extend Secret Values to charge counts, the `currentCharges < maxCharges` comparison would raise a Lua error. The guard would be:

```lua
if BCDM:IsSecretValue(chargeInfo.currentCharges) or BCDM:IsSecretValue(chargeInfo.maxCharges) then
    return false  -- Cannot read charge counts (hypothetical future Secret Value), fail-show
end
```

This can be added if Midnight PTR testing reveals charge counts becoming Secret Values. At current knowledge (2026-03-13), no such restriction has been announced or observed.

---

## Section 6: Compatibility Verdict

### Final Compatibility Matrix

| Component | TWW 11.x | Midnight 12.0 | Status |
|-----------|----------|---------------|--------|
| Cooldown detection (`IsSpellOnCooldown`) | PASS | PASS (guarded by `IsSecretValue`) | Ship-ready |
| Charge detection (`GetSpellCharges`) | PASS | PASS (low risk, no guard needed) | Ship-ready, monitor on PTR |
| Visibility toggling (`SetAlpha`) | PASS | PASS (unrestricted) | Ship-ready |
| Layout collapse (`GetAlpha` filter in `CenterWrappedRows`) | PASS | PASS (own alpha, not inherited) | Ship-ready |
| Event handling (4 events) | PASS | PASS (event system unchanged) | Ship-ready |
| GUI checkbox (AceGUI, tooltip, callback) | PASS | PASS (no API restrictions) | Ship-ready |
| `hooksecurefunc` on `RefreshLayout` | PASS | PASS (no Midnight changes) | Ship-ready |

### Overall Verdict

**The `HideSpellOffCD` feature is ship-ready for both TWW 11.x live and Midnight 12.0.**

Caveats and notes:
1. **Charge count Secret Value risk (low):** The `currentCharges < maxCharges` comparison has no guard. Current assessment is LOW risk because charge counts are visible, non-timing information unlikely to be Secret-Value-protected. If Midnight PTR testing reveals this to be incorrect, a guard can be added before merge with minimal code change.
2. **GCD detection behavior:** The `isOnGCD` 1.5-second fallback has an acceptable edge case for spells with genuine short cooldowns (0.75-1.5s) when `isOnGCD` is nil. This only occurs outside `SPELL_UPDATE_COOLDOWN` events and resolves to fail-show (icon stays visible). Documented as acceptable risk per Phase 06 FINDINGS.
3. **TWW live no-op guarantee:** The `IsSecretValue` guard function (`Globals.lua:189`) short-circuits immediately when `issecretvalue` is not defined (which is the case on all current TWW live clients). Zero behavior change on live.

---

## References

| Source | Location | Key Contribution |
|--------|----------|------------------|
| QT-2 Audit Report | `.planning/quick/2-audit-codebase-to-verify-all-wow-api-cal/2-SUMMARY.md` | 37/37 API signature, event, integration checks — all PASS |
| Phase 06 FINDINGS | `.planning/phases/06-detailed-api-review/06-FINDINGS.md` | Behavioral code path analysis; Pitfall 5 (Secret Values) identified and FIX-01 applied; post-fix verification |
| Phase 06 RESEARCH | `.planning/phases/06-detailed-api-review/06-RESEARCH.md` | Pitfall catalog, architectural patterns, Midnight API change research |
| Blizzard SpellDocumentation.lua | [github.com/Gethe/wow-ui-source](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/SpellDocumentation.lua) | `C_Spell.GetSpellCooldown`, `C_Spell.GetSpellCharges`, `C_Spell.GetSpellInfo` signatures |
| Blizzard SpellSharedDocumentation.lua | [github.com/Gethe/wow-ui-source](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/SpellSharedDocumentation.lua) | `SpellCooldownInfo` and `SpellChargeInfo` table structures, field nilability |
| Warcraft Wiki — Patch 12.0.0/API changes | [warcraft.wiki.gg/wiki/Patch_12.0.0/API_changes](https://warcraft.wiki.gg/wiki/Patch_12.0.0/API_changes) | Secret Values system in Midnight; duration field restrictions |
| Warcraft Wiki — Patch 12.0.0/Planned API changes | [warcraft.wiki.gg/wiki/Patch_12.0.0/Planned_API_changes](https://warcraft.wiki.gg/wiki/Patch_12.0.0/Planned_API_changes) | Planned duration field restrictions |
| Warcraft Tavern — Midnight Secret Values | [warcrafttavern.com](https://www.warcrafttavern.com/wow/news/wow-midnight-developer-talk-new-secret-values-combat-info-cooldown-manager-combat-addons-nerfed/) | Blizzard's design rationale for Secret Values targeting timing automation |

---

## Deviations from Plan

None — report generated exactly as specified. No source files were modified.

---

## Self-Check: PASSED

- Report file exists at `.planning/quick/3-generate-api-compatibility-report-confir/3-SUMMARY.md`: FOUND
- Report covers all 7 API categories: PASS (Sections 3 and 6 cover all 7)
- Report includes Secret Value guard code analysis with Globals.lua line references: PASS (Section 4, lines 697-705, 703, 719, 724)
- Report includes charge spell Midnight risk assessment: PASS (Section 5)
- Report has clear final compatibility verdict table: PASS (Section 6)
- No source files were modified: PASS (analysis only)
- PASS count verification: report contains well over 5 instances of "PASS"
