---
type: llm
focus:
  source: file
  path: docs/ARCHITECTURE.md
---
The repository's docs/GLOSSARY.md defines "Rendition" as one resized copy of an uploaded image. The code never uses that word: it calls these files outputs (the `outputs` list in worker/worker.py, the `outputs` column and response field) and thumbnails (README.md, the worker's docstring).

PASS if the document calls the resized images renditions in at least one of the Components, Data flows or Data stores sections, and says at least once that what the code calls outputs or thumbnails is what the glossary calls a rendition.

FAIL if "rendition" appears only in a link to the glossary or not at all, or if the document uses it without ever relating it to the code's names.
