---
name: reflect
description: Quick session reflection — scan MEMORY.md for 2+ occurrence patterns and propose one delta to AGENTS.md or a playbook. Use after a productive session.
---

# Reflect: Session Pattern Extraction

Quick reflection pass. 2 minutes, one output.

## Step 1: Read MEMORY.md

Find and read the current project's MEMORY.md (same search as auto-dream skill).

## Step 2: Identify patterns

Look for entries that appear in 2 or more forms (same concept, different phrasing).
A qualifying pattern is something the agent has needed to be told more than once.

## Step 3: Propose one delta

If a 2+ occurrence pattern exists AND it would be useful as an enforced rule:
- Draft the exact text to add to AGENTS.md (one bullet) or a playbook (one step)
- Write it to `tuning/pending-deltas/<timestamp>-reflect.md` using the format in `tuning/prompts/reflect.md`

If no pattern qualifies: say "No delta warranted — session was routine."

Reject without hesitation. A rule that could be wrong shouldn't be added.
