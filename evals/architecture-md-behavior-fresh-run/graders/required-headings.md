---
type: regex
pattern: '^(?=[\s\S]*^## Summary[ \t]*$)(?=[\s\S]*^## Components[ \t]*$)(?=[\s\S]*^## Security[ \t]*$)'
flags: m
target:
  source: file
  path: docs/ARCHITECTURE.md
---
