---
name: architecture-md-trigger-onboarding
description: Onboarding request for a whole-repo architecture doc should load architecture-md.
tags: [architecture-md, trigger]
plugins: ["../.."]
max_turns: 4
allowed_tools: [Read, Glob, Grep, Skill]
---
Can you document the architecture of this repo for onboarding? New engineers start next month and nothing is written down about how the pieces fit together.
