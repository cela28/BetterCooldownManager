# Phase 6: Detailed API Review - Research

**Researched:** 2026-03-13
**Domain:** WoW addon behavioral correctness, API contract verification, scenario coverage
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Verification depth:**
- Behavioral verification: Trace every code path through our 4 files and verify each branch produces correct in-game behavior
- Full scenario matrix: Build a complete matrix of WoW scenarios (combat lockdown, loading screens, spec changes, charge spells, GCD edge cases, talent swaps, etc.) and verify our code handles each one
- API contract deep-dive: Cross-reference Blizzard FrameXML source for undocumented behaviors, timing constraints, return value quirks, and nilability guarantees that could affect our code

**Files in scope:**
- `Core/Globals.lua` — HideWhenOffCooldown setting API (lines 641-724) and IsSpellOnCooldown function
- `Modules/HideWhenOffCooldown.lua` — Core visibility module (entire file, our addition)
- `Core/GUI.lua` — Checkbox addition and RefreshHideWhenOffCooldown integration
- `Core/CooldownManager.lua` — Changes to CenterWrappedRows for alpha filtering and EnableHideWhenOffCooldown call

**Output approach:**
- Report + auto-fix: Find issues and commit fixes directly in the same phase
- Each fix should preserve the fail-show philosophy (errors → show icon, don't hide)

**Fix scope boundary:**
- Only fix code we added or modified in the HideSpellOffCD branch
- Do NOT touch pre-existing bugs in files we edited (e.g., existing CooldownManager.lua patterns)
- Do NOT refactor untouched code even if related

### Claude's Discretion
- Specific order of verification checks
- How to structure the scenario matrix document
- Whether to use pcall wrapping or inline nil checks for hardening

### Deferred Ideas (OUT OF SCOPE)
- Broader codebase API hardening (CONCERNS.md items outside our branch) — future phase or separate effort
- Integration test framework for WoW addon testing — out of scope
</user_constraints>

---

## Summary

Phase 6 is a deep behavioral correctness review of the four files modified in the HideSpellOffCD branch. The QT-2 audit (37/37 PASS) confirmed that every API signature, event name, and function reference is correct. This phase goes deeper: it verifies that each code path produces the right in-game outcome across the full space of WoW game states (combat lockdown, loading screens, spec changes, charge spells, GCD edge cases, etc.) and that API contracts are honored at the behavioral level, not just the signature level.

The code is well-structured and follows established BCM patterns. Research identified five specific behavioral concerns that deserve careful scrutiny during the review: (1) the `isOnGCD` nilability and the 1.5-second GCD fallback threshold, (2) the charge spell logic when all charges are full, (3) the timing gap between `EnableHideWhenOffCooldown()` at addon init and viewer frame availability, (4) the `hooksecurefunc` on `RefreshLayout` being called before hooks are set, and (5) the `GetAlpha() > 0` alpha filter in `CenterWrappedRows` and its interaction with other systems. There is also a forward-looking concern: the Midnight expansion (Patch 12.0) is introducing "Secret Values" that will restrict direct numeric reads of cooldown duration from addon code during combat — a behavioral change that our IsSpellOnCooldown approach will need to handle.

**Primary recommendation:** Structure the phase as three sequential plans — (1) code path trace and behavioral verification for each of the 4 files, (2) scenario matrix construction and gap analysis, (3) targeted fixes for any issues found — ensuring each fix is isolated and preserves fail-show semantics.

---

## Standard Stack

### Core
| Library / API | Version | Purpose | Why Standard |
|---|---|---|---|
| `C_Spell.GetSpellCooldown(spellID)` | Added 11.0.0 | Get cooldown state | Modern replacement for deprecated `GetSpellCooldown()`; returns `SpellCooldownInfo` table |
| `C_Spell.GetSpellCharges(spellID)` | Added 11.0.0 | Get charge state | Returns `SpellChargeInfo` table; `MayReturnNothing=true` for non-charge spells |
| `C_Spell.GetSpellInfo(spellID)` | Added 11.0.0 | Validate spell exists | Safe to call; returns nil if invalid |
| `hooksecurefunc(table, method, fn)` | Classic WoW+ | Post-hook Blizzard functions without taint | The only correct way to hook protected methods without causing taint |
| `frame:SetAlpha(0\|1)` | Classic WoW+ | Hide/show icon without destroying frame | Preserves frame state; non-restricted; does not trigger secure frame restrictions |

### Supporting
| Reference | Purpose | Notes |
|---|---|---|
| `SPELL_UPDATE_COOLDOWN` event | Triggers visibility refresh | Fires on GCD, spell casts, cooldown expiry |
| `SPELL_UPDATE_CHARGES` event | Triggers visibility refresh for charge spells | Fires when charge count changes |
| `PLAYER_ENTERING_WORLD` event | Initial state sync on login/reload/zone change | Takes `isInitialLogin`, `isReloadingUi` params (added patch 8.0.1) |
| `PLAYER_SPECIALIZATION_CHANGED` event | Re-evaluate cooldown state after spec change | Spell IDs can change between specs |
| `frame.cooldownInfo` | Per-icon spell metadata set by Blizzard CooldownViewer | Contains `spellID` and `overrideSpellID` |

---

## Architecture Patterns

### Code We Added - File Map

```
Core/Globals.lua (lines 641-724)
├── BCDM:GetHideWhenOffCooldown(barType)       — read per-bar setting from DB
├── BCDM:SetHideWhenOffCooldown(barType, value) — write per-bar setting to DB
├── BCDM:IsHideWhenOffCooldownEnabled(viewerFrameName) — viewer name → barType → DB read
└── BCDM:IsSpellOnCooldown(spellID)            — core cooldown detection logic

Modules/HideWhenOffCooldown.lua (entire file)
├── GetSpellID(frame)                          — local helper, extracts spellID from icon
├── UpdateIconVisibility(viewerName)           — per-viewer alpha update loop
├── UpdateAllViewers()                         — iterates VIEWERS, calls UpdateIconVisibility
├── SetupRefreshLayoutHooks()                  — hooksecurefunc on viewer.RefreshLayout
├── SetupEventFrame()                          — CreateFrame + SetScript("OnEvent")
├── RegisterEvents() / UnregisterEvents()      — event registration management
├── RestoreAllIcons()                          — reset all alphas to 1 on disable
├── BCDM:EnableHideWhenOffCooldown()           — public API, called at addon init
├── BCDM:DisableHideWhenOffCooldown()          — public API
└── BCDM:RefreshHideWhenOffCooldown()          — public API, called from GUI.lua checkbox

Core/GUI.lua (lines 1959-1973)
└── hideWhenOffCooldownCheckbox               — AceGUI CheckBox widget + tooltip + callback

Modules/CooldownManager.lua (diff lines)
├── CenterWrappedRows() — added collapseEnabled guard + GetAlpha() > 0 filter
└── SkinCooldownManager() — added BCDM:EnableHideWhenOffCooldown() call
```

### Pattern 1: Fail-Show Philosophy
**What:** On any error, nil value, or unexpected state — return false (don't hide) so the icon stays visible.
**When to use:** Every branch of IsSpellOnCooldown and every SetAlpha call in UpdateIconVisibility.
**Example:**
```lua
-- Fail-show at every guard
if not spellID or spellID == 0 then return false end      -- nil/zero spell
if not C_Spell.GetSpellInfo(spellID) then return false end -- unknown spell
if not cdInfo then return false end                        -- API nil return
if chargeInfo.currentCharges and chargeInfo.maxCharges then
    return chargeInfo.currentCharges < chargeInfo.maxCharges
end
return false  -- malformed chargeInfo, fail-show
```

### Pattern 2: Event-Driven Visibility (No Polling)
**What:** Visibility updates happen only in response to events and RefreshLayout hooks — no OnUpdate frame polling.
**When to use:** All icon visibility state changes in HideWhenOffCooldown.lua.

### Pattern 3: Alpha-Based Hiding
**What:** `icon:SetAlpha(0)` hides the icon (all children: texture, cooldown spinner, text) without destroying the frame.
**When to use:** Preferred over `icon:Hide()` because it preserves the frame's `cooldownInfo`, `layoutIndex`, and Blizzard's internal tracking of the icon slot.

### Anti-Patterns to Avoid
- **Using `icon:Hide()` instead of `SetAlpha(0)`:** `Hide()` removes the frame from `IsShown()` checks and may interfere with Blizzard's layout system. Alpha is the correct approach for this feature.
- **Polling with OnUpdate:** Our feature uses event-driven updates. Adding an OnUpdate loop would cause unnecessary CPU overhead on every frame render.
- **Modifying cooldownInfo:** The `frame.cooldownInfo` property is Blizzard-managed. Never write to it.
- **Calling `BCDM:EnableHideWhenOffCooldown()` before viewers exist:** Viewers are created in `SkinCooldownManager()`, so the Enable call at the end of that function is correct. Hook and frame setup at enable time is safe because viewers exist by then.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Post-hook Blizzard methods | Custom function replacement | `hooksecurefunc` | Taint-free; runs after the original; can't break secure execution |
| Icon metadata extraction | Custom frame scanning | `frame.cooldownInfo.overrideSpellID or frame.cooldownInfo.spellID` | Established BCM pattern (from DisableAuraOverlay.lua:58-61); handles overrides correctly |
| Nil-safe nested reads | Deep nil guard chains | Follow existing `barSettings and barSettings.HideWhenOffCooldown or false` pattern | Already correct and idiomatic Lua |
| Event registration management | Custom event router | RegisterEvent / UnregisterAllEvents on a dedicated frame | Standard WoW addon pattern; used everywhere in BCM |

---

## Common Pitfalls

### Pitfall 1: isOnGCD Nilability and the 1.5-Second Threshold
**What goes wrong:** `SpellCooldownInfo.isOnGCD` is documented as `Nilable=true` AND the Blizzard docs note "do not trust this field unless responding to a SPELL_UPDATE_COOLDOWN event." When `isOnGCD` is nil, our code falls back to checking `duration <= 1.5` to detect GCD. However, the maximum GCD is 1.5 seconds but some class abilities and Haste scaling can reduce GCD to as low as 0.75 seconds. Any spell with a real cooldown of exactly 1.0-1.5 seconds would be incorrectly treated as "GCD only" if `isOnGCD` is nil.
**Why it happens:** The fallback was designed conservatively but the threshold is based on max GCD duration, not accounting for real short cooldowns.
**How to avoid:** Verify whether any spells in the Essential/Utility bars have real cooldowns <= 1.5 seconds. If so, the fallback is a bug. The correct fix is to also check `cdInfo.startTime > 0` — a real cooldown has a non-zero start time, while a GCD also has a start time but a very short duration. The combination `duration > 0 AND duration <= 1.5 AND startTime > 0` can still be ambiguous.
**Warning signs:** A spell with a 1-second cooldown (e.g. certain talents or procs) that never shows as "on cooldown."

### Pitfall 2: Charge Spell State When All Charges Available
**What goes wrong:** `C_Spell.GetSpellCharges` returns `MayReturnNothing=true` — it returns nil for non-charge spells. For charge spells, it returns `SpellChargeInfo`. Our logic `chargeInfo.currentCharges < chargeInfo.maxCharges` correctly returns false when all charges are available (currentCharges == maxCharges). However, the `startTime` field of `SpellChargeInfo` was part of the old API — verify the new C_Spell version's table structure doesn't expose additional fields we're ignoring.
**Why it happens:** The C_Spell.* APIs replaced the legacy GetSpellCharges and the return table structure may differ subtly.
**How to avoid:** Confirm Blizzard FrameXML source for `SpellChargeInfo` fields — QT-2 already confirmed `currentCharges` and `maxCharges` are correct, but a full table listing should be verified.
**Warning signs:** Charge spells showing as hidden when they should show (or vice versa).

### Pitfall 3: Viewer Frame Availability at Hook Time
**What goes wrong:** `SetupRefreshLayoutHooks()` in HideWhenOffCooldown.lua calls `_G[viewerName]` and checks `viewer.RefreshLayout`. This is called from `BCDM:EnableHideWhenOffCooldown()`, which is called at the end of `SkinCooldownManager()`. If `SkinCooldownManager()` runs before `EssentialCooldownViewer` and `UtilityCooldownViewer` exist as global frames, the hook silently fails (the `if viewer and viewer.RefreshLayout then` guard prevents a crash but the hook is never installed).
**Why it happens:** The `hooksSetup = true` flag is set unconditionally even if no viewers existed. If called again later (e.g., on re-enable), `hooksSetup` would prevent re-attempting the hooks.
**How to avoid:** Verify the execution order: does `SkinCooldownManager()` run after Blizzard CooldownViewer addon loads and creates the viewer frames? The `Init()` function calls `C_AddOns.LoadAddOn("Blizzard_CooldownViewer")` on first run, but `SkinCooldownManager()` may run before the frames are available.
**Warning signs:** Visibility not updating when the bar layout refreshes (icons don't update until a cooldown event fires).

### Pitfall 4: GetAlpha() > 0 Alpha Filter in CenterWrappedRows
**What goes wrong:** `CenterWrappedRows` in CooldownManager.lua filters out hidden icons using `childFrame:GetAlpha() > 0`. This assumes only our code sets alpha on icon frames. If another addon, Blizzard code, or a parent frame sets alpha on child frames for a different reason, icons may be incorrectly excluded from or included in the centering calculation.
**Why it happens:** Alpha is a global property of the frame; any system can set it.
**How to avoid:** Consider whether `GetAlpha()` returns the effective alpha (including parent alpha chain) or just the frame's own alpha. In WoW, `GetAlpha()` returns the frame's own alpha, NOT the effective (parent-inherited) alpha. This means if a parent frame's alpha is 0, `GetAlpha()` on the child still returns 1. Our `SetAlpha(0)` calls are on the icon frames directly, so `GetAlpha() > 0` correctly reflects our setting. This is correct behavior, but should be documented explicitly.
**Warning signs:** Icons incorrectly included/excluded from centering in the wrapped rows layout.

### Pitfall 5: Midnight (Patch 12.0) Secret Values — Future Compatibility
**What goes wrong:** The Midnight expansion (Patch 12.0, public alpha as of 2025-2026) is introducing "Secret Values" — opaque Lua values that addon code cannot perform arithmetic on or compare. Cooldown `duration` fields returned by `C_Spell.GetSpellCooldown` during combat may become Secret Values. If `cdInfo.duration` is a secret value, `cdInfo.duration > 0` and `cdInfo.duration <= 1.5` will raise Lua errors, breaking `IsSpellOnCooldown` entirely during combat.
**Why it happens:** Blizzard is restricting addons from reading exact cooldown times during combat for gameplay fairness.
**How to avoid:** The Globals.lua diff already includes `BCDM:IsSecretValue(value)` and `BCDM:GetCooldownDesaturationCurves()` functions — these appear to be from the main branch's Midnight compatibility work. Verify whether `IsSpellOnCooldown` needs to guard against secret values using `issecretvalue()` before arithmetic comparisons. Our feature (hide when off cooldown) only needs a boolean "is on cooldown or not" — if duration is secret, we may need to use `cdInfo.isOnGCD` alone, or return true (fail-show) when the value is secret.
**Warning signs:** Lua error "attempt to compare a SecretValue" during combat in Midnight.

### Pitfall 6: PLAYER_ENTERING_WORLD Without Viewer Readiness
**What goes wrong:** `PLAYER_ENTERING_WORLD` fires and triggers `UpdateAllViewers()`. If the viewer frames don't exist yet at that moment (e.g., on initial login before Blizzard CooldownViewer finishes loading), the `_G[viewerName]` lookup returns nil, and we safely return early. This is handled correctly. However, there is no re-trigger after the viewer becomes available if it wasn't ready during `PLAYER_ENTERING_WORLD`.
**Why it happens:** `PLAYER_ENTERING_WORLD` fires once; if Blizzard CooldownViewer loads asynchronously after it, our initial sync is missed.
**How to avoid:** Check whether BCM's addon loading guarantees the viewers exist before `PLAYER_ENTERING_WORLD` fires. The `hooksecurefunc` on `RefreshLayout` would compensate since the first layout refresh after the viewer loads would trigger a visibility update.

---

## Code Examples

### SpellCooldownInfo Table Structure (verified fields)
```lua
-- Source: Blizzard SpellSharedDocumentation.lua (QT-2 verified)
-- SpellCooldownInfo structure:
--   .duration    number    — cooldown duration in seconds; 0 if inactive
--   .startTime   number    — GetTime() when cooldown started
--   .isOnGCD     bool|nil  — Nilable=true; only trust during SPELL_UPDATE_COOLDOWN event
--   .modRate     number    — rate modifier for cooldown reduction
```

### SpellChargeInfo Table Structure (verified fields)
```lua
-- Source: Blizzard SpellSharedDocumentation.lua (QT-2 verified)
-- SpellChargeInfo structure:
--   .currentCharges   number  — charges currently available
--   .maxCharges       number  — max charges
--   .cooldownStartTime number — GetTime() when current charge cooldown started
--   .cooldownDuration number  — duration to gain next charge
--   .chargeModRate    number  — rate modifier
-- NOTE: Returns nil for non-charge spells (MayReturnNothing=true)
```

### Correct Pattern: Guard Against Secret Values (Midnight compatibility)
```lua
-- If Midnight secret values affect duration comparisons, use this pattern:
local cdInfo = C_Spell.GetSpellCooldown(spellID)
if not cdInfo then return false end

-- Guard against secret values before arithmetic
if BCDM:IsSecretValue(cdInfo.duration) then
    -- Cannot read duration; use isOnGCD as sole signal, fail-show if unknown
    return not cdInfo.isOnGCD  -- if not GCD, treat as on cooldown (fail-show)
end

if cdInfo.isOnGCD then return false end
if cdInfo.duration and cdInfo.duration > 0 then return true end
return false
```

### Correct Pattern: Hook Safety with Re-hook Guard
```lua
-- Current implementation (correct but hooksSetup prevents retry):
local function SetupRefreshLayoutHooks()
    if hooksSetup then return end
    for _, viewerName in ipairs(VIEWERS) do
        local viewer = _G[viewerName]
        if viewer and viewer.RefreshLayout then
            hooksecurefunc(viewer, "RefreshLayout", function()
                UpdateIconVisibility(viewerName)
            end)
        end
    end
    hooksSetup = true  -- Set unconditionally — verify viewers existed
end
```

### Correct Pattern: GetAlpha() Semantics
```lua
-- GetAlpha() returns THIS frame's alpha, NOT effective (parent-inherited) alpha
-- Our SetAlpha(0) calls are direct on icon frames, so GetAlpha() > 0 correctly
-- reflects our feature's state:
if not collapseEnabled or childFrame:GetAlpha() > 0 then
    table.insert(visibleIcons, childFrame)
end
-- This is CORRECT — alpha=0 means we hid it, alpha=1 means it's visible to us
```

---

## State of the Art

| Area | Current Approach | Concern Level | Notes |
|---|---|---|---|
| `C_Spell.GetSpellCooldown` | Returns `SpellCooldownInfo` table | MEDIUM | Added 11.0.0; works in current TWW; Midnight may secret-value duration |
| `isOnGCD` field | Nilable; only trust during `SPELL_UPDATE_COOLDOWN` | HIGH | Our code calls it during the event handler — correct. The nilability fallback threshold needs validation. |
| `SetAlpha` for hiding | Standard, unrestricted | LOW | Clamped to [0,1] without error since 12.0 (Midnight) — no impact to us |
| Midnight Secret Values | In alpha/PTR | MEDIUM | `IsSecretValue` / `issecretvalue` already exists in Globals.lua from main branch — needs integration into `IsSpellOnCooldown` |
| `hooksecurefunc` | Established standard | LOW | Correct pattern; no taint risk |

**Deprecated/outdated:**
- `GetSpellCooldown()` (legacy): Removed in patch 11.0.0. We correctly use `C_Spell.GetSpellCooldown()`.
- `GetSpellCharges()` (legacy): Superseded. We correctly use `C_Spell.GetSpellCharges()`.

---

## Open Questions

1. **Does `IsSpellOnCooldown` need Secret Value guards now or only for Midnight?**
   - What we know: `BCDM:IsSecretValue()` and `issecretvalue()` already exist in Globals.lua (added in a recent main branch commit). The Midnight alpha is live.
   - What's unclear: Whether the TWW live client (current retail) can return secret values from `C_Spell.GetSpellCooldown`. Likely not yet in TWW but will be in Midnight.
   - Recommendation: Add the guard now as defensive coding — it's cheap and forward-compatible. If `IsSecretValue(cdInfo.duration)` returns false on live TWW (as expected), the guard is a no-op.

2. **Does the `hooksSetup` flag prevent recovery if viewers weren't ready at Enable time?**
   - What we know: `SetupRefreshLayoutHooks()` sets `hooksSetup = true` unconditionally, even if no viewers were found.
   - What's unclear: Whether the viewers always exist by the time `SkinCooldownManager()` runs. BCM calls `C_AddOns.LoadAddOn("Blizzard_CooldownViewer")` in `Init()`, which should make them available synchronously.
   - Recommendation: Verify by reading the CooldownManager.lua addon load sequence. If LoadAddOn is synchronous, viewers exist before SkinCooldownManager runs and hooks succeed.

3. **Is the 1.5-second GCD fallback threshold correct for all specs and talents?**
   - What we know: The base GCD is 1.5 seconds; Haste can reduce it to a minimum of 0.75 seconds. Any real cooldown between 0.75 and 1.5 seconds would be misclassified as GCD.
   - What's unclear: Whether any spells in the Essential/Utility bars have real cooldowns in the 0.75-1.5 second range. This is spec-dependent.
   - Recommendation: Flag the 1.5-second threshold in the scenario matrix. Consider whether the `startTime > 0` field can disambiguate real short cooldowns from GCDs. Both have non-zero startTime while active.

4. **What is the full contract of `viewer:GetChildren()` during a layout refresh?**
   - What we know: `GetChildren()` returns all child frames. We call it inside the `hooksecurefunc` on `RefreshLayout`, which means we run after Blizzard's layout code.
   - What's unclear: Whether Blizzard's layout code creates/destroys child frames during `RefreshLayout` or only repositions existing ones. If frames are created mid-refresh, our hook runs after they exist.
   - Recommendation: This is likely fine (hooks run after the original function completes), but worth confirming in the scenario matrix for spec changes and bar redraws.

---

## Validation Architecture

> No automated test framework exists for this WoW addon project. No `.planning/config.json` was found to check `workflow.nyquist_validation`. WoW addon testing is inherently manual (requires the game client). The integration test framework is explicitly deferred per CONTEXT.md.

### Test Framework
| Property | Value |
|---|---|
| Framework | Manual in-game verification only |
| Config file | None |
| Quick run command | Load addon in WoW client, verify in-game |
| Full suite command | Run full scenario matrix in-game |

### Phase Requirements → Test Map
| Behavior | Test Type | Verification Method |
|---|---|---|
| Charge spell hidden when all charges available | Manual | Log in with a charge spell (e.g., Roll, Vivify), verify icon hides when full charges |
| Charge spell visible when recharging | Manual | Use a charge spell, verify icon shows while recharging |
| GCD-only state does NOT hide icon | Manual | Cast any spell, verify icon stays visible during GCD window |
| Real cooldown correctly hides/shows icon | Manual | Use a spell with >1.5s cooldown, verify hide on cooldown, show when ready |
| Spec change re-evaluates visibility | Manual | Change spec, verify icons update correctly |
| Feature disable restores all icons | Manual | Toggle "Hide When Off Cooldown" off, verify all icons visible |
| Loading screen re-syncs visibility | Manual | Enter zone, verify icons in correct state after load |
| hooksecurefunc hooks installed | Manual | Refresh layout, verify visibility updates without a cooldown event |

### Wave 0 Gaps
- None — existing test infrastructure covers all phase requirements (by definition: WoW addons have no automated unit test infrastructure in this project, and the deferred scope explicitly excludes creating one)

---

## Sources

### Primary (HIGH confidence)
- QT-2 Audit: `.planning/quick/2-audit-codebase-to-verify-all-wow-api-cal/2-SUMMARY.md` — all 37 API/event/integration checks, Blizzard FrameXML links
- Blizzard SpellSharedDocumentation.lua (via QT-2) — `SpellCooldownInfo` and `SpellChargeInfo` table structures, nilability
- Codebase read: all 4 in-scope files and `git diff main...HideSpellOffCD` — exact lines added/modified

### Secondary (MEDIUM confidence)
- [C_Spell.GetSpellCooldown - Warcraft Wiki](https://warcraft.wiki.gg/wiki/API_C_Spell.GetSpellCooldown) — `startTime` field behavior, added 11.0.0, `isOnGCD` trust note
- [SPELL_UPDATE_COOLDOWN - Warcraft Wiki](https://warcraft.wiki.gg/wiki/SPELL_UPDATE_COOLDOWN) — event firing conditions
- [C_Spell.GetSpellCharges - Warcraft Wiki](https://warcraft.wiki.gg/wiki/API_C_Spell.GetSpellCharges) — `MayReturnNothing`, `currentCharges == maxCharges` edge case
- [PLAYER_ENTERING_WORLD - Warcraft Wiki](https://warcraft.wiki.gg/wiki/PLAYER_ENTERING_WORLD) — `isInitialLogin`, `isReloadingUi` params added 8.0.1
- [Patch 12.0.0/API changes - Warcraft Wiki](https://warcraft.wiki.gg/wiki/Patch_12.0.0/API_changes) — Secret Values system in Midnight
- [Patch 12.0.0/Planned API changes - Warcraft Wiki](https://warcraft.wiki.gg/wiki/Patch_12.0.0/Planned_API_changes) — duration field restrictions
- [WoW Midnight Secret Values - Warcraft Tavern](https://www.warcrafttavern.com/wow/news/wow-midnight-developer-talk-new-secret-values-combat-info-cooldown-manager-combat-addons-nerfed/) — Secret Values design overview
- [Secure Execution and Tainting - Wowpedia](https://wowpedia.fandom.com/wiki/Secure_Execution_and_Tainting) — SetAlpha not restricted; taint system background

### Tertiary (LOW confidence, flagged)
- WebSearch finding: "startTime returned is the current time and duration is 0.001 for spells not yet used" — single source, needs verification against Blizzard docs. Not a concern for our code since we only check `duration > 0`.

---

## Metadata

**Confidence breakdown:**
- Code behavior analysis: HIGH — read all 4 files and diffs directly
- API contract (signatures, nilability): HIGH — QT-2 verified against Blizzard FrameXML
- Pitfall identification: HIGH — derived from direct code reading + WoW addon community knowledge
- Midnight/Secret Values impact: MEDIUM — documented in Warcraft Wiki API changes but exact field-level impact on `C_Spell.GetSpellCooldown` during TWW vs Midnight is uncertain
- isOnGCD 1.5s threshold correctness: MEDIUM — correct for live TWW, but short-cooldown edge case is a real risk depending on spell roster

**Research date:** 2026-03-13
**Valid until:** 2026-04-13 (30 days — stable WoW addon APIs; Midnight API changes may shift sooner if PTR accelerates)
