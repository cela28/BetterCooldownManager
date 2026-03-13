# Phase 7: Pre-Merge Cleanup - Research

**Researched:** 2026-03-13
**Domain:** Lua dead-code deletion, shell-script-driven string substitution, WoW addon TOC/SavedVariables hygiene
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Dead code removal:**
- Remove `BCDM:SetHideWhenOffCooldown()` (Globals.lua:650) — never called, GUI writes to DB directly
- Remove `BCDM:DisableHideWhenOffCooldown()` (HideWhenOffCooldown.lua:155) — never called
- Straight deletion, no external addon compatibility concern

**Dev-mode conversion:**
- Use `toggle-dev.sh prod` to revert all `BetterCooldownManager_Dev` references back to `BetterCooldownManager`
- This handles: TOC rename, .pkgmeta, SavedVariables, asset paths, AceAddon/AceLocale/GetAddOnMetadata strings
- After conversion: keep `toggle-dev.sh` (useful for future dev), remove `BetterCooldownManager_Dev.toc`

**Merge strategy:**
- This phase does NOT merge to main — cleanup only
- Merge deferred until after in-game testing by the user
- Branch stays as HideSpellOffCD after cleanup

**Post-cleanup verification:**
- Diff branch against main (excluding .planning/ and .claude/ directories)
- Confirm only intentional feature additions remain
- No stray _Dev references, no dead code, no unintended changes

### Claude's Discretion
- Order of cleanup operations (dead code vs dev references first)
- Whether to combine cleanup into one commit or separate commits
- Handling any edge cases toggle-dev.sh might miss

### Deferred Ideas (OUT OF SCOPE)
- Actual merge to main — after in-game testing
- In-game testing plan — user handles this outside GSD workflow
</user_constraints>

---

## Summary

Phase 7 is a purely mechanical cleanup phase with two independent tasks: deleting two unused Lua functions and running a proven shell script to revert dev-mode string substitutions across all addon source files. No new code is written. The risk surface is very low — both tasks are well-bounded and reversible via git.

The repo is currently in dev mode: `BetterCooldownManager_Dev.toc` exists (not `BetterCooldownManager.toc`), all addon name strings read `BetterCooldownManager_Dev`, and `Core/Core.lua` references `BCDMDB_DEV`. Running `toggle-dev.sh prod` handles the full reversal automatically via sed and perl substitutions — this script was purpose-built for exactly this workflow and has been used previously.

The dead code (`SetHideWhenOffCooldown` and `DisableHideWhenOffCooldown`) are isolated functions with no call sites anywhere in the codebase. Their companion functions (`GetHideWhenOffCooldown`, `RefreshHideWhenOffCooldown`, `IsHideWhenOffCooldownEnabled`) remain and are actively used — only the two unreferenced functions are deleted.

**Primary recommendation:** Run dead-code deletion first (preserves clean diff context), then run `toggle-dev.sh prod`, then delete `BetterCooldownManager_Dev.toc`, then verify with `git diff main..HEAD -- ':(exclude).planning' ':(exclude).claude'`.

---

## Standard Stack

This phase uses no external libraries. The toolchain is:

| Tool | Purpose | Notes |
|------|---------|-------|
| `toggle-dev.sh prod` | Revert all `_Dev` string references to prod | Already present in repo root; idempotent if run from prod state |
| `git diff` with pathspec exclusions | Verify branch delta against main | Standard git; pathspec syntax `:(exclude).planning` required |

**No npm install or package changes required.**

---

## Exact Change Map

### Dead Code to Delete

**File 1: `Core/Globals.lua`**
- Lines 641–657: The comment block `-- HideWhenOffCooldown Setting API` and `SetHideWhenOffCooldown` function
- Specifically lines 650–657 (the function body)
- The comment at lines 641–643 and `GetHideWhenOffCooldown` (lines 644–648) are KEPT — only `SetHideWhenOffCooldown` is removed
- `IsHideWhenOffCooldownEnabled` (lines 659–663) is also KEPT

Exact block to delete from Globals.lua:
```lua
function BCDM:SetHideWhenOffCooldown(barType, value)
    if not barType then return end
    local barSettings = self.db.profile.CooldownManager[barType]
    if barSettings then
        barSettings.HideWhenOffCooldown = value
        -- Future phases may add refresh/update calls here
    end
end
```

**File 2: `Modules/HideWhenOffCooldown.lua`**
- Lines 154–160: The comment and `DisableHideWhenOffCooldown` function
- The immediately following `RefreshHideWhenOffCooldown` (lines 162–167) is KEPT

Exact block to delete from HideWhenOffCooldown.lua:
```lua
-- Disable the hide-when-off-cooldown feature
function BCDM:DisableHideWhenOffCooldown()
    isEnabled = false

    UnregisterEvents()
    RestoreAllIcons()
end
```

### Dev-Mode References Handled by toggle-dev.sh prod

