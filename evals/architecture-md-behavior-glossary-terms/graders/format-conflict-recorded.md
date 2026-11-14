---
type: llm
focus:
  source: file
  path: docs/ARCHITECTURE.md
---
The repository's docs/GLOSSARY.md defines a rendition as saved as WebP. The worker saves every resized copy as PNG (`copy.save(out, "PNG")` in worker/worker.py).

PASS if the document gives the output format as PNG with a citation to worker/worker.py, and records that this contradicts the glossary's WebP definition, citing the glossary (docs/GLOSSARY.md, with or without a line number).

FAIL if the document says the resized images are WebP, or if it never mentions that the code and the glossary disagree on the format.
