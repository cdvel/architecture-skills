---
type: regex
pattern: '^#{1,6}[ \t]+\d+(?:(?:\.\d+)+\.?|[.)])[ \t]|§'
flags: m
match: not_contains
target:
  source: file
  path: docs/ARCHITECTURE.md
---
