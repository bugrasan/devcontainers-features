#!/bin/bash

# Scenario: an 'hc' command already exists. herdr-core must still install as
# 'herdr-core', and the existing 'hc' must stay as it was.

set -e
source dev-container-features-test-lib

check "herdr-core installed" bash -c "herdr-core --version | grep -qE '^hc [0-9]+\.[0-9]+\.[0-9]+'"
check "existing hc untouched" bash -c "test ! -L /usr/local/bin/hc && hc | grep -qx other-hc"

reportResults
