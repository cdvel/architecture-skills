---
name: architecture-md-behavior-regenerate-keep
description: Existing docs/ARCHITECTURE.md recorded at the first commit, with a keep block in the worker section; a later commit changes the worker. Update mode must keep the block and stable sections byte for byte and record previous_commit. Run with --scaffold and --allow-tools Write Edit Bash.
tags: [architecture-md, behavior]
plugins: ["../.."]
max_turns: 40
timeout_seconds: 1200
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---
We changed the worker since docs/ARCHITECTURE.md was generated. Update the sections of the architecture doc that changed. Go ahead without asking; I'll review the diff afterwards.
