#!/bin/bash

# Scenario: a pinned herdr-core (written with a leading 'v') on a minimal base
# image that lacks curl. Covers the per-version manifest path, and proves
# 'installSkill: false' also covers the herdr-core skill.

set -e
source dev-container-features-test-lib

check "pinned herdr-core installed" bash -c "herdr-core --version | grep -qx 'hc 0.1.20'"
check "hc links to herdr-core" bash -c "test \"$(readlink /usr/local/bin/hc)\" = herdr-core"
check "no herdr-core skill written" bash -c "! test -e '${HOME}/.claude/skills/herdr-core/SKILL.md'"
check "herdr still installed" bash -c "herdr --version | grep -qx 'herdr 0.8.2'"

reportResults
