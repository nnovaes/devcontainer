FROM mcr.microsoft.com/devcontainers/base:ubuntu AS base

# System packages
USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    unzip \
    openssh-client \
    git \
    thefuck \
    pipx \
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

# Install Node LTS via NodeSource — kept outside mise so npm is a plain system binary
# that sfw can wrap directly without needing mise shim awareness.
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - \
 && apt-get install -y --no-install-recommends nodejs \
 && rm -rf /var/lib/apt/lists/*

# Set zsh as the login shell for the vscode user
RUN chsh -s /bin/zsh vscode

# Install zsh plugins system-wide
RUN git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions \
        /usr/local/share/zsh-autosuggestions \
 && git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting \
        /usr/local/share/zsh-syntax-highlighting

# Install mise as root so it can write to /usr/local/bin and install tools system-wide.
# Tools land in /usr/local/share/mise/installs — outside any home bind-mount.
ENV MISE_INSTALL_PATH="/usr/local/bin/mise" \
    PATH="/usr/local/share/mise/shims:$PATH"
RUN curl https://mise.run | sh

# Install chezmoi system-wide
RUN sh -c "$(curl -fsLS get.chezmoi.io)" -- -b /usr/local/bin

# Install DCG (Destructive Command Guard) via upstream install script.
RUN curl -fsSL "https://raw.githubusercontent.com/Dicklesworthstone/destructive_command_guard/main/install.sh?$(date +%s)" | bash -s -- --version v0.5.7

# npm global installs run as root since node came from apt.
# Placed near end so upper layers survive claude-code version bumps.
RUN npm install -g sfw
RUN sfw npm install -g @anthropic-ai/claude-code

USER vscode
WORKDIR /home/vscode

# Wire mise activation into bash (zsh activation comes from chezmoi-managed .zshrc)
RUN echo 'eval "$(mise activate bash)"' >> ~/.bashrc

# Pre-create directories so volumes inherit vscode ownership on first mount.
# Symlink ~/.claude.json → ~/.claude/.claude.json so machine identity survives container restarts.
RUN mkdir -p /home/vscode/.claude \
 && mkdir -p /home/vscode/.local/share/atuin \
 && mkdir -p /home/vscode/.local/bin \
 && mkdir -p /home/vscode/.config/chezmoi \
 && ln -sf /usr/bin/claude /home/vscode/.local/bin/claude \
 && ln -s /home/vscode/.claude/.claude.json /home/vscode/.claude.json

# Bake GitHub SSH host key so git-over-SSH works without interactive prompts.
RUN mkdir -p ~/.ssh && ssh-keyscan github.com >> ~/.ssh/known_hosts 2>/dev/null

# NOTE: .zshrc is NOT copied here. chezmoi applies it at container start from /chezmoi-source.

# Shared base tool set — persona stages add /etc/mise/conf.d/<persona>.toml fragments.
COPY base.mise.toml /etc/mise/config.toml

FROM base AS devops
USER root
COPY personas/devops.mise.toml /etc/mise/conf.d/devops.toml
RUN --mount=type=cache,id=mise-devops,target=/root/.cache/mise \
    MISE_CACHE_DIR=/root/.cache/mise mise install --system
USER vscode

FROM base AS frontend
USER root
COPY personas/frontend.mise.toml /etc/mise/conf.d/frontend.toml
RUN --mount=type=cache,id=mise-frontend,target=/root/.cache/mise \
    MISE_CACHE_DIR=/root/.cache/mise mise install --system
USER vscode

FROM base AS qa
USER root
COPY personas/qa.mise.toml /etc/mise/conf.d/qa.toml
RUN --mount=type=cache,id=mise-qa,target=/root/.cache/mise \
    MISE_CACHE_DIR=/root/.cache/mise mise install --system
USER vscode
