---
name: capture-decision
description: Capture the rationale behind a non-obvious implementation decision as a project memory, so a reviewer's challenge is answered from the record rather than reconstructed under pressure. Use when you chose among alternatives, worked around a constraint, ruled out a simpler approach, or fixed a pre-existing bug — and in a pre-PR sweep.
---

# Capture Decision

Record why a non-obvious choice was made, before the reasoning is lost.

## When to capture
- You evaluated 2+ alternatives and chose one
- A constraint (framework, existing code, API boundary) forced or shaped the approach
- A simpler solution was ruled out for a specific reason
- The code as written wouldn't reveal the "why" to a reviewer
- You fixed or refactored a pre-existing bug, proactively or because it blocked the task
- A decision promotes an explicit team value (security, observability, reliability, automation, …)

Also sweep before opening a PR: review the session's significant decisions and capture any not yet recorded.

## Format
Write a `project`-type memory (see the harness Memory section for frontmatter and the MEMORY.md index). Body:

```
[The decision in one sentence]

**Alternatives considered:** [what else was evaluated, and why rejected]
**Constraints:** [what drove or bounded the choice]
**Tradeoffs accepted:** [what was given up to get this approach]
```

## Where captures live
If the project stores memories in-repo (e.g. `.claude/memory/`), confirm the path is gitignored before the session ends; add an entry if it isn't. Never commit memory files to version control.
