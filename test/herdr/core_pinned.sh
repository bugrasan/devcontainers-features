#!/bin/bash

# Scenario: a pinned herdr-core (written with a leading 'v') on a minimal base
# image. Upstream's core installer pins through HC_VERSION. Also proves
# 'installCoreSkill: false' writes no skill for either agent.

set -e
source dev-container-features-test-lib

check "pinned herdr-core installed" bash -c "herdr-core --version | grep -qx 'hc 0.1.20'"
check "hc links to herdr-core" bash -c "test \"\$(readlink /usr/local/bin/hc)\" = herdr-core"
check "no herdr-core skill for Claude Code" bash -c "! test -e '${HOME}/.claude/skills/herdr-core'"
check "no herdr-core skill for Copilot" bash -c "! test -e '${HOME}/.copilot/skills/herdr-core'"
check "herdr TUI still installed" bash -c "command -v herdr"

reportResults
