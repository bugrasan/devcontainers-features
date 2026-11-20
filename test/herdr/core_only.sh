#!/bin/bash

# Scenario: 'installTui: false' installs herdr-core alone. Nothing that belongs
# to the herdr TUI - binary, config, skill or completions - may be written.

set -e
source dev-container-features-test-lib

# Upstream's scripts install to ~/.local/bin and leave PATH alone.
export PATH="${HOME}/.local/bin:${PATH}"

check "herdr-core installed" bash -c "herdr-core --version | grep -qE '^hc [0-9]+\\.[0-9]+\\.[0-9]+'"
check "herdr-core skill for Claude Code" bash -c "test -f '${HOME}/.claude/skills/herdr-core/SKILL.md'"
check "herdr-core skill for Copilot" bash -c "test -f '${HOME}/.copilot/skills/herdr-core/SKILL.md'"

check "no herdr TUI binary" bash -c "! test -e '${HOME}/.local/bin/herdr'"
check "no herdr config" bash -c "! test -e '${HOME}/.config/herdr'"
check "no herdr skill" bash -c "! test -e '${HOME}/.claude/skills/herdr' && ! test -e '${HOME}/.copilot/skills/herdr'"
check "no herdr completions" bash -c "
    ! test -e /usr/share/bash-completion/completions/herdr &&
    ! test -e /usr/local/share/zsh/site-functions/_herdr"

reportResults
