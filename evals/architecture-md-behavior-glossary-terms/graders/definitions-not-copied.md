---
type: llm
focus:
  source: file
  path: docs/ARCHITECTURE.md
---
The repository's docs/GLOSSARY.md defines two terms: Job ("One accepted upload, tracked from queued to done or failed.") and Rendition ("One resized copy of an uploaded image, saved as WebP at one of the configured sizes."). The architecture doc should use these terms and link the glossary, but never define them.

PASS if no sentence, list item or table cell in the document exists to say what a job or a rendition is, in the glossary's words or its own. Using the terms, linking the glossary, mapping a term to the code's names (for example "the code calls renditions `outputs`"), describing what the code does with them, and quoting the disputed words of a definition in a conflict note with a citation are all fine.

FAIL if the document defines either term, for example in a vocabulary or terminology line ("a rendition is one resized copy of an image").
