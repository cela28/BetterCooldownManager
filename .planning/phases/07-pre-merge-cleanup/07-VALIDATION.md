---
phase: 7
slug: pre-merge-cleanup
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-13
---

# Phase 7 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | None — WoW Lua addon, grep/diff verification |
| **Config file** | none |
| **Quick run command** | `grep -r "BetterCooldownManager_Dev\|BCDMDB_DEV" --include="*.lua" --include="*.toc" --include=".pkgmeta" .` |
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

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 07-01-01 | 01 | 1 | Dead code removal | manual grep | `grep -r "function BCDM:SetHideWhenOffCooldown\|function BCDM:DisableHideWhenOffCooldown" . --include="*.lua"` — expect 0 | N/A | ⬜ pending |
| 07-01-02 | 01 | 1 | Dev-mode conversion | manual grep | `grep -r "BetterCooldownManager_Dev\|BCDMDB_DEV" --include="*.lua" --include="*.toc" --include=".pkgmeta" .` — expect 0 | N/A | ⬜ pending |
| 07-01-03 | 01 | 1 | TOC file state | manual check | `ls BetterCooldownManager.toc && ! ls BetterCooldownManager_Dev.toc 2>/dev/null` | N/A | ⬜ pending |
| 07-01-04 | 01 | 1 | Branch diff clean | manual diff | `git diff main..HEAD -- ':(exclude).planning' ':(exclude).claude'` | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. No test framework needed — all verification is grep/diff based.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Branch diff only shows feature additions | Clean merge readiness | Requires human review of diff output | Run `git diff main..HEAD -- ':(exclude).planning' ':(exclude).claude'` and confirm only HideWhenOffCooldown feature code remains |
| Category-enUS TOC field correct | TOC hygiene | toggle-dev.sh may not handle this field | After script, check `BetterCooldownManager.toc` Category-enUS matches main branch |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 2s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
