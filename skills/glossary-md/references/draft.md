# draft

Proposes terms from what the repo already says, for people to review. Nothing is written before approval.

1. Read the README and other docs, `ARCHITECTURE.md` if there is one, and the code: names of modules, types, tables, queues, routes, config keys and enum values, and comments. Terms an accepted ADR defines come through `backfill`: skip them here and suggest `backfill` in the report.
2. Candidates are words and multi-word phrases with a meaning specific to this project: domain nouns, the things the system creates or stores, and common words used in a narrower sense than usual (a "job" that means one upload). Leave out general programming and product vocabulary (request, handler, database, HTTP, the names of libraries) unless the repo gives it a narrower meaning.
3. Look for one thing under several names (one in the code, another in the docs) and one name with several meanings. One thing gets one row, named as the repo says it most often in prose, with the other names listed in the proposal. A name with several meanings gets a question; under pre-approval, leave it out and list it in the report.
4. Draft each definition as one sentence from how the repo uses the term, with source `Convention`. Show each candidate with one to three `path:line` places where it is used or defined; these citations go in the proposal, not in the glossary.
5. Propose at most about 25 terms per run, the most used first, and say how many more there are. Drop terms already in the glossary, then check duplicates.
6. The user accepts, edits or skips each (default: accept). Write once and report.
