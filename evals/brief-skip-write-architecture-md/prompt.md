---
name: brief-skip-write-architecture-md
description: "Asks to write ARCHITECTURE.md, which is architecture-md's job; brief should not fire."
tags: [brief, skip]
plugins: ["../.."]
max_turns: 4
allowed_tools: [Read, Glob, Grep, Skill]
---

Write an ARCHITECTURE.md for this repo so new people can find their way around.
