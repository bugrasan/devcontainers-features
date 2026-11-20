#!/bin/bash

# Scenario: herdr-core 0.1.20 is already in /usr/local/bin and 'latest' is
# requested. Upstream's update path would succeed here, but it starts a root
# core during the build whose state lands in the image. The Feature's
# workaround (README.md, TD-001) installs fresh, so no state exists.
# Runs as root (remoteUser), since /root is not readable by other users.

set -e
source dev-container-features-test-lib

check "runs as root, so /root is readable" bash -c "test \"\$(id -u)\" = 0"
check "herdr-core upgraded past 0.1.20" bash -c "! herdr-core --version | grep -qx 'hc 0.1.20'"
check "hc still links to herdr-core" bash -c "test \"\$(readlink /usr/local/bin/hc)\" = herdr-core"
check "no core state baked into the image" bash -c "test ! -e /root/.local/state/herdr-core"

reportResults
