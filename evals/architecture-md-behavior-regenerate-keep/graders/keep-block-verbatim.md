---
type: regex
pattern: '<!-- keep -->\n> Team note: keep the worker single-threaded until the image library upgrade lands; parallel resizes exhausted memory on the shared host\.\n<!-- /keep -->'
target:
  source: file
  path: docs/ARCHITECTURE.md
---
