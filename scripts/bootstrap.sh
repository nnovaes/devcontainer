#!/usr/bin/env bash
# Idempotent prerequisite bootstrap. No tools are assumed to be preinstalled.
# Ensures Homebrew is installed + up-to-date, then installs git and go-task
# (the task runner this repo uses) via brew. Safe to run repeatedly.
#
# Run this FIRST on a fresh Mac, before `task setup`:
#   ./scripts/bootstrap.sh
set -euo pipefail

log() { printf '==> %s\n' "$*"; }

# Resolve the brew prefix for Apple silicon (default) or Intel, then load it
# into the current shell so the rest of the script can use `brew` immediately.
load_brew() {
  if command -v brew >/dev/null 2>&1; then
    return 0
  fi
  for prefix in /opt/homebrew /usr/local; do
    if [ -x "$prefix/bin/brew" ]; then
      eval "$("$prefix/bin/brew" shellenv)"
      return 0
    fi
  done
  return 1
}

# Install a brew formula if missing, otherwise upgrade it. Idempotent.
ensure_formula() {
  local formula="$1"
  if brew list --formula "$formula" >/dev/null 2>&1; then
    log "$formula already installed via brew; upgrading if needed..."
    brew upgrade "$formula" || true
  else
    log "Installing $formula via brew..."
    brew install "$formula"
  fi
}

# 1. Install Homebrew if missing.
if load_brew; then
  log "Homebrew already installed: $(brew --version | head -n1)"
else
  log "Installing Homebrew (may prompt for your admin password)..."
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if ! load_brew; then
    echo "Homebrew install completed but 'brew' could not be located on PATH." >&2
    exit 1
  fi
  log "Homebrew installed: $(brew --version | head -n1)"
fi

# 2. Make sure Homebrew itself is up-to-date.
log "Updating Homebrew..."
brew update

# 3. Ensure repo prerequisites are installed via brew.
ensure_formula git
ensure_formula go-task

log "Done."
log "  git:     $(git --version)"
log "  go-task: $(task --version)"
log "Next: run 'task setup'"
