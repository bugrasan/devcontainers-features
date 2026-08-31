#!/bin/bash

# exit on error
set -e

# variables provided by devcontainer-feature (option names are uppercased)
SUPERFILE_VERSION="${VERSION:-"latest"}"
INSTALL_PREVIEW_TOOLS="${INSTALLPREVIEWTOOLS:-"false"}"
INSTALL_CLIPBOARD_TOOLS="${INSTALLCLIPBOARDTOOLS:-"false"}"
INSTALL_ZOXIDE="${INSTALLZOXIDE:-"false"}"
CONFIGURE_DEFAULTS="${CONFIGUREDEFAULTS:-"true"}"
NERDFONT="${NERDFONT:-"true"}"
CD_ON_QUIT="${CDONQUIT:-"false"}"
CREATE_ALIAS="${CREATEALIAS:-"true"}"

# The 'install.sh' entrypoint script is always executed as the root user.
# For more details, see https://containers.dev/implementors/features#user-env-var
TARGET_USER="${_REMOTE_USER:-root}"
TARGET_USER_HOME="${_REMOTE_USER_HOME:-}"

RELEASES_REPO="https://github.com/yorukot/superfile"
INSTALL_DIR="/usr/local/bin"
SHARE_DIR="/usr/local/share/superfile"
RC_MARKER="# >>> superfile devcontainer feature (cd_on_quit) >>>"
RC_MARKER_END="# <<< superfile devcontainer feature (cd_on_quit) <<<"

APT_UPDATED="false"

# Install packages via apt, running 'apt-get update' at most once. Package
# lists are cleaned up at the end of the script, but only if we touched apt.
apt_install() {
    # noninteractive matters: some of the optional tools pull in packages
    # (tzdata via ffmpeg, for one) that would otherwise stop and prompt,
    # hanging the image build forever.
    export DEBIAN_FRONTEND=noninteractive
    if [ "${APT_UPDATED}" != "true" ]; then
        apt-get update -y
        APT_UPDATED="true"
    fi
    apt-get -y install --no-install-recommends "$@"
}

# Ensure curl exists - minimal base images (debian:latest, ubuntu:latest)
# don't ship it, unlike mcr.microsoft.com/devcontainers/base images.
if ! command -v curl >/dev/null 2>&1; then
    apt_install ca-certificates curl
fi

# Map machine architecture to the release asset naming
# (superfile-linux-v<ver>-<arch>.tar.gz). Upstream's release script builds
# linux/darwin/windows for amd64 and arm64 only.
case "$(uname -m)" in
    x86_64 | amd64) ARCH="amd64" ;;
    aarch64 | arm64 | armv8*) ARCH="arm64" ;;
    *)
        echo "ERROR: unsupported architecture '$(uname -m)' - superfile publishes linux amd64 and arm64 binaries only."
        exit 1
        ;;
esac

# Accept both '1.6.0' and 'v1.6.0' for the pinned case.
SUPERFILE_VERSION="${SUPERFILE_VERSION#v}"

# Resolve 'latest' to a concrete version WITHOUT the GitHub REST API where
# possible: the releases/latest page redirects to .../releases/tag/v<X.Y.Z>,
# and following it with curl exposes the tag in the effective URL. This
# avoids the unauthenticated api.github.com rate limit (60 req/h per IP),
# which is easy to hit on shared CI runners. The API is kept as a fallback
# for environments that block the HTML endpoint but allow the API.
if [ "${SUPERFILE_VERSION}" = "latest" ]; then
    tag="$(curl -fsSLI -o /dev/null -w '%{url_effective}' "${RELEASES_REPO}/releases/latest" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+$' || true)"
    if [ -z "${tag}" ]; then
        echo "Falling back to the GitHub API to resolve the latest release..."
        tag="$(curl -fsSL "https://api.github.com/repos/yorukot/superfile/releases/latest" | grep -oE '"tag_name":\s*"v[0-9]+\.[0-9]+\.[0-9]+"' | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' || true)"
    fi
    if [ -z "${tag}" ]; then
        echo "ERROR: could not resolve the latest superfile release. Pin an exact version via the 'version' option instead."
        exit 1
    fi
    SUPERFILE_VERSION="${tag#v}"
fi

echo "Installing superfile ${SUPERFILE_VERSION} (linux/${ARCH})..."

ASSET="superfile-linux-v${SUPERFILE_VERSION}-${ARCH}"

tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT
mkdir -p "${tmpdir}/extract"
curl -fsSL -o "${tmpdir}/superfile.tar.gz" \
    "${RELEASES_REPO}/releases/download/v${SUPERFILE_VERSION}/${ASSET}.tar.gz"
