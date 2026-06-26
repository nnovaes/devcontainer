# Prompts

One `.md` file per prompt. Subdirectory by function. Tool-neutral — never name a model.

## Front matter (recommended)

```yaml
---
purpose: one sentence
inputs: what context it expects
output: what it produces
---
```

## Subdirectories

| Dir | Use for |
|---|---|
| `code/` | generation, scaffolding, modification |
| `review/` | code review, security, diffs |
| `writing/` | release notes, docs, summaries |

## Invoke

Run any prompt through the current AI tool:
```bash
AI_TOOL=claude bin/ask review/security-pass
AI_TOOL=gemini bin/ask review/security-pass   # future
```
