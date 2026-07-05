---
name: brief-trigger-big-picture
description: "Asks for the big picture before a review; the brief skill should fire."
tags: [brief, trigger]
plugins: ["../.."]
max_turns: 4
allowed_tools: [Read, Glob, Grep, Skill]
---

What's the big picture here? I'm about to review changes in this codebase and want the overall shape first.
