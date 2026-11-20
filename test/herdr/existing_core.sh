#!/bin/bash

# Scenario: herdr-core is already in /usr/local/bin and an OLDER coreVersion is
# pinned. The Feature must install fresh: upstream's script would otherwise
# take its update path, refuse the older version, and start a root core whose
# state ends up in the image (see docs/tech-debt.md).

set -e
source dev-container-features-test-lib

check "pinned older herdr-core replaced the newer one" bash -c "herdr-core --version | grep -qx 'hc 0.1.20'"
check "hc still links to herdr-core" bash -c "test \"\$(readlink /usr/local/bin/hc)\" = herdr-core"
check "no core state baked into the image" bash -c "! ls -d /root/.local/state/herdr-core /home/*/.local/state/herdr-core 2>/dev/null"
check "no core left running" bash -c "! pgrep -f '[h]erdr-core serve'"
check "herdr-core skill installed" bash -c "test -f '${HOME}/.claude/skills/herdr-core/SKILL.md'"

reportResults
