#!/bin/bash

# This test file will be executed against one of the scenarios devcontainer.json test that
# includes the 'struturizr' feature with "version": "v2024.01.02" option.

set -e

# NOTE: without the 'v' prefix in version
TEST_VERSION="2024.01.02"

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

# Feature-specific tests
# The 'check' command comes from the dev-container-features-test-lib.
check "execute command" bash -c "structurizr.sh version | grep 'structurizr-cli: ${TEST_VERSION}'"

# Report results
# If any of the checks above exited with a non-zero exit code, the test will fail.
reportResults
