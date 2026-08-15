---
name: glossary-md
description: Maintains the project glossary (docs/GLOSSARY.md, or an existing GLOSSARY.md or TERMINOLOGY.md) as one table of terms, each with a one-sentence definition and its source (an ADR, a standard or a team convention). Use when the user wants to start a glossary or a terminology list, add, define or rename terms for the team, record what we call something, write down the project's vocabulary or domain terms, build the ubiquitous language, backfill terms from existing ADRs, or clean up, deduplicate, sort or reconcile the glossary. Also takes the terms of a newly accepted ADR, handed over by adr-md or described in a message. Not for recording a decision (adr-md), writing ARCHITECTURE.md (architecture-md), a plain question about what a word means with nothing to record, API reference docs, or a glossary section inside a README.
---

# glossary-md

Keeps the project's vocabulary in one file that describes the current state: rows that no longer apply are removed, not marked. This skill is the only writer of the file; it reads ADRs and never edits them.

## Files

- **Glossary:** an existing `GLOSSARY.md` or `TERMINOLOGY.md`, at the root or in `docs/`, is used where it is. If several exist, ask which one. If none exists, create `docs/GLOSSARY.md`. If the existing file is a list or has other columns, ask before converting it, and keep every term.
- **ADR register:** the first of `docs/adr`, `docs/decisions`, `adr`, `doc/adr` that exists. Read each record's frontmatter (`status`, `supersedes`, `supersedes_in_part`, `terms`). A record without frontmatter takes its number from the filename and its status from its `## Status` section.

## Format

A new file starts like this:

```markdown
# Glossary

This file is the project's current vocabulary: each term has one definition and the source it comes from. The Source column is a citation, not a history. Rows that no longer apply are removed, not marked.

| Term | Definition | Source |
|---|---|---|
| Variant | A resized copy of an uploaded image at one preset's size. | [ADR-0002](adr/0002-resize-on-upload.md) |
| Preset | A named combination of width, height and output format. | Convention |
```

- **Term:** singular, in the casing the project uses in prose.
- **Definition:** one declarative sentence on what the term means in this project. An ADR-sourced row uses the definition from the record's `terms` as written.
- **Source:** one or more of the following, separated by `; `, ADRs first. A `|` in any cell is written `\|`.
  - `[ADR-0007](adr/0007-slug.md)`: an accepted record that defines or adopts the term, linked relative to the glossary file.
  - `Predates ADRs`: in use before the register began; no ADR defines it.
  - `Standard: <name or link>`: used as an external standard defines it, e.g. `Standard: RFC 9110`.
  - `Convention`: agreed by the team outside any ADR. The default for a term the user defines.

**Sort order**, applied on every write: rows citing an ADR first, by the lowest ADR number they cite; then the other rows grouped as `Predates ADRs`, `Standard`, `Convention` (a row citing several types goes in the first group it cites). Within one ADR number or group, alphabetical by term, ignoring case. If a write moves rows that were out of order, say so in the report.

## Changes from ADRs

An accepted ADR changes a row, whatever its source, in two ways:

- it **redefines** the term (different meaning): its definition and source replace the old ones. If the replaced source was an accepted ADR it doesn't supersede, report that two accepted records disagree.
- it **adopts** the term (same meaning): it is added as a source, taking the place of any record it supersedes.

A row citing an ADR changes only that way, or when that ADR is fully superseded or deprecated: if it was the only source, the row is a removal candidate; otherwise only that ADR leaves the Source cell. Decline other changes to an ADR-sourced definition; changing it takes a new ADR (adr-md). Fixing a link or the layout is allowed. Other rows can be edited at any time.

## Questions and pre-approval

- State your reading of the request and start; don't open with questions.
- Ask in plain text, or with the harness's question tool if it has one.
- Never remove a row without a yes. List each removal candidate with its reason.
- If the request already says to go ahead without asking, that is the yes for every question here, removals included: take the default each step names and state it in the report.

## Duplicates

Before writing a term, compare it with every row. Duplicates: the same term ignoring case, plural, hyphens and spaces. Near-duplicates: an abbreviation and its expansion, or a term whose definition describes the same thing. Show both rows and offer:

- **merge** into one row under the name the repo uses most, sources combined, keeping the ADR-sourced definition if there is one, else the more specific one. Default when both describe the same thing.
- **rename both** so each name says what differs. Default when they describe different things.
- **skip**.

Rows from two accepted ADRs that disagree can't be settled here: report them and suggest superseding one record with adr-md.

## Workflow

Take the intent (`add`, `backfill`, `reconcile`) from the invocation or the request. Read the glossary in full and list the records with their status. If the glossary is missing or empty and accepted ADRs exist, offer `backfill` first; with pre-approval, or for a handoff, do the requested work and suggest `backfill` in the report.

### add

1. Take each term's definition and source from the request. When a definition is missing, draft one from how the repo uses the term and ask for approval (default: the draft). When the source is unclear, use `Convention` and say so.
2. Check for duplicates, then write and report.

Rewording or renaming a row without an ADR source works the same way. "What do we call X?" is answered from the glossary; if no row fits, propose a term and offer to add it.

### Handoff from adr-md

An accepted ADR's terms arrive either as an invocation from adr-md with intent `add` (the ADR id, its file path, its `terms`, and for each record it supersedes: the old id, full or partial, and that record's `terms`), or as a request or message saying an ADR was accepted. In the second case, read the same data from the record and the records it supersedes.

Then, asking only about removals:

1. If the record's status isn't Accepted, add nothing and say why.
2. If `terms` is empty, there is nothing to add. If the field is missing, propose terms from the text as `backfill` does.
3. For each term: if no row matches, add one sourced from this ADR; if a row matches, this ADR redefines or adopts it (Changes from ADRs); handle a near-duplicate under another name as in Duplicates.
4. For each fully superseded record, rows still citing it follow Changes from ADRs. Rows of a partially superseded record stay unless step 3 changed them.
5. Write and report.

### backfill

1. Take the Accepted records in number order; skip all other statuses.
2. A record's candidates are its `terms`. Only when it has no `terms` field, read its text and propose the terms it introduces or gives a project-specific meaning. An empty `terms: []` means none.
3. Drop candidates already sourced from this record. The user accepts, edits or skips each of the rest (default: accept).
4. Apply them with handoff steps 3 and 4, and write before the next record, so an interrupted run keeps its progress.

### reconcile

Check the whole file, show all findings at once, then apply the approved changes in one write:

1. Duplicates and near-duplicates.
2. Removal candidates: those Changes from ADRs defines, and rows without an ADR source whose term appears nowhere in the repo outside the glossary (ignoring case, plurals included). An ADR-sourced term that appears nowhere is only reported; its record may need deprecating with adr-md.
3. Broken ADR links: fix the link if the register has that number under another filename; otherwise report it.
4. Format: a missing preamble, empty Source cells, multi-sentence definitions in rows without an ADR source.
5. Sort.

## Report

End every run with: the glossary path; rows added, changed and removed; removal candidates still open; each choice taken under pre-approval; anything left for adr-md or a later `backfill`.
