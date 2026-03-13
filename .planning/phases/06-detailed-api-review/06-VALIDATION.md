---
phase: 6
slug: detailed-api-review
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-13
---

# Phase 6 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Manual in-game verification only |
| **Config file** | None |
| **Quick run command** | Load addon in WoW client, verify in-game |
| **Full suite command** | Run full scenario matrix in-game |
| **Estimated runtime** | ~15 minutes per full scenario pass |

---

## Sampling Rate

- **After every task commit:** Code review for fail-show compliance
- **After every plan wave:** Run full scenario matrix in-game
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** N/A (manual verification)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Verification Method | Status |
|---------|------|------|-------------|-----------|---------------------|--------|
| 06-01-01 | 01 | 1 | Behavioral trace | Manual | Trace all code paths, verify logic | ⬜ pending |
| 06-01-02 | 01 | 1 | API contracts | Manual | Cross-ref Blizzard FrameXML source | ⬜ pending |
| 06-02-01 | 02 | 2 | Scenario matrix | Manual | Run scenarios in-game | ⬜ pending |
| 06-03-01 | 03 | 3 | Fixes | Manual | Verify each fix in-game | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

*Existing infrastructure covers all phase requirements — WoW addons have no automated unit test infrastructure in this project, and the deferred scope explicitly excludes creating one.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Charge spell hidden when all charges available | Behavioral | Requires WoW client | Log in with charge spell (e.g., Roll), verify icon hides at full charges |
| Charge spell visible when recharging | Behavioral | Requires WoW client | Use a charge spell, verify icon shows while recharging |
| GCD-only state does NOT hide icon | Behavioral | Requires WoW client | Cast any spell, verify icon stays visible during GCD window |
| Real cooldown correctly hides/shows | Behavioral | Requires WoW client | Use spell with >1.5s CD, verify hide on cooldown, show when ready |
| Spec change re-evaluates visibility | Behavioral | Requires WoW client | Change spec, verify icons update correctly |
| Feature disable restores all icons | Behavioral | Requires WoW client | Toggle off, verify all icons visible |
| Loading screen re-syncs visibility | Behavioral | Requires WoW client | Enter zone, verify icons correct after load |
| hooksecurefunc hooks installed | Behavioral | Requires WoW client | Refresh layout, verify visibility updates |

---

## Validation Sign-Off

- [ ] All tasks have manual verification instructions or code review criteria
- [ ] Sampling continuity: code review after every task commit
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency: acceptable for manual verification
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
