#!/bin/bash

# This test file will be executed against an auto-generated devcontainer.json that
# includes the 'herdr' Feature with no options.
#
# For more information, see: https://github.com/devcontainers/cli/blob/main/docs/features/test.md
#
# This test can be run with the following command:
#
#    devcontainer features test \
#                   --features herdr \
#                   --remote-user root \
#                   --skip-scenarios   \
#                   --base-image mcr.microsoft.com/devcontainers/base:ubuntu \
#                   /path/to/this/repo

set -e

# Optional: Import test library bundled with the devcontainer CLI
# See https://github.com/devcontainers/cli/blob/HEAD/docs/features/test.md#dev-container-features-test-lib
# Provides the 'check' and 'reportResults' commands.
source dev-container-features-test-lib

# Upstream's scripts install to ~/.local/bin and leave PATH alone.
export PATH="${HOME}/.local/bin:${PATH}"

CONFIG="${HOME}/.config/herdr/config.toml"
BASH_COMPLETION="/usr/share/bash-completion/completions/herdr"
ZSH_COMPLETION="/usr/local/share/zsh/site-functions/_herdr"
SERVER_LOG="${HOME}/.config/herdr/herdr-server.log"

# Feature-specific tests
# The 'check' command comes from the dev-container-features-test-lib. Syntax is...
# check <LABEL> <cmd> [args...]
check "herdr is on PATH" bash -c "command -v herdr"
check "herdr --version" bash -c "herdr --version"
check "installed at ${HOME}/.local/bin/herdr" bash -c "test -x ${HOME}/.local/bin/herdr"

# herdr's TUI needs a real terminal; these run headlessly and are the sane way
# to exercise the real binary in a test harness.
check "herdr status runs" bash -c "herdr status"
check "herdr --default-config runs" bash -c "herdr --default-config | grep -q '^\[update\]'"

# configureDefaults defaults to true, so the remote user gets a config.
check "config generated for the remote user" bash -c "test -f '${CONFIG}'"
check "config is owned by the remote user" bash -c "test -O '${CONFIG}'"
check "onboarding wizard disabled" bash -c "grep -qx 'onboarding = false' '${CONFIG}'"
check "background version check disabled" bash -c "grep -qx 'version_check = false' '${CONFIG}'"
check "background manifest check disabled" bash -c "grep -qx 'manifest_check = false' '${CONFIG}'"

# 'channel' is deliberately left unset so it keeps upstream's default. Prove
# both halves: absent from the file, still reported as stable by the binary.
check "update channel left at upstream default" bash -c "! grep -q '^channel' '${CONFIG}' && herdr status | grep -q 'channel: stable'"

# The strongest assertion available: start the real server, then read its own
# log. Without this config herdr logs an update check and an agent-manifest
# fetch against herdr.dev within seconds of startup.
check "server accepts the config and stays offline" bash -c '
    rm -f "'"${SERVER_LOG}"'"
    timeout 12 herdr server >/dev/null 2>&1 || true
    test -f "'"${SERVER_LOG}"'" || { echo "server wrote no log"; exit 1; }
    if grep -q "config parse error" "'"${SERVER_LOG}"'"; then
        echo "herdr rejected the generated config:"
        grep -A2 "config parse error" "'"${SERVER_LOG}"'"
        exit 1
    fi
    if grep -qiE "update check|manifest update|herdr\.dev" "'"${SERVER_LOG}"'"; then
        echo "herdr still called home despite the generated config:"
        grep -iE "update check|manifest update|herdr\.dev" "'"${SERVER_LOG}"'"
        exit 1
    fi'

# installTuiSkill defaults to false: no herdr skill for either agent.
check "no herdr skill for Claude Code" bash -c "! test -e '${HOME}/.claude/skills/herdr'"
check "no herdr skill for Copilot" bash -c "! test -e '${HOME}/.copilot/skills/herdr'"

# installCompletions defaults to true.
check "bash completion installed" bash -c "test -f '${BASH_COMPLETION}'"
check "zsh completion installed" bash -c "test -f '${ZSH_COMPLETION}'"
check "bash completion sources and registers herdr" bash -c "
    source '${BASH_COMPLETION}'
    complete -p herdr >/dev/null"
check "zsh completion is a compdef for herdr" bash -c "head -1 '${ZSH_COMPLETION}' | grep -qx '#compdef herdr'"

# installCore defaults to true: herdr-core with its 'hc' link.
check "herdr-core installed at ${HOME}/.local/bin/herdr-core" bash -c "test -x ${HOME}/.local/bin/herdr-core"
check "hc links to herdr-core" bash -c "test \"\$(readlink ${HOME}/.local/bin/hc)\" = herdr-core"
check "hc --version" bash -c "hc --version | grep -qE '^hc [0-9]+\.[0-9]+\.[0-9]+'"
check "hc --help lists its run command" bash -c "hc --help | grep -qE '^ *hc run'"

# installCoreSkill, skillClaudeCode and skillCopilot default to true: the same
# herdr-core skill for both agents, owned by the remote user.
for agent_home in .claude .copilot; do
    CORE_SKILL="${HOME}/${agent_home}/skills/herdr-core/SKILL.md"
    check "herdr-core skill in ~/${agent_home}" bash -c "head -3 '${CORE_SKILL}' | grep -qx 'name: herdr-core'"
    check "herdr-core skill in ~/${agent_home} is owned by the remote user" bash -c "test -O '${CORE_SKILL}'"
done
# The core runs terminals that outlive the caller: prove a real round trip.
check "hc runs a program and returns its output" bash -c "
    export XDG_STATE_HOME=\$(mktemp -d) XDG_RUNTIME_DIR=\$(mktemp -d)
    out=\$(timeout 60 hc run echo herdr-core-ok)
    hc server stop >/dev/null 2>&1 || true
    printf '%s' \"\$out\" | grep -q herdr-core-ok"

# Report results
# If any of the checks above exited with a non-zero exit code, the test will fail.
reportResults
