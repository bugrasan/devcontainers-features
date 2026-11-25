#!/bin/bash

# Scenario: disableCoreUpdates: false unsets HERDR_RELEASES_URL in shells only.

set -e
source dev-container-features-test-lib

# Upstream's scripts install to ~/.local/bin and leave PATH alone.
export PATH="${HOME}/.local/bin:${PATH}"

CONFIG="${HOME}/.config/herdr/config.toml"
UNSET='[ -z "${HERDR_RELEASES_URL+set}" ]'

check "opt-out in /etc/profile.d" bash -c "grep -q '^unset HERDR_RELEASES_URL' /etc/profile.d/herdr-core-updates.sh"
check "unset in login bash" bash -lc "${UNSET}"
check "unset in interactive bash" bash -ic "${UNSET}" </dev/null
check "unset in zsh" zsh -c "${UNSET}"
check "opt-out written once" bash -c "test \"\$(grep -c '^unset HERDR_RELEASES_URL' /etc/bash.bashrc)\" = 1"

# disableTuiUpdates keeps its default: the TUI update checks stay off.
check "version check still disabled" bash -c "grep -qx 'version_check = false' '${CONFIG}'"
check "manifest check still disabled" bash -c "grep -qx 'manifest_check = false' '${CONFIG}'"

reportResults
