#!/bin/bash

# exit on error
set -e

# The 'install.sh' entrypoint script is always executed as the root user.
# For more details, see https://containers.dev/implementors/features#user-env-var
TARGET_USER="${_REMOTE_USER:-root}"

# pi.dev/install.sh hard-requires Node.js >=22.19.0 and npm to already be
# present (it exits with "error: npm is required to install Pi." otherwise).
# 'installsAfter: node' in devcontainer-feature.json only guarantees this
# Feature's RUN layer executes after node's RUN layer (so node's files exist
# on disk) - it does NOT make node's own containerEnv (its PATH/NVM_DIR
# additions) active during a sibling Feature's install.sh at build time; that
# containerEnv only takes effect in the final container's runtime
# environment. Confirmed by a failing CI check where pi.dev's installer
# couldn't find node/npm at all despite node having installed successfully
# first: https://github.com/bugrasan/devcontainers-features/pull/13
#
# So node/npm must be resolved explicitly here, using the same stable
# 'current' version symlink the node Feature's own containerEnv references:
# https://github.com/devcontainers/features/blob/main/src/node/devcontainer-feature.json
NVM_DIR="${NVM_DIR:-/usr/local/share/nvm}"
NODE_BIN_DIR="${NVM_DIR}/current/bin"

# With node/npm present it installs fine non-interactively (no tty): it
# detects "No terminal detected" and just proceeds with the default action
# instead of aborting. Confirmed by running it non-interactively (no tty, no
# stdin) against a clean runner:
# https://github.com/bugrasan/devcontainer-base-ai/actions/runs/29093012572
# It runs 'npm install -g' under the invoking user, so it must run as the
# container's remote user, not root.
su "${TARGET_USER}" -c "export PATH='${NODE_BIN_DIR}:${PATH}'; curl -fsSL https://pi.dev/install.sh | sh"

echo 'Done!'
