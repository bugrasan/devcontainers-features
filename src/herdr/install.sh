#!/bin/bash

# exit on error
set -e

# variables provided by devcontainer-feature (option names are uppercased)
HERDR_VERSION="${VERSION:-"latest"}"
CONFIGURE_DEFAULTS="${CONFIGUREDEFAULTS:-"true"}"
INSTALL_SKILL="${INSTALLSKILL:-"true"}"
INSTALL_COMPLETIONS="${INSTALLCOMPLETIONS:-"true"}"

# The 'install.sh' entrypoint script is always executed as the root user.
# For more details, see https://containers.dev/implementors/features#user-env-var
TARGET_USER="${_REMOTE_USER:-root}"
TARGET_USER_HOME="${_REMOTE_USER_HOME:-}"

RELEASES_REPO="https://github.com/herdrdev/herdr"
# Upstream's release manifest - the same file herdr.dev serves as latest.json
# and that 'herdr update' reads. Taken from raw.githubusercontent.com rather
# than herdr.dev so the build only ever needs to reach GitHub.
MANIFEST_URL="https://raw.githubusercontent.com/herdrdev/herdr/master/distribution/latest.json"
INSTALL_DIR="/usr/local/bin"
BASH_COMPLETION_DIR="/usr/share/bash-completion/completions"
ZSH_COMPLETION_DIR="/usr/local/share/zsh/site-functions"

APT_UPDATED="false"

# Install packages via apt, running 'apt-get update' at most once. Package
# lists are cleaned up at the end of the script, but only if we touched apt.
apt_install() {
    export DEBIAN_FRONTEND=noninteractive
    if [ "${APT_UPDATED}" != "true" ]; then
        apt-get update -y
        APT_UPDATED="true"
    fi
    apt-get -y install --no-install-recommends "$@"
}

# Ensure curl and a SHA-256 tool exist - minimal base images (debian:latest,
# ubuntu:latest) ship neither, unlike mcr.microsoft.com/devcontainers/base.
MISSING_TOOLS=()
command -v curl >/dev/null 2>&1 || MISSING_TOOLS+=(ca-certificates curl)
command -v sha256sum >/dev/null 2>&1 || MISSING_TOOLS+=(coreutils)
if [ "${#MISSING_TOOLS[@]}" -gt 0 ]; then
    apt_install "${MISSING_TOOLS[@]}"
fi

# Map machine architecture to upstream's release asset naming
# (herdr-linux-<arch>). Upstream publishes linux x86_64 and aarch64 only.
case "$(uname -m)" in
    x86_64 | amd64) ARCH="x86_64" ;;
    aarch64 | arm64) ARCH="aarch64" ;;
    *)
        echo "ERROR: unsupported architecture '$(uname -m)' - herdr publishes linux x86_64 and aarch64 binaries only."
        exit 1
        ;;
esac
TARGET="linux-${ARCH}"

# Accept both '0.8.2' and 'v0.8.2' for the pinned case.
HERDR_VERSION="${HERDR_VERSION#v}"

# Pull the release manifest once: it resolves 'latest' AND carries the
# per-target SHA-256 checksums used to verify the download below. Missing it
# is not fatal - the fallbacks further down cover both jobs.
MANIFEST_FILE="$(mktemp)"
MANIFEST_OK="true"
trap 'rm -f "${MANIFEST_FILE}"' EXIT
if ! curl -fsSL --retry 3 --connect-timeout 10 --max-time 30 "${MANIFEST_URL}" -o "${MANIFEST_FILE}"; then
    echo "WARNING: could not fetch the herdr release manifest from ${MANIFEST_URL}."
    MANIFEST_OK="false"
    : > "${MANIFEST_FILE}"
fi

