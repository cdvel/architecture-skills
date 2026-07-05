---
name: brief-behavior-full-brief
description: "Generated docs/ARCHITECTURE.md at HEAD: brief opens with a verdict and has an ASCII diagram, a table, section citations and a labeled opinion section. Needs --scaffold and --allow-tools 'Bash(git:*)' (read-only git for the staleness check)."
tags: [brief, behavior]
plugins: ["../.."]
max_turns: 15
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Bash]
---

I'm new on this team. Give me an architect's brief of this repo.
