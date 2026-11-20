#!/bin/bash

# Scenario: the herdr TUI alone on a minimal base image, with every optional
# extra switched off. Covers the curl/ca-certificates bootstrap and proves
# each optional extra really is opt-out.

set -e
source dev-container-features-test-lib

check "herdr is on PATH" bash -c "command -v herdr"
check "herdr status runs" bash -c "herdr status"

# configureDefaults: false - the Feature must stay out of the user's home.
check "no config written" bash -c "! test -e '${HOME}/.config/herdr/config.toml'"
# Without the generated config herdr keeps its own default, which is 'stable'.
check "upstream update channel intact" bash -c "herdr status | grep -q 'channel: stable'"

# installTuiSkill defaults to false.
check "no herdr skill for Claude Code" bash -c "! test -e '${HOME}/.claude/skills/herdr'"
check "no herdr skill for Copilot" bash -c "! test -e '${HOME}/.copilot/skills/herdr'"

# installCompletions: false
check "no bash completion written" bash -c "! test -e /usr/share/bash-completion/completions/herdr"
check "no zsh completion written" bash -c "! test -e /usr/local/share/zsh/site-functions/_herdr"

# installCore: false
check "no herdr-core installed" bash -c "! test -e /usr/local/bin/herdr-core && ! test -e /usr/local/bin/hc"

reportResults
