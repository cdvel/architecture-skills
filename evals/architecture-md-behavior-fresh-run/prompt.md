---
name: architecture-md-behavior-fresh-run
description: Fresh run on a small committed service with no existing doc; the request pre-approves every confirmation. Writes files, so run with --scaffold and --allow-tools Write Edit Bash.
tags: [architecture-md, behavior]
plugins: ["../.."]
max_turns: 40
timeout_seconds: 1200
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---
Write an ARCHITECTURE.md for this repo so new engineers can find their way around. Use the defaults and go ahead without asking me anything; I won't be around to answer.
