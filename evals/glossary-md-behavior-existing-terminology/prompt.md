---
name: glossary-md-behavior-existing-terminology
description: "A repo with docs/TERMINOLOGY.md; new terms go into that file, in sort order, and no GLOSSARY.md is created. Run with --scaffold and --allow-tools Write Edit Bash."
tags: [glossary-md, behavior]
plugins: ["../.."]
max_turns: 25
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

Add "refund" and "chargeback" to our glossary. Refund: money we return to a customer on our own initiative. Chargeback: a reversal of a payment that the cardholder's bank starts after a dispute. Both are team conventions.
