#!/bin/bash

# Scenario: disableTuiUpdates: false drops only the config's [update] section.

set -e
source dev-container-features-test-lib

# Upstream's scripts install to ~/.local/bin and leave PATH alone.
export PATH="${HOME}/.local/bin:${PATH}"

CONFIG="${HOME}/.config/herdr/config.toml"

check "config copied" bash -c "test -f '${CONFIG}'"
check "onboarding still disabled" bash -c "grep -qx 'onboarding = false' '${CONFIG}'"
check "no [update] section" bash -c "! grep -q '^\[update\]' '${CONFIG}'"
check "no update keys" bash -c "! grep -qE '^(version_check|manifest_check)' '${CONFIG}'"
check "herdr accepts the config" bash -c "herdr status | grep -q 'channel: stable'"

# disableCoreUpdates keeps its default: the hc workaround is still active.
check "HERDR_RELEASES_URL still empty" bash -c '[ "${HERDR_RELEASES_URL+set}" = set ] && [ -z "${HERDR_RELEASES_URL}" ]'
check "no hc opt-out written" bash -c "! test -e /etc/profile.d/herdr-core-updates.sh"

reportResults
