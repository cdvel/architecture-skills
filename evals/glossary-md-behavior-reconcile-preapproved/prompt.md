---
name: glossary-md-behavior-reconcile-preapproved
description: "A glossary with a duplicate term (Cart and Carts) and an unsorted table; the prompt pre-approves changes. Expects one merged row, the sort order applied, and the merge choice reported. Run with --scaffold and --allow-tools Write Edit Bash."
tags: [glossary-md, behavior]
plugins: ["../.."]
max_turns: 25
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

Reconcile our glossary and fix what you find. Go ahead without asking; I'll review the diff.
