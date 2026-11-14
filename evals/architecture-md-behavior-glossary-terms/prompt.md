---
name: architecture-md-behavior-glossary-terms
description: Fresh run on the small service with a committed docs/GLOSSARY.md whose term "Rendition" the code never uses (it says outputs and thumbnails) and whose definition says WebP where the worker saves PNG; the doc must use the glossary term with a mapping, record the conflict, and leave the glossary alone. Writes files, so run with --scaffold and --allow-tools Write Edit Bash.
tags: [architecture-md, behavior]
plugins: ["../.."]
max_turns: 40
timeout_seconds: 1200
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---
Write an ARCHITECTURE.md for this repo so new engineers can find their way around. Use the defaults and go ahead without asking me anything; I won't be around to answer.
