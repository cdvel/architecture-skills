---
name: architecture-md-behavior-missing-deploy
description: Repo with no deployment files (no container file, manifests, IaC or deploy steps); the Infrastructure and deployment section must state a gap instead of inventing a deployment. Writes files, so run with --scaffold and --allow-tools Write Edit Bash.
tags: [architecture-md, behavior]
plugins: ["../.."]
max_turns: 40
timeout_seconds: 1200
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---
Document the architecture of this service in docs/ARCHITECTURE.md. We need it for a pre-production review, including how it is deployed. Go ahead without asking; I won't be around to answer questions.
