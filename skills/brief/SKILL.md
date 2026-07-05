---
name: brief
description: "Gives an architect's brief of a codebase in chat: a one-paragraph verdict, an ASCII picture of the main parts, one request traced end to end, where to start reading, and a short assessment labeled as opinion. Built from the ARCHITECTURE.md that the architecture-md skill writes; it does not explore the code and writes no files. Use when someone wants the big picture, an overview or an architect's brief of a repo, for example 'give me an architect's brief of this repo', 'what's the big picture here before I review it', 'summarize how this codebase is put together, keep it short', 'walk me through the architecture'. Not for a specific question about how one piece of code works, for writing or updating ARCHITECTURE.md (architecture-md), for recording a decision (adr-md), or for the project glossary (glossary-md)."
---

# brief

An architect's brief in chat, built from the repo's `ARCHITECTURE.md` (written by the architecture-md skill): what the system is, how it is built, and an opinion on it, in plain language with diagrams and tables that read well in a terminal.

## Scope

- Reads `ARCHITECTURE.md`, the ADR index and the glossary when they exist, and git (read-only, for the staleness check).
- Writes no files and runs no builds or tests. Never explores source code, even when the doc is missing.
- Not for: writing or updating `ARCHITECTURE.md` (architecture-md), recording decisions (adr-md), the glossary (glossary-md), or a specific question about one piece of code (answer that directly, not as a brief).

## Find the doc

Use the path the user names. Otherwise look for `docs/ARCHITECTURE.md`, then `ARCHITECTURE.md` at the repo root. If both exist, use the one whose `generator` starts with `architecture-md` (the `docs/` one if both do) and mention the other.

## Check its origin

Read the frontmatter. The doc counts as written by architecture-md only if `generator` starts with `architecture-md`.

- **No doc:** say no `ARCHITECTURE.md` was found and where you looked, suggest running the architecture-md skill to write one, and stop.
- **Doc not written by architecture-md:** say so, suggest running architecture-md, and ask whether to brief from this doc anyway (in plain text, or with the harness's question tool if it has one). If the user says yes, or the request already said to go ahead, brief from it and say up front what changes: facts are limited to what this doc says, parts it does not cover are marked as gaps, and staleness is checked only if it records a commit.

## Check staleness

From the repo root, where `<commit>` is the doc's `commit` and `<doc>` its path:

```
git merge-base --is-ancestor <commit> HEAD
git rev-list --count <commit>..HEAD -- . ':(exclude)<doc>'
```

The count leaves out commits that only changed the doc itself, so committing the doc does not make it look stale.

- **0:** the source line says the doc matches HEAD.
- **N above 0:** the source line says the doc is N commits behind HEAD and suggests regenerating it with architecture-md. Continue with the brief.
- **Commit not an ancestor of HEAD, or unknown** (another branch, a rebase, a shallow clone): say its age cannot be measured from this checkout and suggest regenerating.
- **No git, or no `commit` field:** say staleness was not checked.

## Read

Read the frontmatter and Summary first, then only the sections each part of the brief draws on (see Layout). For a long doc, read section by section.

If they exist, also read the ADR index (`README.md` in `docs/adr`, `docs/decisions`, `adr` or `doc/adr`) and the glossary (`GLOSSARY.md` or `TERMINOLOGY.md`, at the root or in `docs/`). Read a single ADR only to check the reason for a choice you are about to criticize. Use glossary definitions when you define terms.

## Reasons before criticism

Before calling a choice a weakness, look for its reason: the key decisions table in Summary, reasons from code comments that the doc quotes in Components, and ADRs. If a reason exists, state it and say whether it still holds given what the doc shows. If none is recorded, say so: a missing reason is an open question, not proof of a mistake.

## Layout

Begin the reply with the verdict paragraph: no preamble and no heading before it. Then the parts below, in order, each under a short heading.

| Part | Form | Draws on |
|---|---|---|
| Verdict | One paragraph: what the system is and for whom, how it is built, and an overall judgment in its last sentence, worded as opinion ("In my view ...") | Summary |
| Source | One line: doc path, generator version, generated date, short commit, staleness | Frontmatter, git |
| Picture | ASCII diagram of users, main parts, data stores and external systems | Diagrams, Summary |
| Parts | Table: part, what it does, where it lives | Components |
| A request, end to end | 4 to 8 numbered steps for the main user action, or a short ASCII sequence | Data flows |
| Where to start reading | 3 to 5 files, one line each on why | Quick reference, Components |
| Assessment (opinion) | Strengths, risks, open questions | All of the above, ADRs |

- When the doc has nothing for a part, keep the heading with one line naming the missing section.
- When the user asks for a short brief, keep the verdict, source line, picture and assessment, and cut the rest.
- Keep the whole brief under about 120 lines.

## Representation

- **Diagrams:** plain ASCII (`+ - | > < v ^`) in a code block, at most 80 columns wide and about 25 lines. Label arrows with what moves (HTTPS, SQL, queue message). Redraw from the doc's diagrams, keeping only what the verdict needs.
- **Tables:** 2 to 4 columns, short cells, under about 12 rows. Group minor parts into one row.
- **Request path:** name the request (for example "place an order"), then one line per step: which part acts and what it does.
- **Prose** only where a diagram or table does not fit.
- **Plain language:** define every term and acronym on first use in a few words, for example "outbox (a table of events waiting to be sent)".

## Facts and opinions

- Facts come from the doc, the ADRs and the glossary only. Cite the source in square brackets: the doc section, for example [Data flows], or the ADR id, for example [ADR-0003]. One citation per part when the whole part comes from one section; inline otherwise.
- Keep the doc's own markings: what it marks as inferred stays inferred, and its gaps stay gaps.
- Opinions sit only in the verdict's last sentence and under the heading "Assessment (opinion)", worded as opinions ("I would", "this looks"). Under that heading, one line per item, about 3 per label:
  - **Strengths:** what the design gets right, and why it matters here.
  - **Risks:** each with the reason found and whether it still holds, or "no recorded reason".
  - **Open questions:** what a reviewer would ask that the doc does not answer.
- Pick what matters most; do not restate the doc's threat table or open-work list.
