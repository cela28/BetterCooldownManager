---
phase: 6
slug: detailed-api-review
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-03-13
completed: 2026-03-13
---

# Phase 6 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Grep/diff-based static verification (no automated test runner — WoW Lua addon) |
| **Config file** | None |
| **Quick run command** | See grep commands in Per-Task Verification Map below |
| **Full suite command** | Run all grep checks in this document sequentially |
| **Estimated runtime** | <2 minutes for all grep checks; ~15 minutes for optional in-game manual verification |

---

## Sampling Rate

- **After every task commit:** Code review for fail-show compliance
- **After every plan wave:** Run full grep verification matrix
- **Before `/gsd:verify-work`:** All grep checks must pass
- **Max feedback latency:** Immediate (grep-based)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Verification Command | Status |
|---------|------|------|-------------|-----------|---------------------|--------|
| 06-01-01 | 01 | 1 | Code path trace | grep | `grep -c "### Pitfall" .planning/phases/06-detailed-api-review/06-FINDINGS.md` → expect 6 | green |
| 06-01-02 | 01 | 1 | Scenario matrix exists | grep | `grep -c "^| [0-9]" .planning/phases/06-detailed-api-review/06-FINDINGS.md` → expect ≥18 | green |
| 06-01-03 | 01 | 1 | Fix list present | grep | `grep -q "Fix List\|Prioritized Fix" .planning/phases/06-detailed-api-review/06-FINDINGS.md` → expect match | green |
| 06-02-01 | 02 | 2 | FIX-01 Secret Value guard | grep | `grep -n "IsSecretValue" Core/Globals.lua` → expect match at line ~703 | green |
| 06-02-02 | 02 | 2 | Guard is before arithmetic | grep | `grep -n "IsSecretValue\|cdInfo.duration" Core/Globals.lua` → IsSecretValue line precedes duration comparisons | green |
| 06-02-03 | 02 | 2 | FIX-02 1.5s fallback comment | grep | `grep -n "1.5s\|isOnGCD.*nil\|fallback" Core/Globals.lua` → expect match near line ~713 | green |
| 06-02-04 | 02 | 2 | FIX-03 GetAlpha semantics comment | grep | `grep -n "own.*alpha\|own-alpha" Modules/CooldownManager.lua` → expect match near line ~232 | green |
| 06-02-05 | 02 | 2 | FIX-04 hooksSetup comment | grep | `grep -n "synchronous\|synchronously" Modules/HideWhenOffCooldown.lua` → expect match near line ~90 | green |
| 06-02-06 | 02 | 2 | Post-Fix Verification documented | grep | `grep -q "Post-Fix Verification" .planning/phases/06-detailed-api-review/06-FINDINGS.md` → expect match | green |
| 06-02-07 | 02 | 2 | Ship-ready verdict | grep | `grep -q "SHIP-READY" .planning/phases/06-detailed-api-review/06-FINDINGS.md` → expect match | green |
| 06-02-08 | 02 | 2 | No files outside scope modified | diff | `git show --stat fa82a10` → only Core/Globals.lua, Modules/CooldownManager.lua, Modules/HideWhenOffCooldown.lua | green |

*Status: pending · green · red · flaky*

---

## Wave 0 Requirements

No automated test infrastructure needed — all verifications are grep/diff-based static checks against source files and planning artifacts. The WoW Lua addon environment has no unit test runner; behavioral correctness is verified through code path analysis documented in 06-FINDINGS.md.

---

## Grep Verification Checks (Runnable)

### Check 1 — REVIEW-01: All 6 pitfalls analyzed in FINDINGS

```sh
grep -c "### Pitfall" .planning/phases/06-detailed-api-review/06-FINDINGS.md
# Expected output: 6
```

**Result:** 6 (PASS)
**Evidence:** FINDINGS.md lines 277, 304, 330, 368, 398, 425

---

### Check 2 — REVIEW-02: Scenario matrix has 18+ rows

```sh
grep -c "^| [0-9]" .planning/phases/06-detailed-api-review/06-FINDINGS.md
# Expected output: ≥18
```

**Result:** 18 scenario rows confirmed (PASS)
**Evidence:** FINDINGS.md Part 3 scenario matrix; scenarios 1-18 all present

---

### Check 3 — REVIEW-03: API behavioral analysis documented beyond signature level

```sh
grep -q "Verdict\|verdict" .planning/phases/06-detailed-api-review/06-FINDINGS.md && echo PASS
# Expected output: PASS
```

**Result:** PASS — all 6 pitfalls include explicit runtime behavioral verdicts (non-issue / acceptable risk / fix needed), not just signature-level observations.

---

### Check 4 — REVIEW-04/FIX-01: IsSecretValue guard present in IsSpellOnCooldown

```sh
grep -n "IsSecretValue" Core/Globals.lua
# Expected: match at line ~189 (definition) AND line ~703 (guard in IsSpellOnCooldown)
```

**Result:** Lines 189 (definition) and 703 (guard call) — PASS
**Evidence:** `if self:IsSecretValue(cdInfo.duration) then` at Globals.lua:703

---

### Check 5 — FIX-01 placement: Guard is before arithmetic comparisons on duration

