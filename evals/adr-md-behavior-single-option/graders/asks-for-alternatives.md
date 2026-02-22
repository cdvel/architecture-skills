---
type: llm
---

PASS if the response says a decision record needs at least two options (or that the alternatives are missing) and asks the user which alternatives were considered, or proposes candidate alternatives for the user to confirm, without writing the record.
FAIL if it writes the record with the shared cache as the only option, or goes ahead without raising the missing alternatives.
