---
name: adr-md
description: Records architecture decisions as numbered ADR files in docs/adr/ and keeps the register consistent (status, supersession links, index). Use when the user wants to write up why the team chose one approach over the alternatives, even without saying "ADR" ("document why we went with a queue instead of cron", "record this decision"), start a decision log or ADR register, propose, accept or deprecate an ADR by number, replace or supersede an earlier decision, fix a typo or broken link in an accepted ADR, or rebuild the ADR index. Refuses content edits to accepted records and offers to supersede them instead. On accept, hands the terms a decision introduces to glossary-md. Not for RFCs or design docs, ARCHITECTURE.md or other docs generated from code, glossary edits, small changes such as adding a dependency, a rename or a config tweak, security reviews of a PR, release notes, or general questions about what ADRs are.
---

# adr-md

Records why the system has its shape: one decision per numbered markdown file, kept next to the code. `architecture-md` documents what the system is; this skill records why.

## Scope

In: new decisions, status changes, replacing a decision with a newer one, cosmetic fixes to locked records, the index.

Out: small changes (a new library, a rename, a config tweak, a refactor inside one component), content edits to a locked record, the glossary file (only `glossary-md` writes it), wiki publishing, git commands that change anything, more than one register per run.

## Start of every run

1. Take the intent from the invocation (`/adr-md new "<topic>"`, `accept 3`) or from the request; ask only if it is unclear. An intent given inline skips the question, never a check.
2. Find the register: the first of `docs/adr`, `docs/decisions`, `adr`, `doc/adr` that exists. If none exists, ask where to create it (default `docs/adr`). When the user only asks to start a register, create the folder and an empty index, then offer `new`.
3. Read every record's number, title and status, including records in other formats (below).
4. Read `ARCHITECTURE.md` if it exists, in `docs/` or at the root.

## Intents

Read the files listed for the intent before starting it.

| Intent | What it does | Read |
|---|---|---|
| `new` | Records a new decision | [new.md](references/new.md), [template.md](references/template.md) |
| `propose` | Draft to Proposed | [status.md](references/status.md) |
| `accept` | Proposed to Accepted; updates the records it replaces; hands its terms to `glossary-md` | [status.md](references/status.md) |
| `deprecate` | Accepted to Deprecated, with a reason and no replacement | [status.md](references/status.md) |
| `supersede` | A new record that replaces an older one, fully or in part | [status.md](references/status.md) |
| `amend` | Typos, broken links and formatting only | [status.md](references/status.md) |
| `index` | Rebuilds the index | [status.md](references/status.md), [template.md](references/template.md) |

A request to change an existing record follows its status: a Draft or Proposed record is edited directly and then run through the checks before save; a locked record takes `amend` for cosmetic fixes, and any other change is refused (see Lifecycle).

## Lifecycle

```
Draft -> Proposed -> Accepted -> Deprecated
                        |            |
                        v            |
                    Superseded <-----+
```

- Draft and Proposed are editable.
- Accepted, Deprecated and Superseded are locked. Status and link fields change only through `accept` and `deprecate`; the body changes only through `amend`. A request to change a locked record's context, options, decision or consequences is refused, even when the request says not to ask: the record is the history of what was decided and why. Offer `supersede`.
- A replacing record lists the old one in `supersedes` or `supersedes_in_part` from its first draft. The old record changes only when the new one is accepted, and its body is never edited.

## Rules

- **Worth an ADR** only if the decision changes a trust boundary or who can call whom, the auth model, how data moves, is stored or is protected, a contract others depend on, or sets a principle later decisions must follow. Reversibility weighs heavily: a choice that is costly to undo leans toward an ADR, one that is cheap to undo may not need one. If it fails, say which test failed and ask; the user can override.
- **Options argued fairly:** describe each rejected option as its supporters would argue it, then say why it lost here.
- **Content:** Context and Consequences cite real file paths and other ADRs. Decision is one declarative paragraph.
- **Writing style:** follow the writing rules in the user's and project's instruction files (CLAUDE.md, AGENTS.md or similar). This skill ships none.
- **Writes:** only records in the register and its index. Terms stay in each record's `terms` field until `accept` hands them to `glossary-md`. Read-only git use (such as `git config user.name`) is fine.
- **Pushback:** name the rule, say why in one sentence, ask whether to proceed. Don't lecture.
- **Questions:** ask in plain text, or with the harness's question tool if it has one.
- **Pre-approval:** a request that already says to go ahead without asking counts as the yes for confirmation steps; state each choice taken.

## Checks before save

Run on every new record before it is written, and on `propose`:

1. One decision per record; if there are several, offer to split.
2. At least two options.
3. At least one positive and one negative consequence.
4. Worth an ADR.
5. Every template section present.
6. Valid frontmatter: every field in the template, link fields as lists, `id` matching the filename number, `status` one of the five values.

A failed check stops the save. Overriding a check needs an explicit yes to that check; a general "go ahead" is not one.

## Records in other formats

Records without frontmatter (adr-tools style, or a `## Status` section) count for numbering, recon and the index. Read the number from the filename, the title from the first heading, the status from the status line or section. Never add frontmatter to them or reformat them. When a workflow must change such a record's status, change only its status line or section, in its existing wording, after showing the change and getting a yes.

## Report

End every run with the files written or changed, each touched record's status, the choices taken without asking, and what happened to the terms.
