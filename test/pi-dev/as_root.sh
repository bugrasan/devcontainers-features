#!/bin/bash

# Executed against the 'as_root' scenario in scenarios.json: the same setup as
# 'with_node', but with remote user root, so the link points into /root.

set -e

source dev-container-features-test-lib

check "pi is on PATH" bash -c "command -v pi"
check "pi links to the managed launcher" bash -c "test \"\$(readlink /usr/local/bin/pi)\" = '${HOME}/.pi/agent/bin/pi'"
check "pi --version" bash -c "pi --version"

reportResults