```sh
grep -n "IsSecretValue\|cdInfo.duration\|duration > 0\|duration <= 1.5" Core/Globals.lua
# Expected: IsSecretValue check (line ~703) appears before arithmetic comparisons (line ~715+)
```

**Result:** PASS — IsSecretValue guard at line 703 precedes `duration > 0` / `duration <= 1.5` comparisons at lines 715+. Guard is placed between cdInfo nil check and isOnGCD check — earliest possible point.

---

### Check 6 — FIX-01 fail-show direction: returns false on Secret Value

```sh
grep -A2 "IsSecretValue(cdInfo.duration)" Core/Globals.lua
# Expected: next line is "return false" with a fail-show comment
```

**Result:** PASS — `return false  -- Cannot read duration (Midnight Secret Value), fail-show` at Globals.lua:704

---

### Check 7 — FIX-02: 1.5s fallback comment present

```sh
grep -n "fallback\|isOnGCD.*nil\|outside SPELL_UPDATE" Core/Globals.lua
# Expected: comment block around line ~713 explaining fallback trigger conditions
```

**Result:** PASS — Block comment at Globals.lua:713-718 explains fallback conditions and acceptable-risk trade-off

---

### Check 8 — FIX-03: GetAlpha() semantics comment present

```sh
grep -n "own.alpha\|inherited" Modules/CooldownManager.lua
# Expected: comment near line ~232 explaining own-alpha vs inherited-alpha
```

**Result:** PASS — Lines 232-234 contain: "GetAlpha() returns the frame's own alpha (not the effective/inherited alpha)"

---

### Check 9 — FIX-04: hooksSetup execution-order comment present

```sh
grep -n "synchronous\|LoadAddOn.*synchron\|synchron.*LoadAddOn" Modules/HideWhenOffCooldown.lua
# Expected: comment near line ~88-93 explaining synchronous load guarantee
```

**Result:** PASS — Lines 88-92 contain block comment: "BCDM:Init() calls C_AddOns.LoadAddOn('Blizzard_CooldownViewer') synchronously before SkinCooldownManager() runs"

---

### Check 10 — REVIEW-05: Post-Fix Verification section in FINDINGS

```sh
grep -q "Post-Fix Verification" .planning/phases/06-detailed-api-review/06-FINDINGS.md && echo PASS
# Expected output: PASS
```

**Result:** PASS — Section at FINDINGS.md line 623 with before/after snippets, 5-scenario re-check, and SHIP-READY verdict

---

### Check 11 — REVIEW-05: Final ship-ready verdict documented

```sh
grep "SHIP-READY" .planning/phases/06-detailed-api-review/06-FINDINGS.md
# Expected: "SHIP-READY." at end of Post-Fix Verification
```

**Result:** PASS — "**SHIP-READY.**" at FINDINGS.md line 739

---

### Check 12 — Scope boundary: no files outside our branch additions modified

```sh
git show --stat fa82a10
# Expected: only Core/Globals.lua, Modules/CooldownManager.lua, Modules/HideWhenOffCooldown.lua
```

**Result:** PASS — Commit fa82a10 modifies exactly Core/Globals.lua, Modules/CooldownManager.lua, Modules/HideWhenOffCooldown.lua. No pre-existing BCM code touched.

---

### Check 13 — GUI.lua checkbox wired to RefreshHideWhenOffCooldown

```sh
grep -n "RefreshHideWhenOffCooldown" Core/GUI.lua
# Expected: match at line ~1964 inside OnValueChanged callback
```

**Result:** PASS — Line 1964: `BCDM:RefreshHideWhenOffCooldown()` called in checkbox OnValueChanged

---

## Manual-Only Verifications

The following require a live WoW client and cannot be grep-verified:

| Behavior | Requirement | Why Manual | Test Instructions | Status |
|----------|-------------|------------|-------------------|--------|
| GCD icon flicker | REVIEW-02 scenario 2 | Visual runtime behavior | Cast instant spell; verify icon hides for GCD window (~0.75-1.5s) then shows again | Deferred to in-game QA |
| Feature toggle responsiveness | REVIEW-02 scenario 11 | Requires active cooldowns in game | Enable feature, cast spells to hide icons, disable checkbox — all icons should restore alpha=1 immediately | Deferred to in-game QA |
| Secret Value guard no-op on live TWW | REVIEW-04 FIX-01 | Requires live TWW client | Confirm `BCDM:IsSecretValue(cdInfo.duration)` always returns false on TWW (issecretvalue() not yet present) | Deferred; no-op confirmed by code analysis |
| Charge spell all-charges-full hides | REVIEW-02 scenario 4 | Requires charge spell in game | Use Roll or similar, let all charges fill; icon should hide | Deferred to in-game QA |
| Spec change re-evaluates visibility | REVIEW-02 scenario 8 | Requires live spec change | Change spec; verify icons update within one PLAYER_SPECIALIZATION_CHANGED event | Deferred to in-game QA |

---

## Validation Sign-Off

- [x] All tasks have grep-based verification commands with expected outputs
- [x] Sampling continuity: code review after every task commit
- [x] Wave 0: no automated test framework needed; all checks are grep/diff
- [x] No watch-mode flags
- [x] Feedback latency: immediate (grep-based)
- [x] All 12 grep checks executed and confirmed green
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** complete — all checks green as of 2026-03-13
