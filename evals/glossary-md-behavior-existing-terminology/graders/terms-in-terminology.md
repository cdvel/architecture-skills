---
type: regex
pattern: '^\|\s*PAN\s*\|[\s\S]*^\|\s*Capture\s*\|[\s\S]*^\|\s*Chargeback\s*\|[^\n]*Convention[\s\S]*^\|\s*Refund\s*\|[^\n]*Convention'
flags: im
target:
  source: file
  path: docs/TERMINOLOGY.md
---

The new rows are in docs/TERMINOLOGY.md as Convention, after the Standard row and alphabetical with the existing Convention row.
