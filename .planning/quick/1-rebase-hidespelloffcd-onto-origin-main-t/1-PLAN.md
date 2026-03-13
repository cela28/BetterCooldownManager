---
phase: quick
plan: 1
type: execute
wave: 1
depends_on: []
files_modified: []
autonomous: false
requirements: ["rebase-onto-upstream"]

must_haves:
  truths:
    - "HideSpellOffCD branch is rebased on top of latest origin/main"
    - "All feature commits preserved and functional after rebase"
    - "Branch pushed to myfork remote"
  artifacts: []
  key_links: []
---

<objective>
Rebase the HideSpellOffCD branch onto origin/main to incorporate 20 upstream commits.

Purpose: Upstream has significant changes (folder restructuring, aura overlay rewrite, vertical layout swap, load conditions) that need to be integrated before our feature branch can be submitted as a PR.

Output: Clean rebased branch pushed to myfork/HideSpellOffCD.
</objective>

<execution_context>
@/home/sntanavaras/.claude/get-shit-done/workflows/execute-plan.md
@/home/sntanavaras/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md

Branch state:
- Current branch: HideSpellOffCD
- 25 commits ahead of origin/main (7 feature commits + 18 docs/planning commits)
- origin/main has 20 new commits since merge-base e87e482

Our feature commits touch these files:
- Core/Defaults.lua (feat 01-01: add HideWhenOffCooldown defaults)
- Core/Globals.lua (feat 01-01 + 02-01: API functions + IsSpellOnCooldown)
- Modules/HideWhenOffCooldown.lua (feat 03-01: new file, no upstream conflict)
- Modules/CooldownManager.lua (feat 03-01 + 04-01: module registration + alpha filtering)
- Modules/Init.xml (feat 03-01: module registration)
- Core/GUI.lua (feat 05-01: HideWhenOffCooldown checkbox)

Conflict risk analysis:
- Core/GUI.lua — HIGH risk (upstream: 13 commits touched this file including layout swap, load conditions, locale)
- Core/Globals.lua — MEDIUM risk (upstream: copy pasta fix, code moves, specID changes)
- Core/Defaults.lua — MEDIUM risk (upstream: various feature additions)
- Modules/Init.xml — LOW risk (upstream: folder restructuring)
- Modules/CooldownManager.lua — SAFE (no upstream changes)
- Modules/HideWhenOffCooldown.lua — SAFE (new file, no upstream equivalent)

Remotes:
- origin = upstream DaleHuntGB/BetterCooldownManager (no push)
- myfork = user's fork cela28/BetterCooldownManager (push here)
</context>

<tasks>

<task type="auto">
  <name>Task 1: Rebase feature branch onto origin/main</name>
  <files>Core/Defaults.lua, Core/Globals.lua, Core/GUI.lua, Modules/Init.xml, Modules/CooldownManager.lua, Modules/HideWhenOffCooldown.lua</files>
  <action>
Rebase HideSpellOffCD onto origin/main. Strategy:

1. Fetch latest from origin: `git fetch origin`
2. Create a safety backup branch: `git branch HideSpellOffCD-backup`
3. Begin interactive-free rebase: `git rebase origin/main`
4. Resolve conflicts as they arise. Key guidance for each conflicting file:

**Core/Defaults.lua:** Our change adds `HideWhenOffCooldown = false` to Essential and Utility bar defaults. Accept upstream's structure changes, then re-add our default field in the correct location within each bar's defaults table.

**Core/Globals.lua:** Our changes add `GetHideWhenOffCooldown()`, `SetHideWhenOffCooldown()` API functions and `IsSpellOnCooldown()`. Accept upstream's restructuring (moved code, copy pasta fix, specID), then ensure our functions are still present and correctly placed. Functions should be in the BCM namespace/module.

