---
name: adr-md-skip-architecture-doc
description: "Near miss: editing ARCHITECTURE.md belongs to architecture-md, not adr-md."
tags: [adr-md, skip]
plugins: ["../.."]
max_turns: 4
allowed_tools: [Read, Glob, Grep, Skill]
---

Update docs/ARCHITECTURE.md: the payments service now calls the ledger service over gRPC instead of REST. Fix the component diagram and the request flow section.
