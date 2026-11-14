---
name: glossary-md-behavior-draft-from-repo
description: "Draft mode on the small service with no glossary and no ADRs: expects docs/GLOSSARY.md with project terms only (Job among them), one row for the resized files that README and code name differently, and no other docs written. Run with --scaffold and --allow-tools Write Edit Bash."
tags: [glossary-md, behavior]
plugins: ["../.."]
max_turns: 30
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

Draft a glossary for this repo from the terms the code and docs already use. Add what you find; go ahead without asking, I won't be around to answer.
