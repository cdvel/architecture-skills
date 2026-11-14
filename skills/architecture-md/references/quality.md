# Gaps and quality checks

## Gaps

Write a gap where the missing content would go:

```
> **Gap:** <what is missing, or the file that couldn't be read>.
> **Question:** <the specific question someone would answer to close it>.
```

| Situation | Write |
|---|---|
| A file can't be read | A gap that names the file |
| Unclear structure | What is observed, with citations, followed by `**To confirm:**` and what the team should confirm |
| Missing information | A gap with the specific question |
| Ambiguous pattern | Each possible reading, marked *Inferred:* with what it rests on |

Never fill a gap from general knowledge of how such systems are usually built.

## Checks before saving

Run these on the assembled doc; fix what they find or turn it into a gap.

- **Completeness.** Every unit on the map has a Components entry. Env vars, integrations, deployment, security and observability are covered or carry a gap. Every first-tier section from [sections.md](sections.md) is present.
- **Evidence.** Sample about ten cited paths and confirm they exist at those lines. Quoted code matches the files. Configuration matches the example env files and the code that reads env vars. Endpoints match the route definitions. Schemas match the migrations.
- **Existing docs.** Compare the README, the glossary and other docs against the code. Each contradiction is recorded with both citations, as the ground rules in SKILL.md require. Concepts the glossary defines carry its terms, with the code's name mapped once where it differs.
- **Coverage by reader.** A new hire finds the purpose, the components and the key paths. An operator finds deployment, configuration, observability and CI/CD. A security reviewer finds trust boundaries, auth, secrets and the threat table. An architect finds the diagrams, the data flows and the key decisions.
- **Headings and links.** Headings follow [sections.md](sections.md); every contents link and cross-reference resolves to a heading.
- **Size.** At comprehensive level, code blocks under 50 lines and sections under 500 lines. At either level, above about 3,500 lines in total, suggest a split in the report (for example one file per unit); don't split unasked.

## Independent check

Only with `--verify`. Before saving, a fresh subagent that didn't write the doc gets the doc and the repo, checks a sample of about 20 claims across sections (every `path:line` claim in Security included), and returns the mismatches. Fix each one or turn it into a gap, and give the result in the report. Without subagents, run the check as a separate pass that starts from the doc and the code alone, and say in the report that it was not independent.
