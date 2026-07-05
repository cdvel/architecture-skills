---
name: brief-skip-specific-question
description: "A specific question about one piece of code; brief should not fire."
tags: [brief, skip]
plugins: ["../.."]
max_turns: 4
allowed_tools: [Read, Glob, Grep, Skill]
---

How does the auth middleware in this repo check permissions? Walk me through the code path.
