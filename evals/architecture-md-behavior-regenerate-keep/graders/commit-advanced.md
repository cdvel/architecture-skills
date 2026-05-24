---
type: regex
pattern: '^commit: ([0-9a-f]{40})[ \t]*$[\s\S]*^previous_commit: (?!\1)[0-9a-f]{7,40}[ \t]*$'
flags: m
target:
  source: file
  path: docs/ARCHITECTURE.md
---
