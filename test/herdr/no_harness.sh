#!/bin/bash

# Scenario: both skills on, but neither agent harness. The build must succeed
# and write no skill anywhere.

set -e
source dev-container-features-test-lib

check "herdr installed" bash -c "command -v herdr"
check "herdr-core installed" bash -c "command -v herdr-core"
check "no skill for Claude Code" bash -c "! test -e '${HOME}/.claude/skills/herdr' && ! test -e '${HOME}/.claude/skills/herdr-core'"
check "no skill for Copilot" bash -c "! test -e '${HOME}/.copilot/skills/herdr' && ! test -e '${HOME}/.copilot/skills/herdr-core'"

reportResults
