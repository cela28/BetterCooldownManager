---
phase: quick-3
plan: 01
type: execute
wave: 1
depends_on: []
files_modified: [".planning/quick/3-generate-api-compatibility-report-confir/3-SUMMARY.md"]
autonomous: true
requirements: [COMPAT-01]

must_haves:
  truths:
    - "Report confirms all WoW API calls are compatible with both TWW live and Midnight 12.0"
    - "Report confirms Secret Value guard is in place and working for Midnight duration fields"
    - "Report identifies any remaining Midnight API restrictions that could affect spell hiding"
    - "Report provides a clear PASS/FAIL compatibility matrix"
  artifacts:
    - path: ".planning/quick/3-generate-api-compatibility-report-confir/3-SUMMARY.md"
      provides: "Complete API compatibility report for TWW and Midnight"
---

<objective>
Generate a comprehensive API compatibility report confirming the HideSpellOffCD spell-hiding feature works correctly under both current TWW live API behavior and upcoming Midnight (12.0) API restrictions (Secret Values, combat protection changes).

Purpose: Provide a definitive compatibility assessment that can accompany a PR or merge request, proving the feature is forward-compatible with Midnight.
Output: A single SUMMARY report with compatibility matrix, Secret Value analysis, and per-API assessment.
</objective>

<execution_context>
@/home/sntanavaras/.claude/get-shit-done/workflows/execute-plan.md
@/home/sntanavaras/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@.planning/quick/2-audit-codebase-to-verify-all-wow-api-cal/2-SUMMARY.md
@.planning/phases/06-detailed-api-review/06-FINDINGS.md
@.planning/phases/06-detailed-api-review/06-RESEARCH.md

Source files (READ ONLY — do NOT modify):
@Core/Globals.lua (lines 641-729 — IsSpellOnCooldown with Secret Value guard)
@Modules/HideWhenOffCooldown.lua (entire file — visibility module)
@Modules/CooldownManager.lua (diff lines — CenterWrappedRows alpha filter)
@Core/GUI.lua (lines 1959-1973 — checkbox widget)
</context>

<tasks>

<task type="auto">
  <name>Task 1: Generate API compatibility report for TWW and Midnight</name>
  <files>.planning/quick/3-generate-api-compatibility-report-confir/3-SUMMARY.md</files>
  <action>
READ-ONLY ANALYSIS. Do NOT modify any source files.

Generate a comprehensive API compatibility report. The report must synthesize existing analysis (QT-2 audit, Phase 6 FINDINGS) with Midnight-specific API restriction analysis. Structure as follows:

**Section 1: Executive Summary**
- One-paragraph verdict: Is the HideSpellOffCD feature compatible with both TWW live and Midnight 12.0?
- Count of APIs used, count with Midnight implications, count with guards in place

**Section 2: Midnight API Restrictions Overview**
- Brief explanation of Secret Values (opaque numeric types that error on arithmetic)
- Which C_Spell APIs are affected: `C_Spell.GetSpellCooldown` returns `SpellCooldownInfo` with `duration` that may become a Secret Value in combat
- Which fields in our code touch numeric values that could be Secret Values: `cdInfo.duration`, `cdInfo.isOnGCD` (boolean, not numeric — safe), `chargeInfo.currentCharges`, `chargeInfo.maxCharges`

**Section 3: Per-API Compatibility Matrix**

For each WoW API call used by the feature, create a row:

| API | TWW Live | Midnight 12.0 | Guard in Place | Notes |
|-----|----------|---------------|----------------|-------|

Cover these APIs:
1. `C_Spell.GetSpellInfo(spellID)` — Returns SpellInfo or nil. No numeric fields accessed by our code. TWW: PASS, Midnight: PASS (no Secret Value risk).
2. `C_Spell.GetSpellCharges(spellID)` — Returns SpellChargeInfo with `currentCharges`, `maxCharges`. Research whether charge counts could become Secret Values in Midnight. If uncertain, note that our comparison `currentCharges < maxCharges` would need a guard. Currently: no guard exists (assess risk level).
3. `C_Spell.GetSpellCooldown(spellID)` — Returns SpellCooldownInfo. `duration` field IS known to be affected by Secret Values in Midnight. Guard: `BCDM:IsSecretValue(cdInfo.duration)` check at Globals.lua:703 — PRESENT and returns false (fail-show). TWW: PASS, Midnight: PASS (guarded).
4. `frame:SetAlpha(0|1)` — Frame method, not API-restricted. No Secret Value involvement. PASS both.
5. `frame:GetAlpha()` — Used in CenterWrappedRows. Returns own alpha (0 or 1 set by us). No Secret Value involvement. PASS both.
6. `hooksecurefunc()` — Hooking API. No Midnight changes known. PASS both.
7. Events: `SPELL_UPDATE_COOLDOWN`, `SPELL_UPDATE_CHARGES`, `PLAYER_ENTERING_WORLD`, `PLAYER_SPECIALIZATION_CHANGED` — Event system unchanged. PASS both.