Confirmed affected files (verified by grep):
- `Core/Core.lua` lines 2, 5, 6 — AceAddon name, AceDB name, LDS name
- `Core/Globals.lua` lines 26–30, 35, 267, 278, 289 — asset paths, GetAddOnMetadata calls
- `Core/GUI.lua` lines 5, 1215–1247 — AceLocale name, media asset paths
- `Locales/enUS.lua` line 1 — AceLocale registration
- `Locales/koKR.lua` line 1 — AceLocale registration
- `.pkgmeta` line 1 — package-as directive
- TOC rename: `BetterCooldownManager_Dev.toc` → `BetterCooldownManager.toc`

### File to Delete After toggle-dev.sh

- `BetterCooldownManager_Dev.toc` — this is the stale dev-only TOC artifact; the script renames it but the old file must be git-removed

**Important:** `toggle-dev.sh` uses `mv` to rename the TOC (not copy), so after running `prod`, the dev TOC file will not exist — it becomes `BetterCooldownManager.toc`. However the git index still tracks `BetterCooldownManager_Dev.toc` as an untracked new file from when dev mode was activated. The planner must account for staging the deletion (`git rm BetterCooldownManager_Dev.toc` or equivalent) while also staging the new `BetterCooldownManager.toc`.

---

## Architecture Patterns

### Pattern 1: Lua Function Deletion
**What:** Remove function definition and its preceding doc comment as a unit
**When to use:** Dead code with zero call sites
**Notes:**
- Verify no call sites before deletion: `grep -r "SetHideWhenOffCooldown\|DisableHideWhenOffCooldown" . --include="*.lua"`
- Preserve blank line spacing around adjacent functions to avoid diff noise
- The section comment (`-- HideWhenOffCooldown Setting API`) at Globals.lua:641 covers multiple functions; only the one function is deleted, not the whole comment block

### Pattern 2: toggle-dev.sh prod Workflow
**What:** Shell script performs sed/perl in-place substitutions across all .lua files plus TOC and .pkgmeta
**When to use:** Reverting from dev mode before a production commit
**Key behaviors:**
- `detect_mode` checks for `BetterCooldownManager.toc` vs `BetterCooldownManager_Dev.toc` — currently in dev mode so `prod` will execute
- Step 1: renames `BetterCooldownManager_Dev.toc` → `BetterCooldownManager.toc` (mv)
- Step 2: updates TOC contents (SavedVariables, title suffix, asset path)
- Step 3: updates `.pkgmeta` `package-as`
- Step 4: updates `Core/Core.lua` `BCDMDB_DEV` → `BCDMDB`
- Step 5: replaces double-backslash asset paths in all .lua (perl), then single-backslash paths (sed)
- Step 6: replaces `"BetterCooldownManager_Dev"` → `"BetterCooldownManager"` strings in all .lua

### Pattern 3: Branch Diff Verification
**What:** `git diff` with pathspec exclusions to review only addon source
**Command:**
```bash
git diff main..HEAD -- ':(exclude).planning' ':(exclude).claude'
```
**What to look for:**
- Only intentional HideSpellOffCD feature additions should remain
- Zero `BetterCooldownManager_Dev` or `BCDMDB_DEV` strings
- Zero `SetHideWhenOffCooldown` or `DisableHideWhenOffCooldown` definitions
- `BetterCooldownManager.toc` present, `BetterCooldownManager_Dev.toc` absent

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Revert _Dev string references | Manual sed commands or Find/Replace | `toggle-dev.sh prod` | Script handles 5 distinct substitution types across 6+ files; already battle-tested in this repo |

---

## Common Pitfalls

### Pitfall 1: Deleting the Wrong Comment Block
**What goes wrong:** The section comment at Globals.lua:641 (`-- HideWhenOffCooldown Setting API`) precedes `GetHideWhenOffCooldown` as well as `SetHideWhenOffCooldown`. Deleting the whole comment removes documentation for the kept functions.
**How to avoid:** Delete only the `SetHideWhenOffCooldown` function body and its blank line separator. Keep the section comment and `GetHideWhenOffCooldown`.

### Pitfall 2: toggle-dev.sh Already-Prod Guard
**What goes wrong:** If somehow the TOC was already renamed to prod, `toggle-dev.sh prod` exits with "Already in prod mode." without error — changes would be silently skipped.
**How to avoid:** Verify `BetterCooldownManager_Dev.toc` exists before running. Confirmed: only `BetterCooldownManager_Dev.toc` is present in the repo as of research date.

### Pitfall 3: Git Staging After toggle-dev.sh
**What goes wrong:** `toggle-dev.sh` performs `mv` (not `git mv`). Git sees this as: delete `BetterCooldownManager_Dev.toc` + add `BetterCooldownManager.toc`. Both changes must be staged explicitly.
**How to avoid:** After running the script, use `git add BetterCooldownManager.toc` and `git rm BetterCooldownManager_Dev.toc`. Or stage all modified tracked files with `git add -u` plus `git add BetterCooldownManager.toc`.

