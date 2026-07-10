#!/bin/bash

# exit on error
set -e

# The 'install.sh' entrypoint script is always executed as the root user.
# For more details, see https://containers.dev/implementors/features#user-env-var
TARGET_USER="${_REMOTE_USER:-root}"

# pi.dev/install.sh hard-requires Node.js >=22.19.0 and npm to already be
# present (it exits with "error: npm is required to install Pi." otherwise) -
# that's what 'installsAfter: node' in devcontainer-feature.json guarantees.
# With node/npm present it installs fine non-interactively (no tty): it
# detects "No terminal detected" and just proceeds with the default action
# instead of aborting. Confirmed by running it non-interactively (no tty, no
# stdin) against a clean runner:
# https://github.com/bugrasan/devcontainer-base-ai/actions/runs/29093012572
# It runs 'npm install -g' under the invoking user, so it must run as the
# container's remote user, not root.
su - "${TARGET_USER}" -c "curl -fsSL https://pi.dev/install.sh | sh"

echo 'Done!'
