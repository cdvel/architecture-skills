---
type: regex
pattern: '(?:[\w./-]+\.(?:py|sql|ya?ml|txt|example|toml|json)|Dockerfile):\d+'
target:
  source: file
  path: docs/ARCHITECTURE.md
---
