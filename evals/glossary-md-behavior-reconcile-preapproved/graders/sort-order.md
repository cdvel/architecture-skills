---
type: regex
pattern: '^\|\s*Order\s*\|[\s\S]*^\|\s*Fulfillment\s*\|[\s\S]*^\|\s*Checkout\s*\|[\s\S]*^\|\s*Currency code\s*\|[\s\S]*^\|\s*Carts?\s*\|[\s\S]*^\|\s*SKU\s*\|'
flags: im
target:
  source: file
  path: docs/GLOSSARY.md
---

ADR-0001, ADR-0002, then Predates ADRs, Standard, Convention (alphabetical).
