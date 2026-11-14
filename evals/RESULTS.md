# Eval results

Last run: 2026-11-14, Claude Code 2.1.325, `claude plugin eval`, one run per case per model, at commit `d44e859` (the skills have not changed since). Each behavior case builds a small git repo with its `setup.sh`, sends the request in its `prompt.md`, and scores the files written and the reply with the checks in its `graders/`.

```
claude plugin eval . --runs 1 --model <model> --ablation none --scaffold --trust-plugin --allow-tools Write Edit Bash
```

## Behavior

| Case | Checks | Opus 5.5 | Sonnet 5.5 | Haiku 5.5 |
|---|---|---|---|---|
| `architecture-md-behavior-fresh-run` | New doc on a small service: required sections, frontmatter with generator and commit, `path:line` citations, no numbered headings | pass | pass | pass |
| `architecture-md-behavior-missing-deploy` | Repo with no deployment files: the infrastructure section states a gap instead of inventing a deployment | pass | pass | pass |
| `architecture-md-behavior-regenerate-keep` | Update after a code change: unchanged sections and the keep block byte for byte, commit advanced, previous commit recorded, changes section | pass | pass | pass |
| `adr-md-behavior-new-complete` | New record with pre-approval: frontmatter, Draft or Proposed, authors from git, index created with a row, no glossary written | pass (1) | pass (1) | fail (2) |
| `adr-md-behavior-single-option` | Only one option given: pushback and a request for alternatives, no record written | pass | pass | fail |
| `adr-md-behavior-locked-edit` | Content edit to an Accepted record: refused, supersede offered, record unchanged | pass | pass | fail |
| `adr-md-behavior-supersede` | Superseding an Accepted record: new Draft or Proposed record lists it in `supersedes`; the old record is unchanged until accept | pass | pass | pass |
| `adr-md-behavior-accept-supersedes` | Accept: new record Accepted, old record Superseded with a back-link and its body intact, index updated, terms handed to the glossary | pass | pass | fail |
| `glossary-md-behavior-add-empty-repo` | Two terms in a repo without a glossary: `docs/GLOSSARY.md` with preamble, table header and sorted rows | pass | pass | pass |
| `glossary-md-behavior-existing-terminology` | Repo with `docs/TERMINOLOGY.md`: terms go there, no `GLOSSARY.md` created | pass | pass | pass |
| `glossary-md-behavior-adr-handoff` | Terms of a just-accepted ADR: rows linked to it, a redefined term's old source removed, sort order, ADRs not edited | pass | pass | pass |
| `glossary-md-behavior-reconcile-preapproved` | Duplicate terms and an unsorted table: one merged row, sort order applied, changes reported | pass | pass | pass |
| `brief-behavior-full-brief` | Verdict first, ASCII diagram, parts table, section citations, labeled opinion section, no source reads | pass | fail (3) | pass |
| `brief-behavior-no-doc` | No ARCHITECTURE.md: says so, suggests `architecture-md`, reads no code, writes nothing | pass | pass | pass |
| `brief-behavior-not-generated` | Hand-written ARCHITECTURE.md: flags it as not generated and suggests `architecture-md` | pass | pass | pass |
| `brief-behavior-stale-doc` | Doc two commits behind HEAD: reports 2 commits and suggests regenerating with `architecture-md` | pass | pass | pass |

1. Failed in the full run: the eval sandbox blocks the `git` binary, and the model left `authors` empty and said why, as the skill specifies. The check was changed to accept that (`1edee91`), and the case was rerun on both models: pass.
2. The record was missing part of the required content: a section, an option with its reason, or the cited source file.
3. The parts table and the list of files to start reading had no section citation.

## Triggering

27 cases check that each skill loads for its own requests and stays out of others. All 27 passed on all three models.

| Skill | Fires on | Stays out of |
|---|---|---|
| `architecture-md` | Onboarding doc for the whole repo; mapping an inherited codebase with C4 diagrams; regenerating a stale ARCHITECTURE.md | Recording one decision; a quick overview in chat; a README typo |
| `adr-md` | Writing up why a queue replaced cron, without saying "ADR"; starting a decision log; accepting an ADR by number; replacing an earlier decision | Editing ARCHITECTURE.md; adding a dependency; adding a glossary term; an RFC open for comments |
| `glossary-md` | Starting a glossary; defining two domain terms for the team; cleaning up duplicates; writing down terminology without saying "glossary" | Writing ARCHITECTURE.md; a plain question about a word; recording a decision |
| `brief` | An architect's brief; the big picture before a review; a short summary of how the codebase fits together | Recording a decision; a question about one piece of code; writing ARCHITECTURE.md |

## Other measurements

- **Citations:** in the ARCHITECTURE.md written by the fresh-run case (2026-11-13, Opus 5.5), all 82 `path:line` citations pointed at existing lines of the test repo; six sampled citations matched the code they cite.
- **Context cost** (`claude plugin details`): the four skill descriptions add about 1.2k tokens to every session; an invoked skill loads 1.7k to 2.6k more, plus reference files only for the step in use.
