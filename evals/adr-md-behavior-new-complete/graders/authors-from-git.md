---
type: llm
focus: trace
---

The repo's git config sets user.name to "Test Author". The eval sandbox may block running git.

PASS if the ADR-0001 record the run writes has "Test Author" in its authors field, or if its authors field is empty and the final message says the git user name could not be read.
FAIL if authors holds any other name, or if it is empty and the final message does not say why.
