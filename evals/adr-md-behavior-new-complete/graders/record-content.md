---
type: llm
focus: trace
---

Look at the content written to docs/adr/0001-*.md.
PASS if the record has Context, Options considered, Decision, Consequences and References sections; lists all three options with a reason each was chosen or rejected; has a Decision of one paragraph choosing the background worker with a job queue; has at least one positive and one negative consequence; and cites src/api/resize.js.
FAIL if any of these is missing, or if the record is not written at all.
