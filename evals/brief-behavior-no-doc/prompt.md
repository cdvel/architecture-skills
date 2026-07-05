---
name: brief-behavior-no-doc
description: "Repo without ARCHITECTURE.md: brief says so, suggests architecture-md, does not read the code and writes nothing. Needs --scaffold and --allow-tools 'Bash(git:*)' (read-only git for the staleness check)."
tags: [brief, behavior]
plugins: ["../.."]
max_turns: 15
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Bash]
---

Give me an architect's brief of this repo.
