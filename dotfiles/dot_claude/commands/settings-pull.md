# /settings-pull — pull team baseline from settings.json.example into settings.json

# Usage: /settings-pull

# Merges the committed team baseline (`settings.json.example`) into your local
# `settings.json`. On conflict, the example wins. Personal keys (model, theme,
# enabledPlugins, etc.) are always preserved in settings.json.

## Step 1 — Verify Files

Paths (bind-mounted `~/.claude`):

- `~/.claude/settings.json.example` — must exist
- `~/.claude/settings.json` — may be absent on first run

If `settings.json.example` is missing, stop with an error.

## Step 2 — Dry Run

```bash
python3 ~/.claude/bin/settings_merge.py pull \
  --dry-run \
  --example ~/.claude/settings.json.example \
  --target ~/.claude/settings.json
```

Parse the JSON output. Key fields: `changes`, `preserved_personal_keys`, `unchanged`.

## Step 3 — Show Change Summary

Print one line per item:

```
hooks.PreToolUse ........ updated from example (team baseline)
skipDangerousModePermissionPrompt ... unchanged
model ................... preserved (personal key)
```

Rules:

- For each entry in `changes`, show path, action (`added` / `updated` / `removed`), and note it comes from the team baseline.
- For each key in `preserved_personal_keys`, show it will be kept unchanged.
- If `unchanged` is true and `changes` is empty: report **PASS — settings.json is already up to date** and stop.

## Step 4 — Confirm

Ask: **"Pull team baseline into settings.json? (yes / cancel)"**

- `yes` → proceed to Step 5
- `cancel` → exit without writing

## Step 5 — Apply

```bash
~/.claude/bin/install.sh
```

Or equivalently:

```bash
python3 ~/.claude/bin/settings_merge.py pull \
  --example ~/.claude/settings.json.example \
  --target ~/.claude/settings.json
```

## Step 6 — Verify

Re-read `~/.claude/settings.json`. Confirm every key from `settings.json.example` matches the example file, and personal keys from before the pull are still present.

Report **PASS** or list any mismatch.

## When to Use

- After `git pull` updates `settings.json.example`
- When team policy in your local `settings.json` seems stale
- On container start, `install.sh` runs this automatically — use `/settings-pull` for an interactive dry-run and confirmation
