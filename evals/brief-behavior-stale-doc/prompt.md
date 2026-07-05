---
name: brief-behavior-stale-doc
description: "Generated docs/ARCHITECTURE.md two commits behind HEAD: brief reports 2 commits, suggests regenerating and still gives the brief. Needs --scaffold and --allow-tools 'Bash(git:*)' (read-only git for the staleness check)."
tags: [brief, behavior]
plugins: ["../.."]
max_turns: 15
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Bash]
---

Give me an architect's brief of this repo.
