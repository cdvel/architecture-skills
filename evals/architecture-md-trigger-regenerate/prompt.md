---
name: architecture-md-trigger-regenerate
description: Request to regenerate a stale ARCHITECTURE.md should load architecture-md.
tags: [architecture-md, trigger]
plugins: ["../.."]
max_turns: 4
allowed_tools: [Read, Glob, Grep, Skill]
---
Our ARCHITECTURE.md is out of date after the last few weeks of changes. Please regenerate it.
