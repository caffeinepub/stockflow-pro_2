# StockFlow Pro

## Current State
HistoryTab and DashboardTab lose item-level detail (baleItemsList) after page refresh. The bilty header info is preserved from `transactions`. But per-item details (items in bale, qty, shop/godown split) are stored in `inwardSaved` records which are never passed to either tab.

## Requested Changes (Diff)

### Add
- `inwardSaved: InwardSavedEntry[]` prop to HistoryTab, DashboardTab, ItemHistoryPanel interfaces
- Import `InwardSavedEntry` type in HistoryTab.tsx and DashboardTab.tsx

### Modify
- App.tsx ~line 2089: add `inwardSaved={inwardSaved}` to HistoryTab render
- App.tsx ~line 1953: add `inwardSaved={inwardSaved}` to DashboardTab render
- HistoryTab.tsx journey modal: include DIRECT_STOCK in type filter; cross-reference inwardSaved by bilty number to get baleItemsList when tx.baleItemsList is empty
- DashboardTab.tsx ItemHistoryPanel: receive inwardSaved; cross-reference inwardSaved by bilty number for baleItemsList when tx.baleItemsList is empty

### Remove
- Nothing

## Implementation Plan
1. Add InwardSavedEntry import to HistoryTab.tsx and DashboardTab.tsx
2. Add inwardSaved prop to all three component interfaces
3. In App.tsx pass inwardSaved={inwardSaved} to both HistoryTab and DashboardTab
4. In HistoryTab journey modal: add DIRECT_STOCK to type filter; fallback to inwardSaved lookup when baleItemsList is missing
5. In DashboardTab/ItemHistoryPanel: pass inwardSaved down; fallback to inwardSaved lookup for baleItemsList
