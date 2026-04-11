---
type: regex
pattern: '^\|\s*Preset\s*\|[^\n]*\|\s*Convention\s*\|\s*$[\s\S]*^\|\s*Variant\s*\|[^\n]*\|\s*Convention\s*\|\s*$'
flags: im
target:
  source: file
  path: docs/GLOSSARY.md
---

Both terms are rows sourced as Convention, in alphabetical order.
