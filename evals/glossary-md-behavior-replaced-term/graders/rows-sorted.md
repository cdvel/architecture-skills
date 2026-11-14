---
type: regex
pattern: '^\|\s*Job\s*\|[\s\S]*^\|\s*Rendition\s*\|[\s\S]*^\|\s*Task\s*\|'
flags: im
target: {source: file, path: docs/GLOSSARY.md}
---

All three rows are Convention, so they sort alphabetically: Job, Rendition, Task.
