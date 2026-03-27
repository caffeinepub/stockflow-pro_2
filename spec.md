# StockFlow Pro

## Current State
WarehouseTab (Queue) has two bugs in bilty/package handling:
1. Auto-fill from Transit (via typing) does not lock the packages field, allowing users to change package count and generate wrong bale labels.
2. Duplicate base bilty check is missing against existing Queue entries — same base bilty can be re-entered with a different package count.

## Requested Changes (Diff)

### Add
- Base bilty duplicate check against `pendingParcels` (Queue) in `handleLog`, both single-package and multi-package paths

### Modify
- `WarehouseTab.tsx` auto-fill useEffect (lines ~196–230): after setting form fields from transit match, also call `setLockedPackages(extractedPkg || null)` to lock the packages field
- `WarehouseTab.tsx` `handleLog` multi-package path: before saving, check if base bilty already exists in `pendingParcels` (stripping X postfix), block with error if found
- `WarehouseTab.tsx` `handleLog` single-package path: the existing `queueBiltyList` exact check should also include a base bilty check against `pendingParcels`

### Remove
- Nothing removed

## Implementation Plan
1. In the auto-fill useEffect, add `setLockedPackages(extractedPkg || null)` after `setForm(...)` when a transit match is found
2. In `handleLog` before both the single-package and multi-package save paths, add:
   - Strip postfix from `bNo` to get `baseBilty`
   - Check if any entry in `pendingParcels` has the same base bilty (strip their postfix too)
   - If match found, block save with error: `Bilty ${baseBilty} already exists in Queue with a different package count`
