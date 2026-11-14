---
name: architecture-md
description: Writes a detailed ARCHITECTURE.md for a repository by reading the code itself (components with file tables, C4 diagrams in ASCII, infrastructure, CI/CD, traced data flows, security and threats, configuration, data stores), saved under docs/ by default, and updates only the changed sections when the doc already exists. Use when asked to document a codebase's architecture, write or regenerate ARCHITECTURE.md, map an inherited or legacy codebase, write onboarding or architecture-review docs, or write down what is deployed and how auth works, for example "document the architecture of this repo", "regenerate our ARCHITECTURE.md", "map this codebase with C4 diagrams". Not for a quick overview in chat (brief), recording one decision as an ADR (adr-md), glossary terms (glossary-md), README edits, a single diagram, API reference from docstrings, explaining C4 in general, or refactoring.
---

# architecture-md

One detailed `ARCHITECTURE.md` written from the code, for onboarding, reference, architecture or security review, and pre-production checks. An existing doc gets only its changed sections rewritten; hand-written notes stay.

## Ground rules

- **Read-only.** The only file written is the `ARCHITECTURE.md` (creating its folder if needed). Git is used read-only: HEAD, remote, tags, log, diff, file list. Never run builds, tests, installs, migrations, deploys or the code itself.
- **Static reading.** Missing evidence never stops the run; it becomes a marked gap ([quality.md](references/quality.md)).
- **Code over docs.** READMEs, wikis and comments are leads. Where they contradict the code, the doc follows the code and notes the conflict with both citations.
- **Observed or inferred.** Every fact cites `path:line` or `path:start-end`. Every inference starts with *Inferred:* and names what it rests on. Nothing unmarked is a guess.
- **Glossary for names, code for facts.** A glossary (`GLOSSARY.md` or `TERMINOLOGY.md`, at the root or in `docs/`) sets what things are called. Name concepts with its terms; where the code uses another name, give the mapping once (class `Task`, the glossary's *job*). Where the code contradicts a definition, the doc follows the code and notes the conflict with both citations. Never copy definitions into the doc or write to the glossary. No glossary is not a gap: names follow the code.

## Options

Taken from arguments or from plain words in the request ("exhaustive", "only security and data flows").

`architecture-md [path] [--level comprehensive|exhaustive] [--sections a,b,c] [--output file] [--verify] [--stride]`

| Option | Default | Effect |
|---|---|---|
| path | Root of the current git repo, else the current folder | What to document |
| `--level` | `comprehensive` | See *Levels* |
| `--sections` | All | New doc: only these sections are written; the doc lists the rest as skipped. Existing doc: only these are rewritten; the rest are copied as stable |
| `--output` | An existing `ARCHITECTURE.md` under the path (`docs/`, then the root), else `docs/ARCHITECTURE.md` | Where the doc goes |
| `--verify` | Off | Independent check of the finished doc before it is saved ([quality.md](references/quality.md)) |
| `--stride` | Off | STRIDE threat table per trust boundary instead of the baseline list ([sections.md](references/sections.md)) |

## Levels

Both levels are detailed. They differ by content, not line counts.

- **comprehensive** (default): every applicable section, all four C4 levels, a file table per component, data flows at wire level, the threat table.
- **exhaustive**: all of that, plus every endpoint, command and topic in Components, every dependency with its version in Technology stack, every TODO, FIXME and HACK marker in Open work, longer code excerpts, and none of the size caps in [quality.md](references/quality.md).

## Confirmations

The run asks before acting on an existing doc (step 2), after the time estimate (step 3), and when the update guardrail trips ([regenerate.md](references/regenerate.md)). Ask in plain text, or with the harness's question tool if it has one, and name the default.

If the request already says to go ahead without asking, that counts as the yes for every confirmation: take the default, say which choice was taken, and continue.

## Run

Show the phases (in the harness's task list if it has one) and one line per unit explored and per section written.

1. **Inputs.** Resolve path, level, sections and output. Record HEAD (full and short SHA), the remote URL with any embedded credentials removed (else `none`), and the release version from release manifests or package files (else `none`). If source files have uncommitted changes, say so: the doc reads the working tree but records HEAD. Read the glossary if there is one; if there are several, read them all. Announce path, level, sections, output and the glossary used, if any.
2. **Existing doc.** If the output file exists, follow [regenerate.md](references/regenerate.md) up to its choice. On cancel, stop.
3. **Estimate.** Count and estimate as in [explore.md](references/explore.md); show the numbers and ask to continue.
4. **Explore.** Map, divide, merge and trace as in [explore.md](references/explore.md).
5. **Plan.** Build this repo's outline from [sections.md](references/sections.md): drop sections that don't apply (say which and why), mark thin ones as gaps, announce the outline.
6. **Write.** Write sections in the order sections.md sets, from the merged findings, marking gaps as [quality.md](references/quality.md) shows. With subagents, sections that don't depend on each other can be written in parallel, each subagent given the findings, the glossary terms, sections.md and quality.md; otherwise write them one after another.
7. **Check and save.** Run the checks in [quality.md](references/quality.md) and fix what they find. Then write the file once and report.

## Report

End with, in chat: output path, level, commit and mode (new, update or rewrite); sections written, updated, copied unchanged and skipped; the number of gaps with the most important open questions; uncovered files; the glossary used, or that none was found and `glossary-md` can start one; terms that several glossaries define differently, suggesting `glossary-md` to merge them; conflicts between docs and code, the glossary included; the `--verify` result if it ran; any size warning from quality.md.

## References

| File | Read it |
|---|---|
| [regenerate.md](references/regenerate.md) | At step 2, only when the doc exists |
| [explore.md](references/explore.md) | Before step 3 |
| [sections.md](references/sections.md) | Before step 5 |
| [quality.md](references/quality.md) | Before step 6 |
