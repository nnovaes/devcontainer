---
name: helm-values-validation
description: Validate that keys added or modified in a Helm values file are actually supported by the chart, and that the rendered template output reflects the intended change. Prevents silent key drops — Helm ignores unknown keys without error, so exit 0 does not mean your values were used.
---

# Helm Values Validation

`helm template` exiting 0 is necessary but not sufficient. Helm silently drops unsupported keys — the chart never uses them, no warning is emitted, and resources they were meant to create are never rendered.

Run both checks any time you add or modify a key in a chart's values file.

## Check 1 — Key exists in the chart

Confirm the chart supports every key you're adding or changing:

```bash
# Top-level key
helm show values <repo/chart> --version <version> | grep <key>

# Nested key path (e.g. ingress.enabled)
helm show values <repo/chart> --version <version> | yq '.<path.to.key>'
```

Silence or `null` means the chart does not support that key — it will be silently dropped. Check the chart's changelog or `helm show readme` for the correct key name before proceeding.

## Check 2 — Template output reflects the change

After `helm template`, assert the expected resources or values are in the output — not just that the command exited 0:

```bash
helm template <release> <repo/chart> --version <version> -f values.yaml \
  | grep -c 'kind: <ResourceKind>'
```

For non-resource changes (e.g. a config value), grep for the specific value instead of a resource kind. Expected count or match must align with what you intended.
