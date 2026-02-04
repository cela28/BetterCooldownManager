# Phase 2: Cooldown State Detection - Context

**Gathered:** 2026-02-04
**Status:** Ready for planning

<domain>
## Phase Boundary

Reliably detect when a spell is on/off cooldown for the hiding feature. This phase creates the `IsSpellOnCooldown(spellID)` function that Phase 3 (Alpha-Based Hiding) will consume. Detection only runs for bars with HideWhenOffCooldown enabled.

</domain>

<decisions>
## Implementation Decisions

### GCD handling
- GCD-only states do NOT count as "on cooldown" — only actual spell cooldowns
- Use whatever GCD detection method BCM already uses elsewhere
- When a spell triggers both GCD and real cooldown, immediately count as "on cooldown"
- GCD filtering works identically on all bars (Essential and Utility)

### Charge spell behavior
- A charge spell counts as "on cooldown" if ANY charge is recharging
- At max charges (e.g., 2/2), spell is "off cooldown" and should be hidden
- Always re-check charge count each update (don't cache max) to handle talent/buff changes
- Follow BCM's existing charge detection API patterns

### State change timing
- Use BCM's existing update pattern for detecting state changes
- Follow BCM's existing debouncing approach (if any)
- Detection behaves the same in and out of combat
- Only run detection for spells on bars with HideWhenOffCooldown enabled (performance)

### Claude's Discretion
- Error fallback behavior (fail-show vs fail-hide when API returns nil/error)
- Error logging approach (follow BCM patterns)
- pcall protection scope (follow BCM patterns, probably not every check)
- No recovery for invalid spell IDs — treat as error with fallback

</decisions>

<specifics>
## Specific Ideas

- "Follow what BCM already does" — several decisions defer to existing BCM patterns for GCD detection, charge handling, update timing, and debouncing
- Keep it simple — no name-based spell lookup recovery, no per-bar GCD options

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 02-cooldown-state-detection*
*Context gathered: 2026-02-04*
