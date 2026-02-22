# Status workflows

Each workflow names a record by number or id (`3`, `0003`, `ADR-0003`). If more than one record could match, list them and ask. Every status change also regenerates the record's header line and its index row ([template.md](template.md)).

## propose

Draft to Proposed. Run the checks before save (SKILL.md) first; a failed check stops it.

## accept

Proposed to Accepted. A Draft goes through `propose` first: say so, and run both after a yes.

1. Set `status: Accepted`. Fill `deciders` if the user names them.
2. For each id in `supersedes`, set that record to `Superseded` and add this record's id to its `superseded_by`. For each id in `supersedes_in_part`, keep its status and add this record's id to its `superseded_in_part_by`. Change nothing else in the old record. Old records without frontmatter follow SKILL.md (Records in other formats).
3. Regenerate the header lines and index rows of every record changed.
4. Hand the terms to the glossary:
   - Data: this record's id, its file path and its `terms`; for each record it supersedes, the old id, whether the replacement is full or partial, and the old record's `terms` (none for records without frontmatter).
   - If the `glossary-md` skill is available, invoke it with intent `add` and that data.
   - Otherwise list the terms in the report and say they are kept in the record's `terms` field, where `glossary-md` can pick them up later.
   - Skip the handoff only when this record and every record it supersedes have no terms, and say so.

## deprecate

Accepted to Deprecated, when the decision no longer applies and nothing replaces it. If something replaces it, use `supersede` instead.

- Needs a one-line reason, stored in `status_note`; ask if the request gives none.
- List the record's terms in the report and note that glossary rows citing it may need review with `glossary-md`.

## supersede

1. Identify the old record. It must be Accepted or Deprecated; a Draft or Proposed record is edited instead.
2. Settle whether the replacement is full or partial, unless the request says. For a partial one, name the part replaced.
3. Run `new` ([new.md](new.md)) with `supersedes` or `supersedes_in_part` set to the old id, using the old record as context.

## amend

Typos, broken links and formatting in a locked record.

- Show each change as before and after, and apply after a yes.
- Add today's date to `revised` once (records with frontmatter only).
- A change that alters meaning (a different word, number, option, decision or consequence) is refused as SKILL.md (Lifecycle) says. Apply the cosmetic ones.

## index

Rebuild the index from every record in the register ([template.md](template.md)). Write it and report the rows added, changed or removed.