# Upstream cuts releases on macOS, so the archives carry Apple xattr headers
# that GNU tar warns about noisily. Suppress that when the flag is supported.
TAR_OPTS=()
if tar --warning=no-unknown-keyword --version >/dev/null 2>&1; then
    TAR_OPTS+=(--warning=no-unknown-keyword)
fi
tar "${TAR_OPTS[@]}" -xzf "${tmpdir}/superfile.tar.gz" -C "${tmpdir}/extract"

# Upstream's release script tars the build directory, so the binary currently
# lands at ./dist/<asset>/spf inside the archive. Locate it instead of
# hardcoding that layout, so a future repackaging upstream doesn't break us.
SPF_BIN="$(find "${tmpdir}/extract" -type f -name spf -print -quit)"
if [ -z "${SPF_BIN}" ]; then
    echo "ERROR: no 'spf' binary found inside ${ASSET}.tar.gz - upstream may have changed the archive layout."
    exit 1
fi

install -m 0755 "${SPF_BIN}" "${INSTALL_DIR}/spf"

# Upstream only ever installs the command as 'spf'; 'superfile' is the name
# people look for, so expose both by default.
if [ "${CREATE_ALIAS}" = "true" ]; then
    ln -sf "${INSTALL_DIR}/spf" "${INSTALL_DIR}/superfile"
elif [ -L "${INSTALL_DIR}/superfile" ] && [ "$(readlink "${INSTALL_DIR}/superfile")" = "${INSTALL_DIR}/spf" ]; then
    # Only ever clean up the symlink this Feature created - never touch some
    # other 'superfile' a different layer may have put there.
    rm -f "${INSTALL_DIR}/superfile"
fi

# --- optional tools superfile shells out to --------------------------------

if [ "${INSTALL_PREVIEW_TOOLS}" = "true" ]; then
    echo "Installing preview tools (ffmpeg, poppler-utils, exiftool, bat)..."
    # exiftool ships as libimage-exiftool-perl on Debian/Ubuntu.
    apt_install ffmpeg poppler-utils libimage-exiftool-perl bat
    # On Debian/Ubuntu the bat package installs the binary as 'batcat' (the
    # 'bat' name is taken by bacula-console-qt), but superfile invokes 'bat'.
    if ! command -v bat >/dev/null 2>&1 && command -v batcat >/dev/null 2>&1; then
        ln -sf "$(command -v batcat)" "${INSTALL_DIR}/bat"
    fi
fi

if [ "${INSTALL_CLIPBOARD_TOOLS}" = "true" ]; then
    echo "Installing clipboard / open tools (xdg-utils, xclip, wl-clipboard)..."
    apt_install xdg-utils xclip wl-clipboard
fi

if [ "${INSTALL_ZOXIDE}" = "true" ]; then
    echo "Installing zoxide..."
    apt_install zoxide
fi

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

CONFIG_DIR="${TARGET_USER_HOME}/.config/superfile"
CONFIG_FILE="${CONFIG_DIR}/config.toml"

if [ "${CONFIGURE_DEFAULTS}" = "true" ]; then
    if [ -e "${CONFIG_FILE}" ]; then
        echo "Leaving the existing ${CONFIG_FILE} untouched."
    else
        # Plugin toggles are only switched on when this Feature actually
        # installed the tool they require, so the config never references a
        # binary that isn't there.
        CFG_METADATA="false"
        CFG_CODE_PREVIEWER='""'
        CFG_ZOXIDE="false"
        if [ "${INSTALL_PREVIEW_TOOLS}" = "true" ]; then
            CFG_METADATA="true"
            CFG_CODE_PREVIEWER='"bat"'
        fi
        if [ "${INSTALL_ZOXIDE}" = "true" ]; then
            CFG_ZOXIDE="true"
        fi

        mkdir -p "${CONFIG_DIR}"
        # superfile merges this file over its own built-in defaults, so it
        # only needs to carry the keys this Feature manages - every key left
        # out keeps upstream's default, including keys added by future
        # superfile releases. 'ignore_missing_fields' silences the warning
        # that a deliberately partial config would otherwise print on start.
        cat > "${CONFIG_FILE}" <<EOF
##############################################################################
# Generated by the 'superfile' Dev Container Feature.
# https://github.com/bugrasan/devcontainers-features
#
# This file is intentionally PARTIAL: superfile loads its built-in defaults
# first and then applies this file on top, so anything not listed here keeps
# upstream's default. Edit it freely - superfile only writes a config file
# when none exists, and this Feature never overwrites an existing one.
#
# Full reference: https://superfile.dev/configure/superfile-config/
##############################################################################

#-- Don't warn about the fields this partial config leaves out.
ignore_missing_fields = true

