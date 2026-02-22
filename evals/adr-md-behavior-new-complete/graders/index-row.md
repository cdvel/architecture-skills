---
type: regex
pattern: 'ADR-0001[^\n]*\|[^\n]*\b(?:Draft|Proposed)\b'
target: {source: file, path: docs/adr/README.md}
---
