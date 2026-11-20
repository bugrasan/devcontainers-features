#!/bin/bash

# Scenario: a pinned herdr-core (written with a leading 'v') on a minimal base
# image. Upstream's core installer pins through HC_VERSION, and the skill is
# taken from that pinned version's tag.

set -e
source dev-container-features-test-lib

check "pinned herdr-core installed" bash -c "herdr-core --version | grep -qx 'hc 0.1.20'"
check "hc links to herdr-core" bash -c "test \"\$(readlink /usr/local/bin/hc)\" = herdr-core"
check "pinned herdr-core skill for Claude Code" bash -c "head -3 '${HOME}/.claude/skills/herdr-core/SKILL.md' | grep -qx 'name: herdr-core'"
check "pinned herdr-core skill for Copilot" bash -c "head -3 '${HOME}/.copilot/skills/herdr-core/SKILL.md' | grep -qx 'name: herdr-core'"
check "herdr TUI still installed" bash -c "command -v herdr"

reportResults
