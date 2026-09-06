#!/bin/bash

# Scenario: an exact version on a minimal base image, with every optional
# extra switched off. Covers the pinned-download path and proves each
# 'true'-by-default option really is opt-out.

set -e
source dev-container-features-test-lib

check "herdr is on PATH" bash -c "command -v herdr"
check "pinned version installed" bash -c "herdr --version | grep -qx 'herdr 0.8.2'"
check "herdr status runs" bash -c "herdr status"

# configureDefaults: false - the Feature must stay out of the user's home.
check "no config written" bash -c "! test -e '${HOME}/.config/herdr/config.toml'"
# Without the generated config herdr keeps its own default, which is 'stable'.
check "upstream update channel intact" bash -c "herdr status | grep -q 'channel: stable'"

# installSkill: false
check "no agent skill written" bash -c "! test -e '${HOME}/.claude/skills/herdr/SKILL.md'"

# installCompletions: false
check "no bash completion written" bash -c "! test -e /usr/share/bash-completion/completions/herdr"
check "no zsh completion written" bash -c "! test -e /usr/local/share/zsh/site-functions/_herdr"

reportResults
