#!/bin/bash

# Scenario: herdr's own skill on, herdr-core's skill off, Copilot off. Only the
# herdr skill may be written, and only for Claude Code.

set -e
source dev-container-features-test-lib

SKILL="${HOME}/.claude/skills/herdr/SKILL.md"
check "herdr skill for Claude Code" bash -c "head -3 '${SKILL}' | grep -qx 'name: herdr'"
check "herdr skill owned by the remote user" bash -c "test -O '${SKILL}'"
# 'herdr --skill' prints the copy bundled with the installed binary, which
# guards itself on HERDR_ENV.
check "herdr skill carries the HERDR_ENV guardrail" bash -c "grep -q 'HERDR_ENV' '${SKILL}'"
check "no herdr skill for Copilot" bash -c "! test -e '${HOME}/.copilot/skills/herdr'"
check "no herdr-core skill for either agent" bash -c "
    ! test -e '${HOME}/.claude/skills/herdr-core' &&
    ! test -e '${HOME}/.copilot/skills/herdr-core'"

reportResults
