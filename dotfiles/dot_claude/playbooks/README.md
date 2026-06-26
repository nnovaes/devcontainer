# Playbooks

Multi-step procedures an agent executes step by step. Write like a runbook — concrete commands, not vague advice.

## Format

```markdown
# Playbook: [Name]
## When to use
[One sentence]
## Steps
1. [Concrete step with exact command]
2. Quote file:line when referencing code
...
N. Stop and report before applying anything irreversible.
```

## Naming

`<verb>-<noun>.md` — e.g. `debug-prod-incident.md`, `scaffold-new-service.md`
