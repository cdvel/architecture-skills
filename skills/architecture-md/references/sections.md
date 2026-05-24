# Document sections

## Layout

Frontmatter, then `# <Project> architecture` (the name from the main manifest or the repo folder), one line `As of commit <commit_short> (<generated>), level <level>.`, a contents list linking every section, then the sections.

## Frontmatter

Keep the keys in this order. `generator` always starts with `architecture-md`; other tools check it.

```yaml
---
title: <Project> architecture
generator: architecture-md 0.1.0
generated: <YYYY-MM-DD>
level: comprehensive          # comprehensive | exhaustive
repository: <remote URL without credentials, or none>
commit: <full SHA of HEAD, or none>
commit_short: <short SHA, or none>
release_version: <version, or none>
previous_commit: <SHA>        # updates only
previous_date: <YYYY-MM-DD>   # updates only
previous_version: <version>   # updates only
---
```

## Section contents

Fixed order, each a level-2 heading with exactly this name. Headings at every level are noun phrases without numbers.

| Section | Must contain |
|---|---|
| Summary | The problem the system solves and for whom; core capabilities; a key decisions table (decision, reason, impact), linking the ADR when the register has one for that decision (read ADR titles and status only); the stack at a glance; an environments table (name, how it is reached or deployed, source file) |
| Diagrams | Four ASCII diagrams: C4 level 1 system context (users, the system, external systems), level 2 containers (deployable units, stores, queues, with protocols on the arrows), level 3 components inside each main container, level 4 deployment (runtime, network, cloud resources). A level without evidence shows what exists and carries a gap |
| Components | Per unit, a subsection with: path, technology, one-sentence purpose; how it is structured; its public surface (endpoints, commands, topics; the main ones at comprehensive level); a table of every non-test, non-generated source file with a one-sentence role; reasons found in code comments (workarounds, "because", "must", library quirks, issue or ADR references) as quoted callouts with `path:line`; what it depends on; how it is tested |
| Infrastructure and deployment | Orchestration, manifests or charts, IaC resources, network layout (ports, ingress, internal traffic), provisioning, with real excerpts from the files |
| Cloud services | Per provider: services used, how the code uses them, how it authenticates, where it is configured |
| External integrations | Per third-party service: purpose, auth method, endpoints called, timeouts, error and retry handling |
| CI/CD | Pipelines and their triggers, build, test, packaging, deploy strategy, promotion between environments, rollback if defined, secrets the pipeline uses |
| Data flows | One subsection per flow kind the repo has (request, background job, ingestion, event), each written from its trace ([explore.md](explore.md)): an ASCII sequence, then every hop with what the trace recorded, including real headers for at least one call |
| Security | Authentication flows, authorization model, secrets handling, encryption in transit and at rest, trust boundaries and where they are crossed, then the threat table |
| Configuration | Every env var (name, purpose, required or optional, default, where it is read), config files, feature flags, per-environment differences |
| Observability | Metrics, logs (format, destination), error tracking, traces, dashboards and alerts defined in the repo |
| Data stores | Per store: engine and version if stated, schema (tables or collections with key fields), migrations and how they ship, indexes, caching, backups and retention if stated |
| Performance | Caching, scaling approach, concurrency limits, stated targets, load tests; only what the repo shows |
| Cross-repo dependencies | Shared libraries, services this one calls or is called by, monorepo layout |
| Technology stack | Tables for languages and runtimes, frameworks, infrastructure tools, data stores, observability and security tools, each with the version where pinned and the file that pins it (main dependencies at comprehensive level) |
| Open work | TODO, FIXME and HACK markers grouped by area with counts (at most 30 listed at comprehensive level, chosen by risk), planned work referenced in code, deprecated parts, visible technical debt |
| Quick reference | Key paths (entry points, config, deploy files), URLs found in config, common commands from Makefiles and package scripts, troubleshooting notes found in docs or comments |
| Changes since previous version | Updates only; see [regenerate.md](regenerate.md) |
| Related documents | Links to the glossary (`GLOSSARY.md` or `TERMINOLOGY.md`, at the root or in `docs/`) and the ADR index (register in `docs/adr`, `docs/decisions`, `adr` or `doc/adr`), only if they exist. Links only |

## Priority tiers

When evidence is thin, write in this order. Never drop the first tier; give it a gap instead.

1. Always: Summary, Diagrams (at least levels 1 and 2), Components, Infrastructure and deployment, Technology stack.
2. Anything that runs as a service: Security, Observability, CI/CD, Data stores.
3. When the repo shows them: detailed Data flows, Performance, Cross-repo dependencies.

Other sections are written when they apply and dropped when they don't.

## Writing order

Components first. Diagrams, Data flows, Performance and Cross-repo dependencies build on it. The rest depend only on the merged findings. Summary last.

## Threat table

| Threat | Where it applies | Mitigation | Status | Gap |
|---|---|---|---|---|

- Status is `mitigated`, `partial` or `not mitigated`. Mitigation cites `path:line`. Gap names the file or TODO behind a partial or missing control.
- Baseline rows, all kept: credential theft; traffic interception; token or request replay; confused deputy and privilege escalation; injection; sensitive data in logs; resource exhaustion; abuse without rate limits; dependency supply chain. A row that doesn't apply says so in "Where it applies", with the reason.
- With `--stride`: one table per trust boundary, one row per STRIDE category (spoofing, tampering, repudiation, information disclosure, denial of service, elevation of privilege), same columns.

## Diagrams

ASCII only, so they read the same in a terminal, a diff and a browser. Boxes name the real unit or store and its path; arrows carry the protocol; lines stay within 100 columns. Level 2 style:

```
+---------+  HTTPS  +---------------+  SQL  +------------+
| Shopper |-------->| storefront    |------>| PostgreSQL |
+---------+         | web/server.ts |       +------------+
                    +---------------+
```

## Writing rules

- Name real files and symbols, never "the main file" or "the API".
- Quote code from the repo with its `path:start-end`; never write pseudocode.
- Say why, not only what: reasons from comments, ADRs and structure.
- Tie facts to the recorded commit or version ("as of `<commit_short>`"), never "currently".
- Use tables for structured data: config, endpoints, schemas, stacks.
- Link cross-references to the other section by name, for example `[Configuration](#configuration)`. No section numbers, no `§`.
- Define acronyms on first use.
- Give a worked example for each major feature, built from the code (a real request and the response the handler returns).
- No emoji. Follow the writing style of the instruction files the harness has already loaded.
