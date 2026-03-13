---
status: complete
phase: 06-detailed-api-review
source: [06-01-SUMMARY.md, 06-02-SUMMARY.md]
started: 2026-03-13T14:00:00Z
updated: 2026-03-13T14:05:00Z
---

## Current Test

[testing complete]

## Tests

### 1. IsSecretValue Guard Placement
expected: In Core/Globals.lua, the `IsSpellOnCooldown` function should have a `BCDM:IsSecretValue(cdInfo.duration)` check placed AFTER the `cdInfo` nil check but BEFORE any arithmetic comparison on `cdInfo.duration`. The guard should return `false` (fail-show = icon stays visible) when duration is an opaque Secret Value.
result: pass

### 2. 1.5s GCD Fallback Comment
expected: In Core/Globals.lua, the 1.5s GCD fallback block should have a block comment explaining: (a) what trigger conditions cause it (isOnGCD is nil, duration <= 1.5s), (b) the race condition trade-off, and (c) that fail-show direction is intentional.
result: pass

### 3. GetAlpha() Semantics Comment
expected: In Modules/CooldownManager.lua, the `GetAlpha() > 0` check should have a comment explaining own-alpha vs effective-alpha semantics and why the `collapseEnabled` guard provides safety.
result: pass

### 4. hooksSetup Execution Order Comment
expected: In Modules/HideWhenOffCooldown.lua, the `hooksSetup = true` assignment should have a block comment documenting why the unconditional assignment is safe (synchronous `LoadAddOn` guarantees viewer frames exist before this code runs).
result: pass

### 5. No Regression - Addon Loads In-Game
expected: Load BetterCooldownManager in WoW (or check for Lua syntax errors). The addon should load without errors. If you have the HideWhenOffCooldown feature enabled, spells on cooldown should show their icons and spells off cooldown should hide — same behavior as before these changes.
result: pass

## Summary

total: 5
passed: 5
issues: 0
pending: 0
skipped: 0

## Gaps

[none yet]
