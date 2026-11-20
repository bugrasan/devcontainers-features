#!/bin/bash

# exit on error
set -e

# variables provided by devcontainer-feature (option names are uppercased)
INSTALL_TUI="${INSTALLTUI:-"true"}"
CONFIGURE_DEFAULTS="${CONFIGUREDEFAULTS:-"true"}"
INSTALL_COMPLETIONS="${INSTALLCOMPLETIONS:-"true"}"
INSTALL_TUI_SKILL="${INSTALLTUISKILL:-"false"}"
INSTALL_CORE="${INSTALLCORE:-"true"}"
CORE_VERSION="${COREVERSION:-"latest"}"
INSTALL_CORE_SKILL="${INSTALLCORESKILL:-"true"}"
SKILL_CLAUDE_CODE="${SKILLCLAUDECODE:-"true"}"
SKILL_COPILOT="${SKILLCOPILOT:-"true"}"

# The 'install.sh' entrypoint script is always executed as the root user.
# For more details, see https://containers.dev/implementors/features#user-env-var
TARGET_USER="${_REMOTE_USER:-root}"
TARGET_USER_HOME="${_REMOTE_USER_HOME:-}"

# Upstream's official install scripts, run unchanged. Both default to
# $HOME/.local/bin; the Feature points them at a system-wide directory.
TUI_INSTALL_URL="https://herdr.dev/install.sh"
CORE_INSTALL_URL="https://releases.herdr.dev/core/install.sh"
CORE_SKILL_BASE_URL="https://raw.githubusercontent.com/herdrdev/herdr-core"
INSTALL_DIR="/usr/local/bin"
BASH_COMPLETION_DIR="/usr/share/bash-completion/completions"
ZSH_COMPLETION_DIR="/usr/local/share/zsh/site-functions"

# A Feature that installs nothing is a misconfiguration - fail the build.
if [ "${INSTALL_TUI}" != "true" ] && [ "${INSTALL_CORE}" != "true" ]; then
    echo "ERROR: 'installTui' and 'installCore' are both false - nothing to install."
    exit 1
fi

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

# Bootstrap what upstream's scripts need - minimal base images (debian:latest,
# ubuntu:latest) lack curl, unlike mcr.microsoft.com/devcontainers/base. The
# herdr-core script also unpacks a .tar.gz archive.
MISSING_TOOLS=()
command -v curl >/dev/null 2>&1 || MISSING_TOOLS+=(ca-certificates curl)
command -v sha256sum >/dev/null 2>&1 || MISSING_TOOLS+=(coreutils)
if [ "${INSTALL_CORE}" = "true" ]; then
    command -v tar >/dev/null 2>&1 || MISSING_TOOLS+=(tar)
    command -v gzip >/dev/null 2>&1 || MISSING_TOOLS+=(gzip)
fi
if [ "${#MISSING_TOOLS[@]}" -gt 0 ]; then
    apt_install "${MISSING_TOOLS[@]}"
fi

# Resolve the remote user's home. _REMOTE_USER_HOME is supplied by the dev
# container CLI; fall back to the passwd entry for standalone/docker builds.
if [ -z "${TARGET_USER_HOME}" ]; then
    TARGET_USER_HOME="$(getent passwd "${TARGET_USER}" 2>/dev/null | cut -d: -f6 || true)"
fi
if [ -z "${TARGET_USER_HOME}" ]; then
    TARGET_USER_HOME="$([ "${TARGET_USER}" = "root" ] && echo /root || echo "/home/${TARGET_USER}")"
fi
TARGET_GROUP="$(id -gn "${TARGET_USER}" 2>/dev/null || echo "${TARGET_USER}")"
# The per-user steps below need a home the remote user owns.
if [ ! -d "${TARGET_USER_HOME}" ]; then
    mkdir -p "${TARGET_USER_HOME}"
    chown "${TARGET_USER}:${TARGET_GROUP}" "${TARGET_USER_HOME}" 2>/dev/null || true
fi

tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT

# Download a file, failing the build with a clear message. Upstream's scripts
# are saved first rather than piped into sh, so a failed download can never
# run as an empty or truncated script.
fetch() {
    if ! curl -fsSL --retry 3 --connect-timeout 10 --max-time 60 "$1" -o "$2"; then
        echo "ERROR: could not download $1."
        exit 1
    fi
}

# Agent harnesses that receive the skills: Claude Code reads personal skills
# from ~/.claude/skills, GitHub Copilot CLI from ~/.copilot/skills.
SKILL_HOMES=()
if [ "${SKILL_CLAUDE_CODE}" = "true" ]; then SKILL_HOMES+=(.claude); fi
if [ "${SKILL_COPILOT}" = "true" ]; then SKILL_HOMES+=(.copilot); fi
if [ "${#SKILL_HOMES[@]}" -eq 0 ]; then
    echo "NOTE: 'skillClaudeCode' and 'skillCopilot' are both false - no agent skill is installed."
fi

