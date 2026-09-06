#!/bin/bash

# Scenario: the image's Dockerfile already wrote a herdr config. The Feature
# must install the binary and still leave that file byte-for-byte alone.

set -e
source dev-container-features-test-lib

CONFIG="${HOME}/.config/herdr/config.toml"

check "herdr installed" bash -c "herdr --version"
check "existing config preserved" bash -c "grep -qx '# hand-written, do not touch' '${CONFIG}'"
check "user's own value kept" bash -c "grep -qx 'onboarding = true' '${CONFIG}'"
check "feature banner not injected" bash -c "! grep -q 'Dev Container Feature' '${CONFIG}'"

# Everything that does not touch the config file still runs.
check "agent skill installed" bash -c "test -f '${HOME}/.claude/skills/herdr/SKILL.md'"
check "bash completion installed" bash -c "test -f /usr/share/bash-completion/completions/herdr"

reportResults
