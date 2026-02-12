# Phase 5: UI Configuration - Context

**Gathered:** 2026-02-12
**Status:** Ready for planning

<domain>
## Phase Boundary

Add a per-bar checkbox to the existing settings panel that toggles the HideWhenOffCooldown feature. Only Essential and Utility bars get this checkbox. No new capabilities — just exposing the existing setting to users.

</domain>

<decisions>
## Implementation Decisions

### Checkbox placement
- Place near existing visibility/show-hide options in the bar settings panel
- Only render for Essential and Utility bars — no checkbox for unsupported bar types
- Default to unchecked (matches Phase 1 default of `false`)
- Inline with existing options — no separator, header, or dedicated section

### Tooltip & labeling
- Checkbox label: "Hide When Off Cooldown"
- Tooltip: short, one line (e.g., "Hides spell icons that are not on cooldown")
- No mention of layout collapse in tooltip — users will see it naturally
- Match the existing addon's language style and tooltip conventions

### Visual feedback
- No visual indicator on the bar itself when the feature is active — hidden icons and collapsed layout are self-evident
- Bar stays visible (empty frame) even when all icons are hidden
- Instant restore when feature is toggled off — icons snap back immediately

### Claude's Discretion
- Whether toggling the checkbox applies live (instant preview) or on settings close — match existing addon behavior
- Exact tooltip wording — follow existing addon tone and patterns

</decisions>

<specifics>
## Specific Ideas

No specific requirements — open to standard approaches that match the existing addon settings patterns.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 05-ui-configuration*
*Context gathered: 2026-02-12*
