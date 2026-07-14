#!/bin/bash

# exit on error
set -e

# variables provided by devcontainer-feature
CLAUDE_CODE_VERSION="${VERSION:-"latest"}"

# The 'install.sh' entrypoint script is always executed as the root user.
# For more details, see https://containers.dev/implementors/features#user-env-var
TARGET_USER="${_REMOTE_USER:-root}"
TARGET_HOME="${_REMOTE_USER_HOME:-/root}"

# claude.ai/install.sh is a self-contained native binary installer with no
# npm/node dependency - confirmed by running it non-interactively (no tty, no
# stdin) against a clean runner:
# https://github.com/bugrasan/devcontainer-base-ai/actions/runs/29093012572
# It installs under the invoking user's $HOME (~/.local/bin), so it must run
# as the container's remote user (via a login shell, so HOME resolves
# correctly), not root.

# Ensure curl exists - minimal base images (debian:latest, ubuntu:latest)
# don't ship it, unlike mcr.microsoft.com/devcontainers/base images.
if ! command -v curl >/dev/null 2>&1; then
    apt-get update -y
    apt-get -y install --no-install-recommends ca-certificates curl
fi

su - "${TARGET_USER}" -c "curl -fsSL https://claude.ai/install.sh | bash -s -- ${CLAUDE_CODE_VERSION}"

# ~/.local/bin isn't on PATH for non-interactive/non-login shells by default
# (confirmed by a failing CI check: the installer itself warns "Native
# installation exists but ~/.local/bin is not in your PATH") - symlink it
# into /usr/local/bin, which every shell already has on PATH, rather than
# relying on PATH/containerEnv propagation.
ln -sf "${TARGET_HOME}/.local/bin/claude" /usr/local/bin/claude

# Install LSP code-intelligence plugins at USER scope (writes the target user's
# ~/.claude/settings.json) so Claude Code's LSP tool has language servers wired
# up. Runs as the remote user via a login shell so HOME/PATH resolve correctly.
#
# NON-FATAL by design: a plugin only wires the connection to a language server -
# the server BINARY (pyright-langserver, typescript-language-server, gopls, ...)
# must be installed separately and be on PATH for the plugin to activate. A
# missing binary, an unregistered marketplace, or a transient network error must
# NOT fail the image build, so each step is guarded with '|| echo WARNING'.
#
# A fresh Claude Code install has NO marketplaces registered (confirmed: the
# 'claude-plugins-official' marketplace is NOT auto-available - 'plugin install
# <p>@claude-plugins-official' fails with "not found in marketplace" and
# 'marketplace update' reports "Available marketplaces:" empty). So each
# marketplace repo in LSP_MARKETPLACES must be ADDED FIRST (at user scope,
# matching the plugin install scope) before the plugins can resolve.
LSP_PLUGINS="${LSPPLUGINS:-}"
LSP_MARKETPLACES="${LSPMARKETPLACES:-}"
if [ -n "${LSP_PLUGINS}" ]; then
    for repo in ${LSP_MARKETPLACES}; do
        echo "Adding Claude Code plugin marketplace: ${repo}"
        su - "${TARGET_USER}" -c "claude plugin marketplace add ${repo} --scope user" \
            || echo "WARNING: could not add marketplace '${repo}' (continuing)"
    done
    for plugin in ${LSP_PLUGINS}; do
        echo "Installing Claude Code LSP plugin: ${plugin}"
        su - "${TARGET_USER}" -c "claude plugin install ${plugin} --scope user" \
            || echo "WARNING: could not install plugin '${plugin}' - skipping (install the language-server binary and re-run 'claude plugin install ${plugin}' if you need it)"
    done
fi

echo 'Done!'