# Read the manifest's top-level "version", which names its newest release.
manifest_version() {
    awk '
        /^[[:space:]]*"version"[[:space:]]*:/ {
            value = $0
            sub(/^[^:]*:[[:space:]]*"/, "", value)
            sub(/".*$/, "", value)
            print value
            exit
        }
    ' "${MANIFEST_FILE}"
}

# Read the SHA-256 for a version/target pair out of the manifest. The manifest
# mirrors its newest release at the top level and lists every release under
# "releases"; both layouts are handled. Prints nothing when that version
# publishes no checksum - upstream only started doing so with 0.8.0.
manifest_sha256() {
    awk -v want_version="$1" -v want_target="$2" '
        # "notes" values are single-line markdown blobs that may contain any
        # character, braces included. Drop them before tracking JSON structure
        # so the brace counting below only ever sees structural braces.
        /^[[:space:]]*"notes"[[:space:]]*:/ { next }

        {
            line = $0
            # Remember which key opens this object, then track nesting depth.
            key = ""
            if (match(line, /^[[:space:]]*"[^"]+"[[:space:]]*:[[:space:]]*\{[[:space:]]*$/)) {
                key = line
                sub(/^[[:space:]]*"/, "", key)
                sub(/"[[:space:]]*:.*$/, "", key)
            }

            n_open = gsub(/\{/, "{", line)
            n_close = gsub(/\}/, "}", line)

            if (n_open > n_close) { depth++; path[depth] = key }

            if (n_open == 0 && n_close == 0) {
                # The top-level checksums describe the top-level "version"
                # only, so record which release that is before trusting them.
                if (path[depth] == "" && $0 ~ /^[[:space:]]*"version"[[:space:]]*:/) {
                    manifest_version = $0
                    sub(/^[^:]*:[[:space:]]*"/, "", manifest_version)
                    sub(/".*$/, "", manifest_version)
                }
                if (path[depth] == "sha256") {
                    top_level = (path[depth - 1] == "" && manifest_version == want_version)
                    per_release = (path[depth - 2] == "releases" && path[depth - 1] == want_version)
                    if ((top_level || per_release) && index($0, "\"" want_target "\"")) {
                        value = $0
                        sub(/^[^:]*:[[:space:]]*"/, "", value)
                        sub(/".*$/, "", value)
                        if (value ~ /^[0-9a-fA-F]{64}$/) { print tolower(value); exit }
                    }
                }
            }

            if (n_close > n_open) { path[depth] = ""; depth-- }
        }
    ' "${MANIFEST_FILE}"
}

if [ "${HERDR_VERSION}" = "latest" ]; then
    resolved="$(manifest_version || true)"
    if [ -z "${resolved}" ]; then
        # Fallback: the releases/latest page redirects to .../tag/v<X.Y.Z>, so
        # the tag shows up in curl's effective URL. Preferred over the GitHub
        # REST API, whose unauthenticated 60 req/h per-IP limit is easy to hit
        # on shared CI runners.
        echo "Falling back to the GitHub releases/latest redirect to resolve the newest release..."
        resolved="$(curl -fsSLI -o /dev/null -w '%{url_effective}' "${RELEASES_REPO}/releases/latest" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+$' || true)"
        resolved="${resolved#v}"
    fi
    if [ -z "${resolved}" ]; then
        echo "ERROR: could not resolve the latest herdr release. Pin an exact version via the 'version' option instead."
        exit 1
    fi
    HERDR_VERSION="${resolved}"
fi

echo "Installing herdr ${HERDR_VERSION} (${TARGET})..."

tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"; rm -f "${MANIFEST_FILE}"' EXIT

# The Linux release asset is a bare executable, not an archive.
ASSET_URL="${RELEASES_REPO}/releases/download/v${HERDR_VERSION}/herdr-${TARGET}"
if ! curl -fsSL --retry 3 --connect-timeout 10 --max-time 300 -o "${tmpdir}/herdr" "${ASSET_URL}"; then
    echo "ERROR: could not download ${ASSET_URL}."
    echo "       Check that herdr ${HERDR_VERSION} exists and publishes a ${TARGET} asset:"
    echo "       ${RELEASES_REPO}/releases"
    exit 1
fi

# Verify the download against upstream's published checksum. Releases before
# 0.8.0 publish none, so a pinned older version installs unverified rather
# than failing the build - the option would otherwise be unusable.
EXPECTED_SHA256="$(manifest_sha256 "${HERDR_VERSION}" "${TARGET}" || true)"
if [ -n "${EXPECTED_SHA256}" ]; then
    ACTUAL_SHA256="$(sha256sum < "${tmpdir}/herdr" | awk '{ print $1 }')"
    if [ "${ACTUAL_SHA256}" != "${EXPECTED_SHA256}" ]; then
        echo "ERROR: checksum mismatch for herdr-${TARGET} v${HERDR_VERSION}."
        echo "       expected ${EXPECTED_SHA256}"
        echo "       actual   ${ACTUAL_SHA256}"
        exit 1
    fi
    echo "Verified SHA-256 ${EXPECTED_SHA256}."
elif [ "${MANIFEST_OK}" != "true" ]; then
    # Do not claim upstream publishes no checksum when we simply could not read
    # the manifest - the two cases need different answers from whoever reads
    # this log.
    echo "WARNING: the release manifest was unreachable, so herdr ${HERDR_VERSION} (${TARGET}) could NOT be checksum-verified."
    echo "         This is a network failure, not a missing upstream checksum. Re-run the build to verify."
else
    echo "WARNING: upstream publishes no SHA-256 for herdr ${HERDR_VERSION} (${TARGET}) - installing unverified."
fi

install -m 0755 "${tmpdir}/herdr" "${INSTALL_DIR}/herdr"

# --- remote user configuration ---------------------------------------------

# Resolve the remote user's home. _REMOTE_USER_HOME is supplied by the dev
# container CLI; fall back to the passwd entry for standalone/docker builds.
if [ -z "${TARGET_USER_HOME}" ]; then
    TARGET_USER_HOME="$(getent passwd "${TARGET_USER}" 2>/dev/null | cut -d: -f6 || true)"
fi
if [ -z "${TARGET_USER_HOME}" ]; then
    TARGET_USER_HOME="$([ "${TARGET_USER}" = "root" ] && echo /root || echo "/home/${TARGET_USER}")"
fi
TARGET_GROUP="$(id -gn "${TARGET_USER}" 2>/dev/null || echo "${TARGET_USER}")"

CONFIG_DIR="${TARGET_USER_HOME}/.config/herdr"
CONFIG_FILE="${CONFIG_DIR}/config.toml"

if [ "${CONFIGURE_DEFAULTS}" = "true" ]; then
    if [ -e "${CONFIG_FILE}" ]; then
        echo "Leaving the existing ${CONFIG_FILE} untouched."
    else
        mkdir -p "${CONFIG_DIR}"
        # herdr layers this file over its own built-in defaults, so it only
        # needs to carry the keys this Feature manages - every key left out
        # keeps upstream's default, including keys added by future releases.
        cat > "${CONFIG_FILE}" <<EOF
##############################################################################
# Generated by the 'herdr' Dev Container Feature.
# https://github.com/bugrasan/devcontainers-features
#
# This file is intentionally PARTIAL: herdr loads its built-in defaults first
# and then applies this file on top, so anything not listed here keeps
# upstream's default. Edit it freely - this Feature never overwrites an
# existing config file.
#
# Print the full commented default config with: herdr --default-config
# Full reference: https://herdr.dev/docs/config-reference/
##############################################################################

#-- Skip the first-run notification setup. A dev container is rebuilt from
#-- scratch, so the wizard would greet the user on every rebuild.
onboarding = false

[update]
#-- Dev containers are disposable and herdr is installed by this Feature, not
#-- by herdr's own installer, so both background calls to herdr.dev are noise:
#-- 'herdr update' cannot manage this install, and the agent-detection
#-- manifest that ships with the pinned binary is the one we want.
#-- Set the Feature's 'configureDefaults' option to false for upstream
#-- behaviour. 'channel' is deliberately left unset so it keeps its default.
version_check = false
manifest_check = false
EOF
        chmod 0644 "${CONFIG_FILE}"
        # ~/.config may not have existed before this Feature ran.
        chown "${TARGET_USER}:${TARGET_GROUP}" "${TARGET_USER_HOME}/.config" 2>/dev/null || true
        chown -R "${TARGET_USER}:${TARGET_GROUP}" "${CONFIG_DIR}" 2>/dev/null || true
        echo "Wrote ${CONFIG_FILE} for user '${TARGET_USER}'."
    fi
fi

# --- agent skill ------------------------------------------------------------

if [ "${INSTALL_SKILL}" = "true" ]; then
    SKILL_DIR="${TARGET_USER_HOME}/.claude/skills/herdr"
    # 'herdr --skill' prints the copy bundled with THIS binary, so the skill
    # always documents the CLI that is actually installed.
    if "${INSTALL_DIR}/herdr" --skill > "${tmpdir}/SKILL.md" 2>/dev/null && [ -s "${tmpdir}/SKILL.md" ]; then
        mkdir -p "${SKILL_DIR}"
        install -m 0644 "${tmpdir}/SKILL.md" "${SKILL_DIR}/SKILL.md"
        chown "${TARGET_USER}:${TARGET_GROUP}" "${TARGET_USER_HOME}/.claude" 2>/dev/null || true
        chown -R "${TARGET_USER}:${TARGET_GROUP}" "${TARGET_USER_HOME}/.claude/skills" 2>/dev/null || true
        echo "Installed the herdr agent skill to ${SKILL_DIR}/SKILL.md."
    else
        echo "WARNING: 'herdr --skill' is unavailable in herdr ${HERDR_VERSION} - skipping the agent skill."
    fi
fi

# --- shell completions ------------------------------------------------------

if [ "${INSTALL_COMPLETIONS}" = "true" ]; then
    # 'herdr completion' only exists from 0.7.1 onwards. Generate into the temp
    # directory first: an older pinned version must warn and carry on rather
    # than fail the build, and a failed run must not truncate a completion file
    # that is already there.
    if "${INSTALL_DIR}/herdr" completion bash > "${tmpdir}/herdr.bash" 2>/dev/null &&
        "${INSTALL_DIR}/herdr" completion zsh > "${tmpdir}/_herdr" 2>/dev/null &&
        [ -s "${tmpdir}/herdr.bash" ] && [ -s "${tmpdir}/_herdr" ]; then
        # Both are standard system-wide locations, picked up without editing any
        # shell rc file: bash-completion lazy-loads by command name, and
        # /usr/local/share/zsh/site-functions is on zsh's compiled-in fpath.
        mkdir -p "${BASH_COMPLETION_DIR}" "${ZSH_COMPLETION_DIR}"
        install -m 0644 "${tmpdir}/herdr.bash" "${BASH_COMPLETION_DIR}/herdr"
        install -m 0644 "${tmpdir}/_herdr" "${ZSH_COMPLETION_DIR}/_herdr"
        echo "Installed bash and zsh completions."
    else
        echo "WARNING: 'herdr completion' is unavailable in herdr ${HERDR_VERSION} - skipping shell completions."
    fi
fi

# Only clean up what we caused - leave the image's apt state alone otherwise.
if [ "${APT_UPDATED}" = "true" ]; then
    apt-get clean
    rm -rf /var/lib/apt/lists/*
fi

"${INSTALL_DIR}/herdr" --version

echo "Done! herdr ${HERDR_VERSION} installed as '${INSTALL_DIR}/herdr' for remote user '${TARGET_USER}'."
