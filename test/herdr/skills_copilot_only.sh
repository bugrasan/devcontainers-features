#!/bin/bash

# Scenario: both skills on, Claude Code off. Each skill must land in Copilot
# CLI's personal skills directory only, owned by the remote user.

set -e
source dev-container-features-test-lib

# Upstream's scripts install to ~/.local/bin and leave PATH alone.
export PATH="${HOME}/.local/bin:${PATH}"

for name in herdr herdr-core; do
    check "${name} skill for Copilot" bash -c "head -3 '${HOME}/.copilot/skills/${name}/SKILL.md' | grep -qx 'name: ${name}'"
    check "${name} skill owned by the remote user" bash -c "test -O '${HOME}/.copilot/skills/${name}/SKILL.md'"
    check "no ${name} skill for Claude Code" bash -c "! test -e '${HOME}/.claude/skills/${name}'"
done

reportResults
