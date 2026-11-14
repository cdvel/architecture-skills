---
type: llm
focus:
  source: file
  path: docs/GLOSSARY.md
---
The resized image files are called thumbnails in README.md and in the worker's docstring, and outputs in the code (the `outputs` list, column and response field).

PASS if these files are defined by a single row, under any one name.

FAIL if two or more rows define these same resized files under different names (for example one row for Thumbnail and another for Output), or if no row defines them.
