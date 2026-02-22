---
name: adr-md-behavior-locked-edit
description: "A content edit to an Accepted ADR is refused and supersede is offered; the record stays unchanged. Run with --scaffold and --allow-tools Write Edit Bash."
tags: [adr-md, behavior]
plugins: ["../.."]
max_turns: 25
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

In docs/adr/0001-use-relational-database-for-orders.md, change the Decision section so it says we store orders in a document database instead of a relational database. We switched last month. Just edit the file, no need to ask me.
