---
type: regex
pattern: '^\|\s*Variant\s*\|[^\n]*\[ADR-0003\]\(adr/0003-resize-on-upload-with-presets\.md\)'
flags: im
target:
  source: file
  path: docs/GLOSSARY.md
---

Variant is a new row sourced with a link to ADR-0003, relative to the glossary.
