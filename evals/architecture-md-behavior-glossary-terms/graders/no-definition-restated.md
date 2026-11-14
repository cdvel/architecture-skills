---
type: regex
pattern: '\b(jobs?|renditions?)\*?\s+(is|are|means?)\s+(one|an?|the)\s+(accepted|resized)'
flags: i
match: not_contains
target: {source: file, path: docs/ARCHITECTURE.md}
---

The doc does not restate a glossary definition in the form "a rendition is one resized copy" or "a job is one accepted upload".
