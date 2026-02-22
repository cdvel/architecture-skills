---
name: adr-md-skip-dependency
description: "Adding a dependency is a small change, not an architecture decision; adr-md should not fire."
tags: [adr-md, skip]
plugins: ["../.."]
max_turns: 4
allowed_tools: [Read, Glob, Grep, Skill]
---

Add a date formatting library to package.json and use it in src/cart/totals.js to format the delivery date.
