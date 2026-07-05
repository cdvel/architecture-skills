---
name: brief-behavior-not-generated
description: "Hand-written root ARCHITECTURE.md without a generator field: brief says it was not written by architecture-md, suggests it and asks before briefing. Needs --scaffold and --allow-tools 'Bash(git:*)' (read-only git for the staleness check)."
tags: [brief, behavior]
plugins: ["../.."]
max_turns: 15
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Bash]
---

What's the big picture of this codebase? I start reviewing it tomorrow.
