---
name: glossary-md-behavior-adr-handoff
description: "ADR-0003 (accepted, supersedes ADR-0002) has terms in its frontmatter; the prompt says it was just accepted. Expects rows sourced with a link to ADR-0003, the redefined term moved off ADR-0002, sort order kept, and no ADR edited. Run with --scaffold and --allow-tools Write Edit Bash."
tags: [glossary-md, behavior]
plugins: ["../.."]
max_turns: 25
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

ADR-0003 was just accepted. Add its terms to the glossary.
