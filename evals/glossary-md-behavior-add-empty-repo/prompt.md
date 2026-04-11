---
name: glossary-md-behavior-add-empty-repo
description: "Adds two user-defined terms in a repo with no glossary; expects docs/GLOSSARY.md with the preamble and the Term | Definition | Source table, rows sorted. Run with --scaffold and --allow-tools Write Edit Bash."
tags: [glossary-md, behavior]
plugins: ["../.."]
max_turns: 25
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

Add two terms to the project glossary. Preset: a named combination of width, height and output format. Variant: a resized copy of an uploaded image at one preset's size. Both are our own conventions.
