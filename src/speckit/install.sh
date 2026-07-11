#!/bin/bash

# exit on error
set -e

# variables provided by devcontainer-feature
VERSION="${VERSION:-"latest"}"
# Remember whether the user asked for 'latest' BEFORE find_version_from_git_tags
# resolves it to a concrete tag. Only consumed by the (currently commented-out)
# auto-update marker block near the end of this script.
# shellcheck disable=SC2034
REQUESTED_VERSION="${VERSION}"
# Accept both '0.12.11' and 'v0.12.11' for an explicit version ('latest' is untouched).
VERSION="${VERSION#v}"

# The 'install.sh' entrypoint script is always executed as the root user.
# For more details, see https://containers.dev/implementors/features#user-env-var
# We install the tool AS the container's remote user, so uv's per-user tool dir
# (~/.local/bin, ~/.local/share/uv) is owned by that user - not root.
TARGET_USER="${_REMOTE_USER:-root}"
TARGET_HOME="${_REMOTE_USER_HOME:-/root}"
USER_LOCAL_BIN="${TARGET_HOME}/.local/bin"

# ---------------------------------------------------------------------------
# Helpers adopted from the official devcontainers/features:
#   apt_get_update / check_packages -> src/copilot-cli/install.sh
#   find_version_from_git_tags      -> src/github-cli/install.sh
# ---------------------------------------------------------------------------
apt_get_update() {
    if [ "$(find /var/lib/apt/lists/* 2>/dev/null | wc -l)" = "0" ]; then
        echo "Running apt-get update..."
        apt-get update -y
    fi
}

# Checks if packages are installed and installs them if not
check_packages() {
    if ! dpkg -s "$@" >/dev/null 2>&1; then
        apt_get_update
        apt-get -y install --no-install-recommends "$@"
    fi
}

# Figure out correct version if a three-part version number is not passed
find_version_from_git_tags() {
    local variable_name=$1
    local requested_version=${!variable_name}
    if [ "${requested_version}" = "none" ]; then return; fi
    local repository=$2
    local prefix=${3:-"tags/v"}
    local separator=${4:-"."}
    local last_part_optional=${5:-"false"}
    if [ "$(echo "${requested_version}" | grep -o "." | wc -l)" != "2" ]; then
        local escaped_separator=${separator//./\\.}
        local last_part
        if [ "${last_part_optional}" = "true" ]; then
            last_part="(${escaped_separator}[0-9]+)?"
        else
            last_part="${escaped_separator}[0-9]+"
        fi
        local regex="${prefix}\\K[0-9]+${escaped_separator}[0-9]+${last_part}$"
        local version_list="$(git ls-remote --tags ${repository} | grep -oP "${regex}" | tr -d ' ' | tr "${separator}" "." | sort -rV)"
        if [ "${requested_version}" = "latest" ] || [ "${requested_version}" = "current" ] || [ "${requested_version}" = "lts" ]; then
            declare -g ${variable_name}="$(echo "${version_list}" | head -n 1)"
        else
            set +e
            declare -g ${variable_name}="$(echo "${version_list}" | grep -E -m 1 "^${requested_version//./\\.}([\\.\\s]|$)")"
            set -e
        fi
    fi
    if [ -z "${!variable_name}" ] || ! echo "${version_list}" | grep "^${!variable_name//./\\.}$" >/dev/null 2>&1; then
        echo -e "Invalid ${variable_name} value: ${requested_version}\nValid values:\n${version_list}" >&2
        exit 1
    fi
    echo "${variable_name}=${!variable_name}"
}

# git is required by find_version_from_git_tags AND by uv's git+https install;
# ca-certificates/curl for TLS. uv and Python 3.11+ are assumed already present
# (see installsAfter / README prerequisites) and are NOT installed here.
check_packages ca-certificates curl git

# Resolve 'latest' (or a partial version) to a concrete release tag number, e.g.
# 0.12.11. An exact version is validated against the published tags.
find_version_from_git_tags VERSION "https://github.com/github/spec-kit"

# uv's tool dir is per-user, so install as the remote user. We use a non-login
# 'su ... -c' (which preserves the build-time environment) and additionally
# prepend ~/.local/bin to PATH - the same pattern used by the pi-dev and
# npm-packages Features. uv itself is assumed to be on PATH already.
su "${TARGET_USER}" -c "export PATH='${USER_LOCAL_BIN}:${PATH}'; uv tool install specify-cli --from git+https://github.com/github/spec-kit.git@v${VERSION}"

# ~/.local/bin isn't on PATH for non-interactive/non-login shells by default, so
# symlink the binary into /usr/local/bin (always on PATH) - same approach as the
# claude-code Feature.
ln -sf "${USER_LOCAL_BIN}/specify" /usr/local/bin/specify

# ---------------------------------------------------------------------------
# Startup self-upgrade marker (mirrors the copilot-cli Feature). Writes a marker
# only when the user asked for 'latest'; the postStartCommand in
# devcontainer-feature.json then runs `specify self upgrade` on each start.
# COMMENTED OUT for now - uncomment this block AND that postStartCommand to enable.
# ---------------------------------------------------------------------------
# if [ "${REQUESTED_VERSION}" = "latest" ]; then
#     mkdir -p /etc/devcontainer-speckit
#     touch /etc/devcontainer-speckit/auto-update
# fi

echo 'Done!'