**Core/GUI.lua:** Our change adds a HideWhenOffCooldown checkbox in the Essential/Utility settings section. This is the highest-risk conflict. Accept upstream's extensive GUI changes (vertical layout, load conditions UI), then re-apply our checkbox addition. Look for the settings toggle section (near CenterHorizontally or similar per-bar boolean toggles) and add our checkbox after it. Use the same pattern as other toggles in the updated GUI code.

**Modules/Init.xml:** Our change adds `<Script file="HideWhenOffCooldown.lua"/>`. Accept upstream's folder restructuring, ensure the line is present in the correct Init.xml within Modules/.

5. After each conflict resolution, `git add` the resolved files and `git rebase --continue`.
6. If rebase gets stuck or too messy, abort with `git rebase --abort` and report the situation for human decision.

IMPORTANT: Do NOT use `git rebase -i` (interactive mode is not supported). Use plain `git rebase origin/main`.
IMPORTANT: .planning/ and .claude/ directories are part of our branch but should NOT be merged to main. They will naturally rebase along; that is fine for now.
  </action>
  <verify>
    <automated>git log --oneline origin/main..HEAD | head -30 && echo "---" && git diff --stat origin/main..HEAD -- . ':!.planning' ':!.claude' | tail -10 && echo "---" && echo "Rebase status:" && git status --short | head -10</automated>
  </verify>
  <done>All commits cleanly rebased on top of origin/main. No merge conflicts remaining. git status is clean.</done>
</task>

<task type="checkpoint:human-verify" gate="blocking">
  <what-built>Rebased HideSpellOffCD branch onto latest origin/main, resolving any conflicts in Core/GUI.lua, Core/Globals.lua, Core/Defaults.lua, and Modules/Init.xml.</what-built>
  <how-to-verify>
    1. Review the conflict resolutions: `git log --oneline origin/main..HEAD` should show our commits on top of origin/main
    2. Spot-check key files:
       - `Core/Defaults.lua` — HideWhenOffCooldown defaults still present in Essential/Utility bars
       - `Core/Globals.lua` — GetHideWhenOffCooldown, SetHideWhenOffCooldown, IsSpellOnCooldown functions present
       - `Core/GUI.lua` — HideWhenOffCooldown checkbox code present in settings
       - `Modules/HideWhenOffCooldown.lua` — file exists and is intact
       - `Modules/Init.xml` — includes HideWhenOffCooldown.lua
    3. If anything looks wrong, say what needs fixing
    4. If all good, say "approved" and the branch will be force-pushed to myfork
  </how-to-verify>
  <resume-signal>Type "approved" to push, or describe issues to fix</resume-signal>
</task>

<task type="auto">
  <name>Task 3: Force-push rebased branch to myfork</name>
  <files></files>
  <action>
Force-push the rebased branch to the user's fork:

```
git push myfork HideSpellOffCD --force-with-lease
```

Use --force-with-lease (not --force) for safety. This is expected after a rebase.
  </action>
  <verify>
    <automated>git log --oneline myfork/HideSpellOffCD -5 2>/dev/null || echo "Check remote manually"</automated>
  </verify>
  <done>HideSpellOffCD branch pushed to myfork remote. Branch is up to date with local.</done>
</task>

</tasks>

<verification>
- `git log --oneline origin/main..HEAD` shows all feature commits on top of origin/main
- `git status` is clean (no unresolved conflicts)
- `git diff origin/main..HEAD -- Modules/HideWhenOffCooldown.lua` shows our module intact
- `grep -c "HideWhenOffCooldown" Core/Defaults.lua Core/Globals.lua Core/GUI.lua` confirms feature code present in all three files
- Branch is pushed to myfork/HideSpellOffCD
</verification>

<success_criteria>
- HideSpellOffCD is rebased on latest origin/main with zero conflicts remaining
- All 7 feature commits preserved with correct content
- Feature code (HideWhenOffCooldown) functional in the rebased codebase
- Branch pushed to myfork remote
</success_criteria>

<output>
After completion, create `.planning/quick/1-rebase-hidespelloffcd-onto-origin-main-t/1-SUMMARY.md`
</output>