**Section 4: Secret Value Guard Analysis**

Detail the specific guard implemented at Globals.lua:697-705:
- Show the code snippet
- Explain that `BCDM:IsSecretValue()` (Globals.lua:189) wraps the global `issecretvalue()` function
- On TWW live: `issecretvalue()` does not exist, so `IsSecretValue()` always returns false — zero behavior change
- On Midnight: when `cdInfo.duration` is a Secret Value during combat, the guard catches it before any arithmetic and returns false (fail-show)
- Confirm the guard is placed BEFORE the first arithmetic comparison on `cdInfo.duration` (before `duration > 0` and `duration <= 1.5`)

**Section 5: Charge Spell Midnight Risk Assessment**

Analyze whether `chargeInfo.currentCharges` and `chargeInfo.maxCharges` could become Secret Values:
- Research note: Secret Values in Midnight primarily target cooldown timing information to prevent automation. Charge COUNTS (how many charges you have) are visible information shown in the default UI, so they are LESS likely to be Secret Values.
- However, `chargeInfo.cooldownStartTime` and `chargeInfo.cooldownDuration` (which we do NOT access) are timing fields and more likely candidates.
- Risk assessment: LOW for charge counts, but note that no guard currently exists. If Blizzard does Secret-Value-protect charge counts, our `currentCharges < maxCharges` comparison would error.
- Recommendation: Consider adding `IsSecretValue(chargeInfo.currentCharges)` guard as optional future hardening (not blocking for merge).

**Section 6: Compatibility Verdict**

Final matrix:

| Component | TWW 11.x | Midnight 12.0 | Status |
|-----------|----------|---------------|--------|
| Cooldown detection (IsSpellOnCooldown) | PASS | PASS (guarded) | Ship-ready |
| Charge detection | PASS | PASS (low risk) | Ship-ready, monitor |
| Visibility toggling (SetAlpha) | PASS | PASS | Ship-ready |
| Layout collapse (GetAlpha filter) | PASS | PASS | Ship-ready |
| Event handling | PASS | PASS | Ship-ready |
| GUI checkbox | PASS | PASS | Ship-ready |

Overall verdict and any caveats.

**References section:** Link to QT-2 audit summary, Phase 6 FINDINGS, and relevant Wowpedia/FrameXML sources for Secret Values.
  </action>
  <verify>
    <automated>test -f .planning/quick/3-generate-api-compatibility-report-confir/3-SUMMARY.md && grep -c "PASS" .planning/quick/3-generate-api-compatibility-report-confir/3-SUMMARY.md | xargs test 5 -le</automated>
  </verify>
  <done>Complete API compatibility report exists with per-API TWW/Midnight matrix, Secret Value guard analysis, charge spell risk assessment, and clear ship-ready verdict</done>
</task>

</tasks>

<verification>
- Report file exists at `.planning/quick/3-generate-api-compatibility-report-confir/3-SUMMARY.md`
- Report covers all 7 API categories used by the feature
- Report includes Secret Value guard code analysis with Globals.lua line references
- Report includes charge spell Midnight risk assessment
- Report has a clear final compatibility verdict table
- No source files were modified
</verification>

<success_criteria>
- Every WoW API used by HideSpellOffCD is assessed for both TWW and Midnight compatibility
- Secret Value guard at Globals.lua:703 is confirmed as correctly placed and functional
- Charge spell API is assessed for Midnight Secret Value risk with recommendation
- Final verdict is clear: ship-ready or not, with any caveats documented
- Report is self-contained and suitable for PR documentation
</success_criteria>

<output>
After completion, create `.planning/quick/3-generate-api-compatibility-report-confir/3-SUMMARY.md`
</output>
