# Phase 4: Layout Collapse - Context

**Gathered:** 2026-02-12
**Status:** Ready for planning

<domain>
## Phase Boundary

Make remaining icons shift to fill gaps left by hidden (alpha=0) icons. Icons reposition when spells go on/off cooldown. Bar container size does not change. This phase modifies layout calculation only — hiding logic (Phase 3) and UI configuration (Phase 5) are separate.

</domain>

<decisions>
## Implementation Decisions

### Collapse direction
- Icons compact toward center of the bar (not left-aligned)
- Full reflow across rows for multi-row bars — if row 1 loses icons, row 2 icons move up to fill
- When a hidden icon reappears, it returns to its **original configured position**, other icons shift to accommodate
- Bar container keeps its original dimensions — icons compact within it

### Transition behavior
- Instant snap to new positions — no animation
- Every visibility change triggers immediate relayout (no debouncing/batching)
- Icons just appear/disappear with no visual cue (no flash, glow, or highlight)

### Spacing & alignment
- Collapsed icons keep the same spacing/padding as configured — only the hidden icon's slot is removed
- Centering based on full bar width (including padding/borders)
- If bar has a grow direction setting, collapse respects that direction (grow right = compact from left, grow center = center, etc.)

### Edge cases
- When ALL icons are hidden, the empty bar frame stays visible (no bar hiding)
- Single remaining icon follows grow direction rules — sits at origin point, not forced to center
- Layout collapse applies to ALL bar types that support HideWhenOffCooldown (Essential and Utility)

### Claude's Discretion
- Vertical bar compacting direction (if vertical bars exist in the addon)
- Whether to recalculate on every RefreshLayout or only on visibility change (optimize based on existing patterns)
- Behavior when feature is toggled off mid-combat (immediate restore vs next refresh cycle — pick safest approach)

</decisions>

<specifics>
## Specific Ideas

- Centering should respect grow direction — this means the "compact toward center" behavior is the default, but bars with explicit grow direction override it
- Full reflow means treating visible icons as a contiguous sequence and laying them out fresh, not just shifting individual icons

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 04-layout-collapse*
*Context gathered: 2026-02-12*
