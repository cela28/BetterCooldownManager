# Phase 3: Alpha-Based Hiding - Context

**Gathered:** 2026-02-04
**Status:** Ready for planning

<domain>
## Phase Boundary

Hide spell icons when their spell is off cooldown by setting alpha to 0. Icons become visible when the spell goes on cooldown. This phase implements the core visibility toggle; layout collapse (shifting icons to fill gaps) is Phase 4.

</domain>

<decisions>
## Implementation Decisions

### Hide/Show Trigger
- Hide instantly when cooldown ends (no delay/debounce)
- Icon only appears once cooldown actually starts (not during cast)
- Check available events in Midnight API wiki for update mechanism (Claude to research)

### Alpha Behavior
- Instant alpha change (no fade animation)
- Full opacity (1.0) when visible (spell on cooldown)
- Hide everything together: icon, cooldown spiral, and text (set alpha on parent frame)

### Charge Spell Handling
- Hide only when at max charges (2/2) — show while recharging
- If recharging (1/2 charges), icon stays visible
- Show charge count text on icon while visible
- Re-evaluate hide state when max charges changes (talents/buffs)

### Edge Cases
- Only cooldown state matters for hiding — hide even if spell unusable (no mana, out of range)
- No special combat handling — same logic in and out of combat
- Immediate re-evaluation on spec/talent changes

### Claude's Discretion
- Bar alpha interaction (how hidden icons interact with bar opacity settings)
- Fail state behavior during loading/unavailable data (likely fail-visible per Phase 2 pattern)
- Specific event selection for Midnight API

</decisions>

<specifics>
## Specific Ideas

- User mentioned checking Midnight wiki for available events — research needed on SPELL_UPDATE_COOLDOWN behavior in current expansion
- Phase 2 established "fail-show" pattern — Claude should follow this for error states

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 03-alpha-based-hiding*
*Context gathered: 2026-02-04*