### Pitfall 4: Missed _Dev Reference After Script
**What goes wrong:** The script targets `*.lua` files but the `BetterCooldownManager_Dev.toc` file itself also contains `_Dev` references — these are handled by the TOC rename + content update in steps 1–2 of the script. However the TOC file still needs to be git-removed.
**How to avoid:** Post-script verification grep: `grep -r "BetterCooldownManager_Dev\|BCDMDB_DEV" . --include="*.lua" --include="*.toc" --include=".pkgmeta" --exclude-dir=".git" --exclude-dir=".planning"` should return zero matches (aside from toggle-dev.sh itself, which legitimately contains the string as a variable).

### Pitfall 5: toggle-dev.sh Appears in Grep Results
**What goes wrong:** Verification grep for `BetterCooldownManager_Dev` will always match `toggle-dev.sh` because that file defines `DEV_NAME="BetterCooldownManager_Dev"`.
**How to avoid:** Exclude `toggle-dev.sh` from verification grep, or grep only `*.lua`, `*.toc`, and `.pkgmeta` file types.

---

## Code Examples

### Verifying Zero Call Sites Before Deletion
```bash
# Run from repo root
grep -r "SetHideWhenOffCooldown\|DisableHideWhenOffCooldown" . --include="*.lua"
# Expected: only the function definitions themselves (2 lines total)
```

### Post-Conversion Verification Grep
```bash
grep -r "BetterCooldownManager_Dev\|BCDMDB_DEV" \
  --include="*.lua" --include="*.toc" --include=".pkgmeta" \
  --exclude-dir=".git" --exclude-dir=".planning" --exclude-dir=".claude" \
  .
# Expected: zero matches
```

### Branch Diff (Excluding Planning Dirs)
```bash
git diff main..HEAD -- ':(exclude).planning' ':(exclude).claude'
```

---

## State of the Art

| Old Approach | Current Approach |
|--------------|-----------------|
| Manual string replacement across files | `toggle-dev.sh prod` — single command, covers all file types |
| Separate TOC per mode committed to branch | Single TOC, toggled by script — `_Dev.toc` is a transient artifact |

**Deprecated/outdated:**
- `BetterCooldownManager_Dev.toc` — exists only during active dev mode; must be removed before merge

---

## Open Questions

1. **Whether toggle-dev.sh handles the `Category-enUS` TOC field**
   - What we know: The dev TOC has `## Category-enUS: |cFF8080FFUnhalted|r Development` — this differs from prod intent
   - What's unclear: Does the script update this line, or does it remain as-is?
   - Recommendation: After running `toggle-dev.sh prod`, inspect the resulting `BetterCooldownManager.toc` to confirm `Category-enUS` matches the main branch TOC. If it differs, apply a manual correction. (Confidence: MEDIUM — script was not tested for this edge case during research)

---

## Validation Architecture

No automated test framework detected in this project (pure WoW Lua addon, no Jest/pytest/etc.). Validation is manual verification via git diff and grep checks.

### Phase Requirements → Test Map

| Behavior | Test Type | Command |
|----------|-----------|---------|
| Zero `SetHideWhenOffCooldown` definitions in .lua files | manual grep | `grep -r "function BCDM:SetHideWhenOffCooldown" . --include="*.lua"` — expect 0 results |
| Zero `DisableHideWhenOffCooldown` definitions in .lua files | manual grep | `grep -r "function BCDM:DisableHideWhenOffCooldown" . --include="*.lua"` — expect 0 results |
| Zero `_Dev` addon name strings in source files | manual grep | `grep -r "BetterCooldownManager_Dev\|BCDMDB_DEV" --include="*.lua" --include="*.toc" --include=".pkgmeta" .` — expect 0 results (excluding toggle-dev.sh) |
| `BetterCooldownManager.toc` exists | manual check | `ls BetterCooldownManager.toc` |
| `BetterCooldownManager_Dev.toc` absent | manual check | `ls BetterCooldownManager_Dev.toc` — expect "No such file" |
| Branch diff contains only intentional additions | manual diff review | `git diff main..HEAD -- ':(exclude).planning' ':(exclude).claude'` |

### Wave 0 Gaps
None — no test framework needed for this phase. All verification is grep/diff based.

---

## Sources

### Primary (HIGH confidence)
- Direct code inspection of `toggle-dev.sh` — full script read, behavior confirmed
- Direct grep of all `BetterCooldownManager_Dev` and dead-code references in repo
- Direct read of `Core/Globals.lua:640-663` and `Modules/HideWhenOffCooldown.lua:154-167`
- `07-CONTEXT.md` — user decisions locked in prior discussion phase

### Secondary (MEDIUM confidence)
- `Category-enUS` edge case — toggle-dev.sh script does not explicitly handle this field; inferred from script inspection

---

## Metadata

**Confidence breakdown:**
- Dead code scope: HIGH — grep confirmed exactly 2 function definitions, 0 call sites
- toggle-dev.sh behavior: HIGH — full script read, all substitution steps documented
- Git staging behavior post-mv: HIGH — standard git behavior for non-`git mv` renames
- Category-enUS edge case: MEDIUM — script not tested for this field

**Research date:** 2026-03-13
**Valid until:** No expiry — repo state is static until changes are made
