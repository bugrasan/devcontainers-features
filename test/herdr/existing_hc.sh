#!/bin/bash

# Scenario: an 'hc' command already exists. herdr-core must still install as
# 'herdr-core', the existing 'hc' must stay as it was, and the herdr-core skill
# (which tells agents to run 'hc') must be skipped, though it is on by default.

set -e
source dev-container-features-test-lib

check "herdr-core installed" bash -c "herdr-core --version | grep -qE '^hc [0-9]+\.[0-9]+\.[0-9]+'"
check "existing hc untouched" bash -c "test ! -L /usr/local/bin/hc && hc | grep -qx other-hc"

check "no herdr-core skill for Claude Code" bash -c "! test -e '${HOME}/.claude/skills/herdr-core'"
check "no herdr-core skill for Copilot" bash -c "! test -e '${HOME}/.copilot/skills/herdr-core'"

reportResults
