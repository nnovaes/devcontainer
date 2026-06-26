# Platform Dev Environment — Quickstart

A Mac-native development environment for platform engineering. Tools and Claude Code run inside a persona-based Linux container; your Mac provides credentials, repos, and an editor.

---

## Prerequisites

| Requirement | Notes |
|---|---|
| Mac with Apple silicon | `apple/container` does not support Intel Macs |
| macOS 26 (Tahoe) recommended | Older macOS may work but is not officially supported |
| [Homebrew](https://brew.sh) | Installed/updated automatically by `scripts/bootstrap.sh` |
| [go-task](https://taskfile.dev) | Installed by `scripts/bootstrap.sh`; runs all repo commands |
| git | Installed via brew by `scripts/bootstrap.sh` |
| `~/.aws` on the host (optional at first run) | Bind-mounted into the container for SSO and profiles; `task up` creates an empty directory if missing |
| `~/workspaces` | Clone your repos here; the container mounts it at `/workspaces`; `task up` creates it if missing |

---

## One-time machine setup

From this repo root:

```sh
# Installs prerequisites (Homebrew, git, go-task). No tools assumed preinstalled.
./scripts/bootstrap.sh

# Now that go-task is available, finish setup.
task setup
```

`scripts/bootstrap.sh` is idempotent and assumes nothing is preinstalled — it installs/updates Homebrew, then installs `git` and `go-task` via brew. Run it first because `task setup` itself requires `go-task`.

`task setup` then installs chezmoi (if missing), installs `apple/container` from the pinned GitHub release (admin password required), and starts the container service. It also re-runs the bootstrap step (via `task bootstrap`) so prerequisites stay current.

---

## First run

Build a persona image, start the container, and attach a shell:

```sh
task build PERSONA=devops
task up PERSONA=devops
task attach PERSONA=devops
```

On first `task up`, chezmoi prompts once for:

- **Persona** — `devops`, `frontend`, or `qa` (default: `devops`)
- **Claude model** — e.g. `claude-sonnet-4-6`
- **Theme** — `dark` or `light`

Answers are stored in `~/.local/share/devcontainer-chezmoi/` on your Mac and persist across container restarts.

Inside the container, verify the environment:

```sh
echo $SHELL                    # /bin/zsh
terraform --version            # devops persona
bat --version
claude --version
```

Authenticate Claude Code on first use:

```sh
claude
```

Follow the browser OAuth flow. Credentials live inside the container's `~/.claude` directory.

---

## Daily workflow

| Command | Purpose |
|---|---|
| `task up PERSONA=devops` | Start (or restart) a persona container |
| `task attach PERSONA=devops` | Open an interactive zsh shell |
| `task switch PERSONA=frontend` | Stop all persona containers and start a different one |
| `task list-personas` | List available personas |
| `task build PERSONA=devops` | Rebuild an image after Dockerfile or tool changes |

Your repos are at `/workspaces/` inside the container:

```sh
cd /workspaces/my-infra-repo
```

Use your editor on the Mac and run commands in the container via `task attach`, or point your editor's remote/terminal integration at the running container if supported.

---

## Personas

Each persona is a separate OCI image with its own tool set:

| Persona | Typical use | Example tools |
|---|---|---|
| `devops` | Platform / infra work | terraform, kubectl, helm, aws |
| `frontend` | Frontend development | node, pnpm, bun, deno |
| `qa` | Load / API testing | node, pnpm, k6 |

Switch personas without rebuilding the others:

```sh
task switch PERSONA=frontend
task attach PERSONA=frontend
```

---

## How config is managed

Three layers:

1. **OCI image** — `containers/Dockerfile` builds persona images. Tools are installed via mise during the image build.
2. **chezmoi source** — `dotfiles/` in this repo. On `task up`, chezmoi generates `~/.zshrc`, `~/.claude/settings.json`, starship config, and related files inside the container.
3. **User preferences** — persona/model/theme prompts stored at `~/.local/share/devcontainer-chezmoi/` on the Mac (never committed).

Edit shell or Claude settings by changing templates under `dotfiles/`, then restart the container:

```sh
container stop devcontainer-devops
task up PERSONA=devops
```

---

## AWS credentials

`~/.aws` from your Mac is bind-mounted into the container. If you have not configured AWS yet, `task up` creates an empty `~/.aws` so the container can start; add profiles or run `aws configure` / `aws sso login` before using AWS CLI commands.

```sh
aws sts get-caller-identity

# If SSO session expired
aws sso login --profile <your-profile>
```

Default Claude Code AWS env vars are set in `dotfiles/dot_claude/settings.json.tmpl` (`AWS_REGION`, `AWS_PROFILE`). Adjust the template if your team uses different defaults.

---

## When to rebuild

**Rebuild required** (`task build PERSONA=<name>`):

- Changes to `containers/Dockerfile`
- Changes to `containers/base.mise.toml` or `containers/personas/*.mise.toml` (tool version bumps)

**Rebuild not required:**

- Changes to `dotfiles/` — restart the container (`task up`) to re-apply chezmoi
- Changes to `Taskfile.yml`

After rebuilding, restart the container:

```sh
container stop devcontainer-devops
task build PERSONA=devops
task up PERSONA=devops
```

---

## Changing tool versions

Base tools are defined in `containers/base.mise.toml`. Persona-specific tools live in `containers/personas/<persona>.mise.toml`. mise merges both at image build time via `/etc/mise/config.toml` and `/etc/mise/conf.d/<persona>.toml`.

```toml
# containers/personas/devops.mise.toml
[tools]
terraform = "1.9.8"   # was "latest"
```

To change a base tool version, edit `containers/base.mise.toml` instead (rebuilds all personas).

Then rebuild:

```sh
task build PERSONA=devops
```

To pin a tool for a single repo without rebuilding the image, add a `.mise.toml` in that repo and run `mise install` inside the container.

---

## Adding a new persona

1. Create `containers/personas/<name>.mise.toml` with persona-specific tools only.
2. Add a `FROM base AS <name>` stage to `containers/Dockerfile` (follow the existing devops pattern).
3. Build and start: `task build PERSONA=<name>` then `task up PERSONA=<name>`.

---

## What persists

| Data | Location | Survives container restart? | Survives image rebuild? |
|---|---|---|---|
| Persona / model / theme prompts | `~/.local/share/devcontainer-chezmoi/` on Mac | Yes | Yes |
| Shell history (atuin) | Container home | Yes (same container) | No (new container) |
| Claude credentials | `~/.claude/` in container | Yes (same container) | No (new container) |
| AWS SSO cache | `~/.aws` on Mac | Yes | Yes |
| Your repos | `~/workspaces` on Mac | Yes | Yes |

Claude Code session history is ephemeral and resets when you recreate the container.

---

## Troubleshooting

**`task: command not found`** — go-task isn't installed yet. Run `./scripts/bootstrap.sh` to install prerequisites, then `task setup`.

**`container: command not found`** — Run `task setup`.

**Build fails on first run** — First persona builds can take 5–15 minutes while mise downloads tools. Subsequent builds use cache and are faster.

**chezmoi prompts every restart** — Check that `~/.local/share/devcontainer-chezmoi/` exists and is writable. `task up` creates it automatically.

**`Error: path '.../.aws' does not exist`** — Older versions required `~/.aws` before `task up`. Update to the latest `Taskfile.yml` (which creates `~/.aws`, `~/workspaces`, and the chezmoi state dir automatically), or run `mkdir -p ~/.aws ~/workspaces` and retry.

**Wrong persona tools** — You may have started the wrong image. Run `task switch PERSONA=<name>` to stop other containers and start the correct one.

**Upgrade apple/container** — Bump `CONTAINER_VERSION` in `Taskfile.yml`, then run `task setup`.

---

## Security note

`~/.aws` is mounted read/write so `aws sso login` can cache tokens inside the container. This setup is intended for your own infrastructure repositories on a trusted Mac, not for running untrusted code with host credential access.
