---
name: adr-md-trigger-queue-over-cron
description: "Writing up a settled choice between alternatives, without saying ADR, should trigger adr-md."
tags: [adr-md, trigger]
plugins: ["../.."]
max_turns: 4
allowed_tools: [Read, Glob, Grep, Skill]
---

We argued about this for two weeks and finally settled it: order confirmation emails will go through a message queue consumer instead of the nightly cron job. The cron job delayed emails by up to a day, and one failed run lost a whole day's emails. We also looked at calling the email provider directly from the checkout request, but didn't want checkout to depend on it. Can you write this up in the repo so people later know why we chose it?
