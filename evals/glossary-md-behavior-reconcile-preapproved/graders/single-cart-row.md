---
type: regex
pattern: '^\|\s*carts?\s*\|[\s\S]*^\|\s*carts?\s*\|'
flags: im
match: not_contains
target:
  source: file
  path: docs/GLOSSARY.md
---

Only one Cart row is left.
