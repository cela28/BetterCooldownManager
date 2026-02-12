---
status: testing
phase: all-phases
source: 01-01-SUMMARY.md, 02-01-SUMMARY.md, 03-01-SUMMARY.md, 04-01-SUMMARY.md, 05-01-SUMMARY.md
started: 2026-02-12T00:00:00Z
updated: 2026-02-12T00:00:00Z
---

## Current Test

number: 1
name: Settings Checkbox Exists
expected: |
  Open BetterCooldownManager settings. Navigate to Essential bar settings. You should see a "Hide When Off Cooldown" checkbox inside the Essential Settings group, after the CenterHorizontally checkbox.
awaiting: user response

## Tests

### 1. Settings Checkbox Exists
expected: Open BetterCooldownManager settings. Navigate to Essential bar settings. You should see a "Hide When Off Cooldown" checkbox inside the Essential Settings group, after the CenterHorizontally checkbox.
result: [pending]

### 2. Checkbox Tooltip on Hover
expected: Hover over the "Hide When Off Cooldown" checkbox. A GameTooltip should appear saying "Hides spell icons that are not on cooldown".
result: [pending]

### 3. Checkbox Default State
expected: On a fresh profile (or after resetting settings), the "Hide When Off Cooldown" checkbox should be unchecked (disabled by default). All spell icons should be visible as normal.
result: [pending]

### 4. Enable Feature - Icons Hide When Off Cooldown
expected: Check the "Hide When Off Cooldown" checkbox for Essential bar. Spell icons that are NOT on cooldown should immediately disappear (become invisible). Icons for spells currently ON cooldown should remain visible.
result: [pending]

### 5. Icons Reappear When Spell Goes On Cooldown
expected: With the feature enabled, use a spell that was previously hidden (off cooldown). The icon should reappear as the spell goes on cooldown and its cooldown spiral becomes visible.
result: [pending]

### 6. Icons Hide When Cooldown Finishes
expected: Watch a spell icon that is on cooldown. When the cooldown completes, the icon should disappear (hide) since it's no longer on cooldown.
result: [pending]

### 7. GCD-Only Spells Stay Hidden
expected: With the feature enabled, use a spell that has no real cooldown (only GCD). The icon should briefly appear during the GCD then hide again when the GCD ends. It should NOT stay visible just because of the GCD.
result: [pending]

### 8. Charge Spell Detection
expected: If you have a charge-based spell (e.g., a spell with 2 charges), the icon should remain visible as long as at least one charge is recharging. It should only hide when all charges are fully available.
result: [pending]

### 9. Layout Collapse - Icons Fill Gaps
expected: With the feature enabled and some icons hidden, the remaining visible icons should shift/compact together toward the center. There should be no empty gaps between visible icons.
result: [pending]

### 10. Layout Restore When Icons Reappear
expected: When hidden icons reappear (spell goes on cooldown), the layout should expand to accommodate them. Icons should reposition correctly without overlapping.
result: [pending]

### 11. Disable Feature - All Icons Restore
expected: Uncheck the "Hide When Off Cooldown" checkbox. ALL spell icons should immediately reappear and the bar layout should return to its normal full state.
result: [pending]

### 12. Utility Bar Support
expected: Navigate to Utility bar settings. The same "Hide When Off Cooldown" checkbox should exist. Enabling it should hide/show icons on the Utility bar independently from the Essential bar setting.
result: [pending]

### 13. Setting Persists Through Reload
expected: Enable the feature for Essential bar, then /reload the UI. After reload, the checkbox should still be checked and icons should still be hidden when off cooldown.
result: [pending]

## Summary

total: 13
passed: 0
issues: 0
pending: 13
skipped: 0

## Gaps

[none yet]
