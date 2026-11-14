---
name: glossary-md-trigger-draft-from-code
description: "Should trigger glossary-md: pulling the domain terms out of the codebase into a glossary for review."
tags: [glossary-md, trigger]
plugins: ["../.."]
max_turns: 4
allowed_tools: [Read, Glob, Grep, Skill]
---

Go through the codebase and pull out the domain terms we use into a glossary I can review.
