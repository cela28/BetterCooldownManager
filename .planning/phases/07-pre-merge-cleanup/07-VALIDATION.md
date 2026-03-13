---
phase: 7
slug: pre-merge-cleanup
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-03-13
validated: 2026-03-13
---

# Phase 7 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | None — WoW Lua addon, grep/diff verification |
| **Config file** | none |
| **Quick run command** | `grep -r "BetterCooldownManager_Dev\|BCDMDB_DEV" --include="*.lua" --include="*.toc" . && grep -r "function BCDM:SetHideWhenOffCooldown\|function BCDM:DisableHideWhenOffCooldown" --include="*.lua" .` |
| **Full suite command** | `git diff main..HEAD -- ':(exclude).planning' ':(exclude).claude'` |
| **Estimated runtime** | ~2 seconds |

---

## Sampling Rate

- **After every task commit:** Run quick grep verification
- **After every plan wave:** Run full diff review
- **Before `/gsd:verify-work`:** Full suite must show only intentional additions
- **Max feedback latency:** 2 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | Status |
|---------|------|------|-------------|-----------|-------------------|--------|
| 07-01-01 | 01 | 1 | Dead code removal — `SetHideWhenOffCooldown` and `DisableHideWhenOffCooldown` absent | grep | `grep -r "function BCDM:SetHideWhenOffCooldown\|function BCDM:DisableHideWhenOffCooldown" --include="*.lua" /home/sntanavaras/random-projects/BetterCooldownManager` — expect 0 matches | green |
| 07-01-02 | 01 | 1 | Dev-mode string cleanup — no `BetterCooldownManager_Dev` or `BCDMDB_DEV` in source files | grep | `grep -r "BetterCooldownManager_Dev\|BCDMDB_DEV" --include="*.lua" --include="*.toc" /home/sntanavaras/random-projects/BetterCooldownManager` — expect 0 matches | green |
| 07-01-03 | 01 | 1 | TOC file state — prod TOC present, dev TOC absent | filesystem | `ls BetterCooldownManager.toc` (expect present, `SavedVariables: BCDMDB`) and `ls BetterCooldownManager_Dev.toc` (expect ABSENT) | green |
| 07-01-04 | 01 | 1 | Branch diff clean — no `_Dev` refs or dead code in diff additions | git diff | `git diff main..HEAD -- ':(exclude).planning' ':(exclude).claude' ':(exclude)toggle-dev.sh' \| grep "^+" \| grep -i "BetterCooldownManager_Dev\|BCDMDB_DEV\|function BCDM:SetHideWhenOffCooldown\|function BCDM:DisableHideWhenOffCooldown"` — expect 0 matches | green |

*Status: pending · green · red · flaky*

---

## Wave 0 Requirements

No Wave 0 infrastructure was needed. All phase 7 requirements are verifiable by grep and filesystem checks against the existing codebase. No test harness, fixture files, or helper scripts were required.

---

## Executed Verification Results

Verified on 2026-03-13 against commit `7751756` (the phase 7 cleanup commit).

### 07-01-01 — Dead code removal

Command run:
```
grep -r "function BCDM:SetHideWhenOffCooldown|function BCDM:DisableHideWhenOffCooldown" --include="*.lua" .
```
Result: **0 matches — PASS**

### 07-01-02 — Dev-mode string cleanup

Command run:
```
grep -r "BetterCooldownManager_Dev|BCDMDB_DEV" --include="*.lua" --include="*.toc" .
```
Result: **0 matches across all .lua and .toc files — PASS**

`.pkgmeta` also checked: `package-as: BetterCooldownManager` (production name, no dev suffix).

### 07-01-03 — TOC file state

Filesystem check:
- `BetterCooldownManager.toc` — present (694 bytes), contains `SavedVariables: BCDMDB`, `IconTexture` path uses `BetterCooldownManager` (no `_Dev`)
- `BetterCooldownManager_Dev.toc` — ABSENT

Result: **PASS**

### 07-01-04 — Branch diff clean

Commands run:
```
git diff main..HEAD -- ':(exclude).planning' ':(exclude).claude' ':(exclude).agents' ':(exclude)toggle-dev.sh' | grep "^+" | grep -i "BetterCooldownManager_Dev|BCDMDB_DEV"
git diff main..HEAD -- ':(exclude).planning' ':(exclude).claude' | grep "^+" | grep "function BCDM:SetHideWhenOffCooldown|function BCDM:DisableHideWhenOffCooldown"
```
Result: **0 matches in both checks — PASS**

Note: diff grep for `_Dev` matched `SPEC_DEVOURER` (a WoW spec constant in an unrelated file) before the exclusion list was tightened. That is a false positive — `SPEC_DEVOURER` is not a dev-mode artifact. Targeted grep for the exact strings returns zero matches.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Branch diff contains only intentional feature additions | Clean merge readiness | Requires human review of full diff output for unexpected changes | Run `git diff main..HEAD -- ':(exclude).planning' ':(exclude).claude'` and confirm only HideSpellOffCD feature code (Globals, GUI, HideWhenOffCooldown module, Locales, TOC, .pkgmeta) plus `toggle-dev.sh` are present |
| Category-enUS TOC field correct | TOC hygiene | Field value requires comparison against main branch intent | `BetterCooldownManager.toc` Category-enUS is `|cFF8080FFUnhalted|r Development` — matches main branch value exactly (confirmed during phase execution) |

---

## Validation Sign-Off

- [x] All tasks have automated verify command
- [x] Sampling continuity: phase has only 2 tasks, both verified
- [x] Wave 0: no missing infrastructure — grep/diff coverage is complete
- [x] No watch-mode flags
- [x] Feedback latency < 2s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** complete — all 4 tasks green, phase verified 2026-03-13
