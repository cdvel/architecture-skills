---
type: regex
pattern: '^\|\s*Job\s*\|[^\n]*upload[^\n]*\|\s*Convention\s*\|\s*$'
flags: im
target: {source: file, path: docs/GLOSSARY.md}
---

Job has a row carrying the old meaning (one upload), sourced as Convention.
