---
name: adr-md-trigger-supersede
description: "Replacing an earlier recorded decision should trigger adr-md."
tags: [adr-md, trigger]
plugins: ["../.."]
max_turns: 4
allowed_tools: [Read, Glob, Grep, Skill]
---

ADR-0004 says we keep user sessions in server memory. That stopped working once we ran three instances behind the load balancer, and we've decided to move sessions to a shared cache service. Record the new decision so it replaces ADR-0004.
