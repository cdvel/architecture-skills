# Template

## Filename

`NNNN-short-slug.md` in the register: the number, then a lowercase hyphenated slug of the title in a few words. If the register already uses another pattern, follow it. The filename never changes; status lives only in the frontmatter.

## Record

````markdown
---
id: ADR-0007
title: Sign download URLs instead of proxying files
status: Draft
status_note: ""
date: 2026-02-15
revised: []
authors: []
deciders: []
supersedes: []
supersedes_in_part: []
superseded_by: []
superseded_in_part_by: []
related: []
terms: []
---

# ADR-0007: Sign download URLs instead of proxying files

**Status:** Draft · **Date:** 2026-02-15

## Context

## Options considered

### Signed URLs from object storage (chosen)

### Proxy every download through the API

## Decision

We will ...

## Consequences

### Positive

### Negative

### Known gaps

## References
````

Drop "Known gaps" unless delivery is staged.

## Fields

| Field | Rule |
|---|---|
| `id` | `ADR-` plus the filename number |
| `title` | Plain title, no number |
| `status` | `Draft`, `Proposed`, `Accepted`, `Deprecated` or `Superseded` |
| `status_note` | Optional qualifier, such as a deprecation reason; `""` when unused |
| `date` | Creation date; never changes |
| `revised` | Dates added by `amend` |
| `authors` | Who wrote the record; defaults to `git config user.name` |
| `deciders` | Who made the decision |
| `supersedes`, `supersedes_in_part` | Ids this record replaces, fully or in part; set from the first draft |
| `superseded_by`, `superseded_in_part_by` | Ids that replaced this record; set by `accept` |
| `related` | Entries like `- {id: ADR-0003, reason: one line}` |
| `terms` | Entries like `- {term: Signed URL, definition: one sentence}` |

Link fields are always lists, empty when unused. Ids look like `ADR-0004`.

## Header line

The line under the title is generated from the frontmatter and regenerated whenever the status or a link field changes:

`**Status:** <status> (<status_note>) · **Date:** <date>`

Leave out the parentheses when `status_note` is empty. Append, when set, `· **Supersedes:**`, `· **Supersedes in part:**`, `· **Superseded by:**` or `· **Superseded in part by:**` with links to those records.

## Index

`README.md` in the register by default. An index already in the register (such as `index.md`) is used instead; if its layout differs, add rows in its layout and ask before converting it.

````markdown
# Architecture decision records

Why the system has its current shape, one decision per record.

Status: Draft (being written) · Proposed (under review) · Accepted (in force, locked) · Deprecated (no longer applies) · Superseded (replaced by a newer record)

| ADR | Title | Status | Date |
|---|---|---|---|
| [ADR-0001](0001-keep-sessions-in-a-shared-cache.md) | Keep sessions in a shared cache | Accepted | 2026-02-04 |
| [ADR-0002](0002-sign-download-urls.md) | Sign download URLs instead of proxying files | Superseded by [ADR-0005](0005-serve-downloads-from-cdn.md) | 2026-02-07 |
````

- One row per record, in number order, values from the frontmatter (or as read from records in other formats).
- A partly replaced record shows its status plus `, in part superseded by` and the link.
- No footer.
