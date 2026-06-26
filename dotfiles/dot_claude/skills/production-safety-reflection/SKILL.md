---
name: production-safety-reflection
description: Use before any write operation against production code or infrastructure — deploy, delete, migrate, scale, or run a command against a live system. Covers IaC (Terraform/OpenTofu, CloudFormation, CDK, Pulumi), kubectl/helm against a prod cluster, database migrations or queries, CI/CD that ships to prod, any CD/GitOps operation that modifies live state (sync, refresh, rollout, reconcile, redeploy — regardless of tool), secrets/IAM/security groups, DNS, load balancers, AWS CLI/SAM, and anything holding real data or serving real users. Trigger even when the user didn't ask for a safety check and even when the change looks small.
---

# Production Safety Reflection

**Goal:** classify each risk as *confirmed-safe* or *unconfirmed*, then stop only when an unconfirmed risk reaches production.

## What counts as production?

Check these signals in order. Stop as soon as you can classify the target.

- **Named signals**: context/namespace/account names containing `prod`, `prd`, `production`, `live`; known prod cluster names or AWS account IDs/aliases; ArgoCD app names or Argo namespaces that reference prod clusters
- **Behavioral signals**: real users or traffic, real persistent data, active SLAs or on-call rotations, billing-active resources
- **Structural signals**: resource shared across teams, no equivalent staging counterpart, not easily reproducible
- **Memory**: check user-level memory for prior confirmed classifications. If memory records any resource in an environment as production, infer that other resources in the same environment (same account, cluster, namespace, VPC, etc.) are also production unless the relationship is clearly ambiguous.
- **Cannot classify?** Ask the user. Do not default to either prod or non-prod and silently proceed.

**When the user confirms a target is production**, save it as a `user`-level memory entry so future sessions can skip the classification step.

## Risk checklist

For each dimension: is the risk **confirmed-safe** or **unconfirmed**? Name the actual resource and worst case — not generic categories.

| Dimension | Confirmed-safe means |
|---|---|
| **Reversibility** | Exact rollback path verified, not assumed. `DROP`, `--force`, destroy, state overwrite = highest-priority pause. |
| **Backup** | Recent backup verified and restorable. "Probably a snapshot" = unconfirmed. |
| **Blast radius** | Exact scope known including downstream. Watch wildcards, missing `--target`, shared modules, wrong context. **For fixes:** also identify what else was silently blocked by the broken state — other consumers of the same resource that will resume when fixed. A fix's blast radius includes everything it unblocks, not just what it directly touches. |
| **Security** | No widened access, exposed secret, weakened auth, or new escalation path — even temporarily. |
| **State integrity** | Idempotent; partial failure can't corrupt state. Migrations won't lock or degrade unacceptably. |
| **Observability** | A metric/alert/log will surface failure fast. Silent failure = unconfirmed. |
| **Timing** | Safe now: traffic levels, deploy freezes, in-flight changes, on-call coverage all checked. |

## Decision

- **All confirmed-safe** → proceed, briefly stating what you checked: *"Reversible, no data risk, no access change — applying."*
- **Any unconfirmed** → **STOP.** Use this format:

```
⏸️ Pausing before this touches production.

Action: <exact command / change>
Target: <env / cluster / resource>

Unconfirmed risk(s):
- <risk — why unconfirmed, worst case>

To proceed I need:
- <what you need from the user>

Want me to <safer alternative> instead, or proceed as-is?
```

Always offer a safer path when one exists: dry-run, `--target`, snapshot first, scope down the IAM grant.

## Don't rationalize past the pause

| Rationalization | Reality |
|---|---|
| "It's a small change." | Small prod changes cause most incidents. |
| "The user clearly wants this done." | They want it done safely. Confirming the risk is doing it. |
| "Staging worked, prod is the same." | Different data, scale, traffic. Unconfirmed until verified. |
| "It was already broken — fixing it can't make things worse." | Other systems may have adapted to or been gated by the broken state. Fixing it re-activates them. What else resumes when this is fixed? |
| "There's probably a backup." | "Probably" is unconfirmed. Verify or take one. |
| "Rolling back is easy." | Only if the rollback path is verified. Assumed rollback is no rollback. |
| "Asking now is annoying." | One message vs an incident. |
| "It's just a sync / refresh / rollout." | Syncing deploys code, restarts pods, and applies config changes. For an out-of-sync prod app, triggering a sync IS a deployment. Refresh + sync on a prod ArgoCD app = prod deploy. |

## Examples

**Proceed:** bump `replicas` 3→4 on a stateless prod deployment — reversible, no data, no access change, metrics visible. → *"Scaling web-api 3→4 — stateless, reversible, no security/data impact. Applying."*

**Pause:** `tofu apply` shows `aws_db_instance` replacement (destroy+create). Data loss risk; "a snapshot exists" is unconfirmed. → Surface the replacement, ask for a verified snapshot, offer to take one first.
