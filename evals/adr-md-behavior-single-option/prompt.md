---
name: adr-md-behavior-single-option
description: "A new decision with only one option gets pushback and a request for alternatives; no record is written. Run with --scaffold and --allow-tools Write Edit Bash."
tags: [adr-md, behavior]
plugins: ["../.."]
max_turns: 25
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

Write an ADR for moving cart sessions from in-process memory (src/cart/session.js) to a shared cache service, so carts survive restarts and work across our three app instances. The shared cache is the only option we looked at.
