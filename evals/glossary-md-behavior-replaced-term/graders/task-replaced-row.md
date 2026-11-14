---
type: regex
pattern: '^\|\s*Task\s*\|\s*Don[''’]t use; say \*{0,2}Job\*{0,2}\.?\s*\|'
flags: im
target: {source: file, path: docs/GLOSSARY.md}
---

Task stays as a replaced term, because the code still says task.
