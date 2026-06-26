# CLAUDE.md

This file provides guidance to Claude Code when working in this repository.

## What This Repo Is

A Mac-native development environment definition using apple/container, persona-based OCI images, and chezmoi for config management. It targets Claude Code users doing platform engineering.

## Key Commands

```sh
# One-command machine bootstrap: installs apple/container + chezmoi and starts the container service
task setup

# Build a persona image (required before first up)
task build PERSONA=devops

# Start a container
task up PERSONA=devops

# Switch personas (stops current, starts new)
task switch PERSONA=frontend

# Attach a shell to the running container
task attach

# List available personas
task list-personas
```

## Architecture

**Three layers:**
1. **OCI image (persona)** - `containers/Dockerfile` multi-stage build. Each target (`devops`, `frontend`, `qa`) installs a complete tool set via mise. Base tools are repeated in each persona `.mise.toml`; `containers/.mise.toml` is the reference template.
2. **chezmoi source** - `dotfiles/` is bind-mounted read-only into the container as `/chezmoi-source`. `chezmoi apply --source /chezmoi-source` runs on container start and generates `~/.zshrc`, `~/.claude/settings.json`, and related config from templates.
3. **User preferences** - Stored in `~/.local/share/devcontainer-chezmoi/` on the Mac and bind-mounted as `~/.config/chezmoi/` in the container. Never committed. `chezmoi` prompts once for persona, model, and theme; answers persist across restarts.

**When a rebuild is required:**
- `containers/Dockerfile` changes
- Any `containers/personas/*.mise.toml` change (tool version bumps)

**When a rebuild is NOT required:**
- Changes to `dotfiles/` (chezmoi applies on next container start)
- Changes to `Taskfile.yml`

## Adding A New Persona

1. Copy `containers/.mise.toml` to `containers/personas/<name>.mise.toml`.
2. Add persona-specific tools below the base tools section.
3. Add a `FROM base AS <name>` stage to `containers/Dockerfile`, following the existing persona pattern.
4. Run `task build PERSONA=<name>`.

## Credentials

AWS credentials are mounted from `~/.aws` into the container. Claude Code credentials are managed inside the container through the chezmoi-generated `~/.claude` config. A future `dotfiles/dot_claude/private_dot_credentials.json.tmpl` can add 1Password-backed credential material if needed.
