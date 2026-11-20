#!/bin/bash

# Scenario: another program already owns 'hc' (/usr/local/bin/hc). Upstream's
# herdr-core script then installs only 'herdr-core' and adds no 'hc' link.

set -e
source dev-container-features-test-lib

# Upstream's scripts install to ~/.local/bin and leave PATH alone.
export PATH="${HOME}/.local/bin:${PATH}"

check "herdr-core installed" bash -c "herdr-core --version | grep -qE '^hc [0-9]+\.[0-9]+\.[0-9]+'"
check "no hc link added" bash -c "! test -e '${HOME}/.local/bin/hc'"
check "existing hc untouched" bash -c "test ! -L /usr/local/bin/hc && /usr/local/bin/hc | grep -qx other-hc"

reportResults
