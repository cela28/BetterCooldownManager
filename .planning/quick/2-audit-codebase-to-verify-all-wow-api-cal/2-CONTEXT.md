# Quick Task 2: Audit codebase to verify all WoW API calls, internal functions, and integration points exist with direct citations - Context

**Gathered:** 2026-03-13
**Status:** Ready for planning

<domain>
## Task Boundary

Audit the HideSpellOffCD branch codebase to verify every WoW API call, internal function reference, and module integration point actually exists. For each API call (C_Spell.*, Duration:*, frame methods, etc.), directly observe and cite the source. For internal references (getter/setter functions, module hooks, RefreshLayout calls), trace them to their definition. Flag anything that cannot be verified as existing. Show all work with direct citations.

</domain>

<decisions>
## Implementation Decisions

### Verification Sources
- Use both Wowpedia wiki pages AND Blizzard's GitHub FrameXML repo as verification sources
- Two independent sources: Wowpedia for API documentation, FrameXML for source-level proof
- An API is "verified" if it appears in either source

### Audit Scope
- Audit only files we added/modified on the HideSpellOffCD branch
- Target files: HideWhenOffCooldown.lua, Globals.lua (our additions), Defaults.lua (our additions), GUI.lua (our additions), Init.xml (our additions)
- Do NOT audit the full upstream addon codebase

### Output Format
- Pass/fail checklist format
- Each row: API/function call name, source file:line, verification source (Wowpedia URL or FrameXML path), PASS/FAIL status
- Easy to scan and act on any failures

### Claude's Discretion
None — all areas discussed.

</decisions>

<specifics>
## Specific Ideas

- Never rely on internal memory for API existence — must observe directly via web sources or codebase grep
- Cite Wowpedia URLs and/or FrameXML GitHub paths for every WoW API
- For internal BCM functions, cite the file:line where they are defined
- Flag any API call that cannot be verified through these sources

</specifics>