#-- Dev containers are disposable, so the 24h "is there a newer superfile?"
#-- call to the GitHub API (and its update nag) is just noise. Set the
#-- Feature's 'configureDefaults' option to false to get upstream behaviour.
auto_check_update = false

#-- Nerd Font glyphs. The terminal font lives on the host, not in this
#-- container, so turn this off (Feature option 'nerdfont') if your terminal
#-- isn't using a Nerd Font-patched font and you see tofu boxes.
nerdfont = ${NERDFONT}

#-- cd the shell into superfile's last directory on exit. Needs the shell
#-- wrapper this Feature installs (Feature option 'cdOnQuit').
cd_on_quit = ${CD_ON_QUIT}

###############################################################################
#                                   Plugins                                   #
###############################################################################

#-- Detailed metadata. Requires exiftool (Feature option 'installPreviewTools').
metadata = ${CFG_METADATA}

#-- Syntax-highlighted preview via bat, "" for the builtin chroma highlighter.
#-- Requires bat (Feature option 'installPreviewTools').
code_previewer = ${CFG_CODE_PREVIEWER}

#-- Smart directory jumping. Requires zoxide (Feature option 'installZoxide').
zoxide_support = ${CFG_ZOXIDE}
EOF
        chmod 0644 "${CONFIG_FILE}"
        # ~/.config may not have existed before this Feature ran.
        chown "${TARGET_USER}:${TARGET_GROUP}" "${TARGET_USER_HOME}/.config" 2>/dev/null || true
        chown -R "${TARGET_USER}:${TARGET_GROUP}" "${CONFIG_DIR}" 2>/dev/null || true
        echo "Wrote ${CONFIG_FILE} for user '${TARGET_USER}'."
    fi
elif [ "${CD_ON_QUIT}" = "true" ]; then
    echo "NOTE: cdOnQuit installs the shell wrapper, but 'cd_on_quit = true' could not be set"
    echo "      because configureDefaults is false - set it yourself in ${CONFIG_FILE}."
fi

# --- cd on quit shell wrapper ----------------------------------------------

if [ "${CD_ON_QUIT}" = "true" ]; then
    # Mirrors upstream's cd_on_quit.sh. superfile writes its last directory to
    # SPF_LAST_DIR as a sourceable script when cd_on_quit is enabled; the
    # wrapper sources it after superfile exits, which is the only way a child
    # process can change the parent shell's directory.
    mkdir -p "${SHARE_DIR}"
    cat > "${SHARE_DIR}/cd_on_quit.sh" <<'EOF'
# Shell wrapper for superfile's cd_on_quit, installed by the 'superfile'
# devcontainer Feature. Based on upstream cd_on_quit/cd_on_quit.sh.
spf() {
    export SPF_LAST_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/superfile/lastdir"

    command spf "$@"

    [ ! -f "$SPF_LAST_DIR" ] || {
        . "$SPF_LAST_DIR"
        rm -f -- "$SPF_LAST_DIR" > /dev/null
    }
}
EOF
    chmod 0644 "${SHARE_DIR}/cd_on_quit.sh"

    rc_snippet="${RC_MARKER}
[ -f ${SHARE_DIR}/cd_on_quit.sh ] && . ${SHARE_DIR}/cd_on_quit.sh
${RC_MARKER_END}"

    rc_written="false"
    for rc in "${TARGET_USER_HOME}/.bashrc" "${TARGET_USER_HOME}/.zshrc"; do
        [ -f "${rc}" ] || continue
        rc_written="true"
        # postCreate/rebuild can run this more than once - stay idempotent.
        if grep -qF "${RC_MARKER}" "${rc}"; then
            continue
        fi
        printf '\n%s\n' "${rc_snippet}" >> "${rc}"
        echo "Added the cd_on_quit wrapper to ${rc}."
    done

    if [ "${rc_written}" != "true" ]; then
        printf '%s\n' "${rc_snippet}" >> "${TARGET_USER_HOME}/.bashrc"
        chown "${TARGET_USER}:${TARGET_GROUP}" "${TARGET_USER_HOME}/.bashrc" 2>/dev/null || true
        echo "Created ${TARGET_USER_HOME}/.bashrc with the cd_on_quit wrapper."
    fi
fi

# Only clean up what we caused - leave the image's apt state alone otherwise.
if [ "${APT_UPDATED}" = "true" ]; then
    apt-get clean
    rm -rf /var/lib/apt/lists/*
fi

"${INSTALL_DIR}/spf" --version

echo "Done! superfile ${SUPERFILE_VERSION} installed as '${INSTALL_DIR}/spf' for remote user '${TARGET_USER}'."
