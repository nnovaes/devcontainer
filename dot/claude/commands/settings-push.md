# /settings-push — push eligible local changes to settings.json.example

# Usage: /settings-push

# Copies team-relevant changes from your local `settings.json` back to the
# committed `settings.json.example`. Personal keys are never pushed. This file
# is tracked in git — pushing requires a commit/PR to share with the team.

## Step 1 — Verify Files

Both must exist:

- `~/.claude/settings.json`
- `~/.claude/settings.json.example`

If either is missing, stop with an error.

## Step 2 — Dry Run

```bash
python3 ~/.claude/bin/settings_merge.py push \
  --dry-run \
  --example ~/.claude/settings.json.example \
  --target ~/.claude/settings.json
```

Parse the JSON output. Key fields: `pushable`, `blocked`, `unchanged`.

Personal keys (never pushed): `model`, `theme`, `enabledPlugins`, `extraKnownMarketplaces`, `awsAuthRefresh`, `primaryApiKey`, `customApiKey`.

## Step 3 — Show Summary

Print two sections:

**Pushable** (will update `settings.json.example`):

```
hooks ................... updated (local value wins)
permissions.deny ........ added 2 entries
```

**Blocked** (personal — will NOT touch example):

```
model, theme, enabledPlugins, extraKnownMarketplaces, awsAuthRefresh
```

If `unchanged` is true and `pushable` is empty: report **PASS — nothing eligible to push** and stop.

## Step 4 — Confirm

Ask: **"Push these changes to settings.json.example? (yes / edit `<key>` / cancel)"**

- `yes` → proceed to Step 5
- `edit <key>` → ask what to change, update the proposed diff for that key, re-show the summary, ask again
- `cancel` → exit without writing

## Step 5 — Write

```bash
python3 ~/.claude/bin/settings_merge.py push \
  --example ~/.claude/settings.json.example \
  --target ~/.claude/settings.json
```

## Step 6 — Post-Write

Resolve the devcontainer repo root as the parent of `~/.claude` (the repo that owns the bind mount). Run:

```bash
git -C <devcontainer-repo> diff dot/claude/settings.json.example
```

Show the diff summary. Remind the user:

> `settings.json.example` is committed — create a commit or PR in the devcontainer repo to share team baseline changes.

## Trigger Rule

After editing `~/.claude/settings.json` (directly or on user request), ask:

> "Some of these changes look like team baseline policy. Run `/settings-push` to copy eligible keys to settings.json.example?"

Do not auto-push without explicit confirmation.
