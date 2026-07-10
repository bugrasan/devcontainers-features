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

echo 'Done!'
