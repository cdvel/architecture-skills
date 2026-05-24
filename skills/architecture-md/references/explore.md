# Exploring the codebase

Breadth before depth: nothing is read in detail until every unit is on the map. Effort follows each unit's size and how central it is.

## Counting

- Source files are the tracked files (from git; without git, walk the tree). Exclude `.git`, vendored and third-party folders, generated code, build output, lockfiles, minified files, binaries and large data files.
- Count lines across all remaining source files, whatever the language, and keep the per-folder counts for the map.

## Time estimate

Minutes = base × the larger of the file factor and the line factor. Base: comprehensive 20, exhaustive 30.

| Source files | Lines | Factor |
|---|---|---|
| Up to 50 | Up to 5k | 0.5 |
| 51 to 200 | 5k to 30k | 1 |
| 201 to 600 | 30k to 100k | 2 |
| 601 to 1,500 | 100k to 300k | 3 |
| More | More | 4, and suggest `--sections` or documenting one unit at a time |

Show: source files, lines, level, the range (minutes to 1.5 × minutes) and the expected doc size (roughly 400 lines plus 150 per unit at comprehensive; about 1.5 to 2 times that at exhaustive). On an update, count only the units the changed paths touch. Then ask to continue. Report progress against the range using the rough split: exploring 15 to 20%, planning 5 to 10%, writing 60 to 70%, checks 10 to 15%.

## Map

One quick pass over the layout, the manifests and the entry points. List every unit (service, package, library, CLI, worker, frontend app, infrastructure module) with:

| Unit | Root path | Language | Source files | Lines | Entry points |
|---|---|---|---|---|---|

## Explorers

- **One explorer per unit** for its internals: file roles, entry points, public surface, reasons given in code comments, dependencies, tests.
- **Cross-cutting explorers:** infrastructure and CI; auth and security; configuration and secrets; data stores; observability. In a small repo, one explorer can take several areas.
- **Large units split again.** A unit above about 150 source files or 20k lines is divided into sub-units by its own folders or packages, each with its own explorer.
- **Scale.** The number of explorers follows the estimate's factor, at most about 8 running at a time; queue the rest. At factor 0.5, explore in the main thread without subagents.
- **Briefing.** Each explorer gets its unit or area, the files it owns, the matching discovery signals, the ground rules from SKILL.md and the findings format.
- **Without subagents,** run the same explorers one after another in the main thread, recording findings in the same format. Keep findings in the conversation; write no intermediate files.

## Discovery signals

Signals to look for, not commands; the harness's own search and read tools do the work.

| Area | Look at | Extract |
|---|---|---|
| Layout | Top-level folders, file-type mix | Languages, monorepo or single service, where source, tests, docs and tooling live |
| Dependencies | Every package manifest present, in any ecosystem | Frameworks, data stores, cloud SDKs, observability libraries, AI and LLM clients |
| Units and boundaries | Entry points (servers, workers, CLIs, `main` files), API definitions (routes, OpenAPI, protobuf), clients for other services | Units, their public surface, who calls whom |
| Infrastructure and CI | Container files, compose files, Kubernetes manifests and Helm charts, infrastructure as code (IaC), CI workflow files | How it is built, packaged, deployed and promoted |
| Configuration and secrets | Example env files, config modules and folders, references to secret stores | Env vars and whether each is required, credentials, feature flags, per-environment differences |
| Data | Migrations, ORM models, schema files, seed and init scripts | Stores, schemas, how schema changes ship, retention if stated |
| Observability | Metrics, logging, error tracking and tracing libraries and their config | What is measured, where logs and traces go, alerts and dashboards defined in the repo |

## Findings format

Every explorer returns exactly this, with no prose:

```
unit: <name or area> (<root path>)
files_read:
- <path>
facts:
- <statement> (<path:line>)
inferences:
- <statement>; rests on: <path:line or observation>
open_questions:
- <specific question the code can't answer>
links:
- <other unit or external system>: <how they connect> (<path:line>)
uncovered:
- <path>: <why it was not read>
```

## Merge

One step reconciles all findings:

- Remove duplicate facts, keeping the most specific citation.
- Settle contradictions by re-reading the code at the cited lines. If the code can't settle one, keep both readings as inferences.
- Check coverage against the map: every source file appears in some `files_read` or in `uncovered`. Assign uncovered files to a follow-up pass, or list them as uncovered in the report and as a gap in Components.

## Tracing

Data flows come from following real entry points, not from joining component descriptions. For each kind of entry point the repo has (HTTP request, background job, message or event, scheduled task, CLI command), pick one real entry point and follow it hop by hop through middleware, handlers, stores and external calls to the response. Record per hop: `path:line`, headers read or set, payload shape, how keys and IDs are built, what the hop adds, checks or strips, and what the caller sees on failure. These traces become the Data flows section.
