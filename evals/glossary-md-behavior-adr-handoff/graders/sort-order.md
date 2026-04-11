---
type: regex
pattern: '^\|\s*Original\s*\|[\s\S]*^\|\s*Thumbnail\s*\|[\s\S]*^\|\s*Variant\s*\|[\s\S]*^\|\s*Preset\s*\|'
flags: im
target:
  source: file
  path: docs/GLOSSARY.md
---

ADR rows by number (alphabetical within ADR-0003), then the Convention row.
