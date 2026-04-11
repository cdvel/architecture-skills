---
type: regex
pattern: '^\|\s*Thumbnail\s*\|[^\n]*ADR-0002'
flags: im
match: not_contains
target:
  source: file
  path: docs/GLOSSARY.md
---

The Thumbnail row no longer cites the superseded ADR-0002.