# Install one SKILL.md as skill <name> for every enabled harness.
install_skill() {
    local name="$1" file="$2" agent_home
    for agent_home in "${SKILL_HOMES[@]}"; do
        mkdir -p "${TARGET_USER_HOME}/${agent_home}/skills/${name}"
        install -m 0644 "${file}" "${TARGET_USER_HOME}/${agent_home}/skills/${name}/SKILL.md"
        # The agent's home may not have existed before this Feature ran.
        chown "${TARGET_USER}:${TARGET_GROUP}" "${TARGET_USER_HOME}/${agent_home}" 2>/dev/null || true
        chown -R "${TARGET_USER}:${TARGET_GROUP}" "${TARGET_USER_HOME}/${agent_home}/skills" 2>/dev/null || true
        echo "Installed the ${name} agent skill to ${TARGET_USER_HOME}/${agent_home}/skills/${name}/SKILL.md."
    done
}

# --- herdr TUI ---------------------------------------------------------------

if [ "${INSTALL_TUI}" = "true" ]; then
    # The command https://herdr.dev/tui/ documents. It always installs the
    # latest release and verifies it against upstream's SHA-256 manifest.
    fetch "${TUI_INSTALL_URL}" "${tmpdir}/herdr-install.sh"
    HERDR_INSTALL_DIR="${INSTALL_DIR}" sh "${tmpdir}/herdr-install.sh"

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
#-- Dev containers are disposable and herdr is installed system-wide when the
#-- image is built, so both background calls to herdr.dev are noise: 'herdr
#-- update', run as this user, cannot replace /usr/local/bin/herdr, and the
#-- agent-detection manifest that ships with the installed binary matches it.
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

    if [ "${INSTALL_COMPLETIONS}" = "true" ]; then
        # Standard system-wide locations, picked up without editing any shell
        # rc file: bash-completion lazy-loads by command name, and
        # /usr/local/share/zsh/site-functions is on zsh's compiled-in fpath.
        mkdir -p "${BASH_COMPLETION_DIR}" "${ZSH_COMPLETION_DIR}"
        "${INSTALL_DIR}/herdr" completion bash > "${BASH_COMPLETION_DIR}/herdr"
        "${INSTALL_DIR}/herdr" completion zsh > "${ZSH_COMPLETION_DIR}/_herdr"
        chmod 0644 "${BASH_COMPLETION_DIR}/herdr" "${ZSH_COMPLETION_DIR}/_herdr"
        echo "Installed bash and zsh completions."
    fi

    if [ "${INSTALL_TUI_SKILL}" = "true" ] && [ "${#SKILL_HOMES[@]}" -gt 0 ]; then
        # 'herdr --skill' prints the skill bundled with the installed binary.
        "${INSTALL_DIR}/herdr" --skill > "${tmpdir}/herdr-SKILL.md"
        install_skill herdr "${tmpdir}/herdr-SKILL.md"
    fi
fi

# --- herdr-core (hc) ---------------------------------------------------------

if [ "${INSTALL_CORE}" = "true" ]; then
    # Upstream's script installs herdr-core plus an 'hc' link (only when no
    # other 'hc' exists) and verifies the archive's SHA-256. It pins through
    # HC_VERSION, a bare version like '0.1.21'; empty means the latest.
    CORE_VERSION="${CORE_VERSION#v}"
    if [ "${CORE_VERSION}" = "latest" ]; then CORE_VERSION=""; fi
    fetch "${CORE_INSTALL_URL}" "${tmpdir}/herdr-core-install.sh"
    # WORKAROUND (docs/tech-debt.md TD-001): with herdr-core already present,
    # upstream's script updates in place - refusing an older version and
    # starting a root core whose state lands in the image. Removing the binary
    # makes it install fresh; an existing 'hc' link resolves again afterwards.
    rm -f "${INSTALL_DIR}/herdr-core"
    HC_VERSION="${CORE_VERSION}" HC_INSTALL_DIR="${INSTALL_DIR}" sh "${tmpdir}/herdr-core-install.sh"

    if [ "${INSTALL_CORE_SKILL}" = "true" ] && [ "${#SKILL_HOMES[@]}" -gt 0 ]; then
        if [ "$(readlink -f "$(command -v hc || true)")" != "${INSTALL_DIR}/herdr-core" ]; then
            # The skill tells agents to run 'hc', which is another program here.
            # Known edge case: a symlinked /usr/local or /usr/local/bin makes
            # the resolved path differ and skips the skill (see NOTES.md).
            echo "WARNING: 'hc' is not herdr-core in this image - skipping the herdr-core agent skill."
        else
            # 'hc --skill' prints a manual without the frontmatter agents need,
            # so take upstream's skill file from the installed version's tag
            # (published from 0.1.13 on); it tells the agent to read that
            # manual from the binary.
            installed="$("${INSTALL_DIR}/herdr-core" --version | awk '{ print $2 }')"
            fetch "${CORE_SKILL_BASE_URL}/v${installed}/skills/herdr-core/SKILL.md" "${tmpdir}/herdr-core-SKILL.md"
            install_skill herdr-core "${tmpdir}/herdr-core-SKILL.md"
        fi
    fi
fi

# Only clean up what we caused - leave the image's apt state alone otherwise.
if [ "${APT_UPDATED}" = "true" ]; then
    apt-get clean
    rm -rf /var/lib/apt/lists/*
fi

echo "Done! Installed for remote user '${TARGET_USER}':"
if [ "${INSTALL_TUI}" = "true" ]; then "${INSTALL_DIR}/herdr" --version; fi
if [ "${INSTALL_CORE}" = "true" ]; then "${INSTALL_DIR}/herdr-core" --version; fi
