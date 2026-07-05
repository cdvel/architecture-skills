---
name: brief-skip-record-decision
description: "Asks to record an architecture decision, which is adr-md's job; brief should not fire."
tags: [brief, skip]
plugins: ["../.."]
max_turns: 4
allowed_tools: [Read, Glob, Grep, Skill]
---

Record a decision: we're moving image resizing out of the API process into a background worker queue. Write it up as an ADR.
