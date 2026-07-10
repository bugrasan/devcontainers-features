#!/bin/bash

# exit on error
set -e

# variables provided by devcontainer-feature
CLAUDE_CODE_VERSION="${VERSION:-"latest"}"

# The 'install.sh' entrypoint script is always executed as the root user.
# For more details, see https://containers.dev/implementors/features#user-env-var
TARGET_USER="${_REMOTE_USER:-root}"

# claude.ai/install.sh is a self-contained native binary installer with no
# npm/node dependency - confirmed by running it non-interactively (no tty, no
# stdin) against a clean runner:
# https://github.com/bugrasan/devcontainer-base-ai/actions/runs/29093012572
# It installs under the invoking user's $HOME (~/.local/bin), so it must run
# as the container's remote user, not root.
su - "${TARGET_USER}" -c "curl -fsSL https://claude.ai/install.sh | bash -s -- ${CLAUDE_CODE_VERSION}"

echo 'Done!'
