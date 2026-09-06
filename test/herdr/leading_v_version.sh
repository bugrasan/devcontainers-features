#!/bin/bash

# Scenario: the 'version' option accepts a leading 'v', matching how upstream
# writes its release tags. It must resolve to the same release as '0.8.2'.

set -e
source dev-container-features-test-lib

check "version with leading v resolves" bash -c "herdr --version | grep -qx 'herdr 0.8.2'"
check "config still generated" bash -c "grep -qx 'onboarding = false' '${HOME}/.config/herdr/config.toml'"

reportResults
