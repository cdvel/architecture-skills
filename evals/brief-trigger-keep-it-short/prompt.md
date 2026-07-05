---
name: brief-trigger-keep-it-short
description: "Asks for a short summary of how the codebase is put together; the brief skill should fire."
tags: [brief, trigger]
plugins: ["../.."]
max_turns: 4
allowed_tools: [Read, Glob, Grep, Skill]
---

Summarize how this codebase is put together. Keep it short.
