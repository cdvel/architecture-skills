# Regenerating an existing doc

## Existing doc

Read the frontmatter and show its `release_version`, `generated` date and `commit`, the doc's age in days, the number of commits since that commit, and the files changed (count, plus the list when short).

Every section counts as changed, and the guardrail below does not apply, when any of these holds (say which):

- No frontmatter, or a `generator` that doesn't start with `architecture-md`. Treat the doc as hand-written: warn that rewriting replaces its text, and suggest wrapping what must stay in keep blocks or writing to another path with `--output`.
- No recorded commit, a commit that is not in the history, or no git.

The level defaults to the existing doc's `level`. Then offer:

- **Update changed sections** (default)
- **Rewrite everything**
- **Cancel**

## Scope of an update

The diff from the recorded commit to HEAD says where to look; ignore the doc's own file in it. Map each changed path to sections:

| Changed path | Sections |
|---|---|
| Any file the doc cites | Every section that cites it, if the diff touches the lines or facts it cites (moved line numbers count) |
| Package manifests, lockfiles | Technology stack; Cloud services or External integrations when an SDK or client changed |
| Container, compose, Kubernetes, Helm, IaC files | Infrastructure and deployment; Diagrams (level 4) |
| CI workflow files | CI/CD |
| Example env files, config modules | Configuration |
| Migrations, models, schema files | Data stores |
| Auth, middleware, secrets handling | Security |
| Logging, metrics, tracing config | Observability |
| A source file added, removed or renamed | Components (its unit's file table) |
| A unit added or removed | Components, Diagrams, Summary |
| New or removed TODO, FIXME, HACK markers | Open work |

Summary changes only when a unit, a capability, a key decision or the stack changed. Sections not mapped are stable.

## Guardrail

If more than a quarter of the doc's sections come out as changed (not counting Changes since previous version), stop and offer:

- **Continue** the update (default)
- **Rewrite everything**
- **Narrow:** show the file-to-section mapping and let the user mark sections as stable

## Stable sections

Copy them byte for byte. Never reword one "for clarity". Check each: cited paths exist, cited lines still hold what is quoted, commands in Quick reference still exist in the Makefile or package scripts, env vars named still exist in the code. A check only flags; a failed check marks the whole section as changed.

## Changed sections

Rewrite them from the current code, exploring only the units and areas the changed paths touch. Old wording may stay only after it has been checked against the code. Write from the code, not from commit messages: commit messages appear only in Changes since previous version.

Then:

- Frontmatter: new `generated`, `commit`, `commit_short`, `release_version`; `previous_commit`, `previous_date` and `previous_version` take the old doc's `commit`, `generated` and `release_version`.
- Changes since previous version: from tags, commit messages and the repo changelog between the two commits, grouped by tag, each change linked to the sections it touched. Replace any earlier version of this section.
- Update the contents links if sections were added or dropped.

## Preserved notes

Blocks between `<!-- keep -->` and `<!-- /keep -->`, and a section headed "Team notes", are copied byte for byte, in place, in every mode including Rewrite everything:

- In place means in the same section, after the same heading or paragraph they followed. If that anchor is gone, put the block at the end of its section and say so in the report.
- Never edit inside a keep block, even to fix a stale path; flag it in the report instead.
