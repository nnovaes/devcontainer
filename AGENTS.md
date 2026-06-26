# AGENTS.md

This file provides guidance to Claude Code when working in this repository.

## What This Repo Is

A Mac-native development environment definition using apple/container, persona-based OCI images, and chezmoi for config management. It targets Claude Code users doing platform engineering.

## Key Commands

```sh
# Prerequisites bootstrap (run FIRST on a fresh Mac — assumes nothing preinstalled).
# Installs/updates Homebrew, then installs git + go-task via brew.
./scripts/bootstrap.sh

# One-command machine bootstrap: installs prerequisites + apple/container + chezmoi, starts the container service.
# Requires go-task, so run ./scripts/bootstrap.sh first if `task` is not yet installed.
task setup

# Just the idempotent prerequisites step (also run as part of `task setup`)
task bootstrap

# Build a persona image (required before first up)
task build PERSONA=devops

# Start a container
task up PERSONA=devops

# Stop and remove a container
task down PERSONA=devops

# Restart a container by recreating it
task restart PERSONA=devops

# Switch personas (stops current, starts new)
task switch PERSONA=frontend

# Attach a shell to the running container
task attach

# List available personas
task list-personas
```

## Architecture

**Three layers:**
1. **OCI image (persona)** - `containers/Dockerfile` multi-stage build. Each target (`devops`, `frontend`, `qa`) installs tools via mise. Shared base tools live in `containers/base.mise.toml` (copied to `/etc/mise/config.toml`); persona-specific tools live in `containers/personas/<name>.mise.toml` (copied to `/etc/mise/conf.d/<name>.toml` and merged at build time).
2. **chezmoi source** - `dotfiles/` is bind-mounted read-only into the container as `/chezmoi-source`. `chezmoi apply --source /chezmoi-source` runs on container start and generates `~/.zshrc`, `~/.claude/settings.json`, and related config from templates.
3. **User preferences** - Stored in `~/.local/share/devcontainer-chezmoi/` on the Mac and bind-mounted as `~/.config/chezmoi/` in the container. Never committed. `chezmoi` prompts once for persona, model, and theme; answers persist across restarts.

**When a rebuild is required:**
- `containers/Dockerfile` changes
- Changes to `containers/base.mise.toml` or any `containers/personas/*.mise.toml` (tool version bumps)

**When a rebuild is NOT required:**
- Changes to `dotfiles/` (chezmoi applies on next container start)
- Changes to `Taskfile.yml`

## Adding A New Persona

1. Create `containers/personas/<name>.mise.toml` with persona-specific tools only (base tools come from `containers/base.mise.toml`).
2. Add a `FROM base AS <name>` stage to `containers/Dockerfile`, following the existing persona pattern (`COPY personas/<name>.mise.toml /etc/mise/conf.d/<name>.toml` then `mise install --system`).
3. Run `task build PERSONA=<name>`.

## Credentials

AWS credentials are mounted from `~/.aws` into the container. Claude Code credentials are managed inside the container through the chezmoi-generated `~/.claude` config. A future `dotfiles/dot_claude/private_dot_credentials.json.tmpl` can add 1Password-backed credential material if needed.
