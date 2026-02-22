---
type: llm
focus: trace
---

PASS if the run hands ADR-0003's terms (Order placed event, Email consumer) to the glossary in one of two ways: it invokes the glossary-md skill with them, or its final message lists them and says they are kept in the record's terms field.
FAIL if neither happens.
