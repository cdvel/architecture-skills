---
name: glossary-md-behavior-replaced-term
description: "Renames the glossary term Task to Job while the code still says task: expects a Job row with the old meaning, a Task row reading \"Don't use; say Job.\", rows sorted, and the code untouched. Run with --scaffold and --allow-tools Write Edit Bash."
tags: [glossary-md, behavior]
plugins: ["../.."]
max_turns: 25
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

We've agreed to call tasks "jobs" from now on. Update the glossary to match; go ahead without asking.
