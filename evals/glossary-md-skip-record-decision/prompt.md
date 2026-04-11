---
name: glossary-md-skip-record-decision
description: "Should not trigger glossary-md: recording an architecture decision belongs to adr-md."
tags: [glossary-md, skip]
plugins: ["../.."]
max_turns: 4
allowed_tools: [Read, Glob, Grep, Skill]
---

Record a decision: our image-resizing API will resize uploads on a background queue instead of inside the request, because large images keep timing out. We considered bigger instances and a separate resizing service and rejected both.
