#!/bin/bash

# exit on error
set -e

# The 'install.sh' entrypoint script is always executed as the root user.
# For more details, see https://containers.dev/implementors/features#user-env-var
TARGET_USER="${_REMOTE_USER:-root}"
TARGET_USER_HOME="${_REMOTE_USER_HOME:-$(getent passwd "${TARGET_USER}" | cut -d: -f6)}"

# Upstream's official installer, run unchanged.
PI_INSTALL_URL="https://pi.dev/install.sh"
INSTALL_DIR="/usr/local/bin"

# pi.dev/install.sh hard-requires Node.js >=22.19.0 and npm. The node Feature's
# containerEnv (its PATH) is not active while a sibling Feature's install.sh
# runs, so put its stable 'current' bin directory on PATH explicitly:
# https://github.com/bugrasan/devcontainers-features/pull/13
NVM_DIR="${NVM_DIR:-/usr/local/share/nvm}"
NODE_BIN_DIR="${NVM_DIR}/current/bin"

# Save the script first, so a failed download fails the build instead of
# piping an empty script into sh.
tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT
curl -fsSL --retry 3 --connect-timeout 10 --max-time 60 "${PI_INSTALL_URL}" -o "${tmpdir}/install.sh"
chmod 0755 "${tmpdir}" "${tmpdir}/install.sh"

# A link left by an earlier run would make upstream's installer pick
# /usr/local/bin for its launcher, which the remote user cannot write. Drop it;
# it is recreated below.
if [ -L "${INSTALL_DIR}/pi" ]; then rm -f "${INSTALL_DIR}/pi"; fi

# Pi installs per user, so run the installer as the remote user. Without a
# terminal it proceeds with its default action instead of prompting.
su "${TARGET_USER}" -c "export PATH='${NODE_BIN_DIR}:${PATH}'; sh '${tmpdir}/install.sh'"

# Upstream's managed install puts its launcher in ~/.pi/agent/bin, which is not
# on PATH. Link it into a system-wide bin directory; the launcher follows
# symlinks to find its install, so 'pi update' keeps working.
PI_LAUNCHER="${TARGET_USER_HOME}/.pi/agent/bin/pi"
if [ ! -x "${PI_LAUNCHER}" ]; then
    echo "ERROR: upstream's installer did not create ${PI_LAUNCHER}."
    exit 1
fi
ln -sf "${PI_LAUNCHER}" "${INSTALL_DIR}/pi"

echo "Done! pi installed for '${TARGET_USER}' and linked as '${INSTALL_DIR}/pi'."
