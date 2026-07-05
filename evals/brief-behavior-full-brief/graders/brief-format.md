---
type: llm
focus: last_message
---

The repo has a docs/ARCHITECTURE.md written by architecture-md whose recorded commit is the current HEAD. The reply should be an architect's brief built from it.

PASS if all of these hold:

1. The reply opens with a one-paragraph verdict saying what the system is and how it is built, with no heading or preamble before it.
2. It has an ASCII diagram in a code block, and no line of the diagram is clearly wider than about 80 characters.
3. It has a markdown table of the system's parts.
4. It walks through one request (such as placing an order) as numbered steps.
5. Factual parts cite the ARCHITECTURE.md section they come from, for example [Components] or [Data flows].
6. Opinions sit under a heading that labels them as opinion (for example "Assessment (opinion)"), covering strengths, risks and open questions.
7. If the assessment criticizes running payment capture in the worker, sharing one database, or cookie sessions, it mentions the reason the document records for that choice.
8. It does not say the document is out of date or behind HEAD.

FAIL if any of these does not hold.
