#!/bin/bash

# Scenario: herdr-core 0.1.21 is already in /usr/local/bin and the OLDER 0.1.20
# is pinned. Upstream's script would take its update path and refuse to go
# back; the Feature's workaround (docs/tech-debt.md TD-001) installs fresh.

set -e
source dev-container-features-test-lib

check "pinned older herdr-core replaced the newer one" bash -c "herdr-core --version | grep -qx 'hc 0.1.20'"
check "hc still links to herdr-core" bash -c "test \"\$(readlink /usr/local/bin/hc)\" = herdr-core"
check "herdr-core skill installed" bash -c "test -f '${HOME}/.claude/skills/herdr-core/SKILL.md'"

reportResults
