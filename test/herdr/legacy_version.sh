#!/bin/bash

# Scenario: a pinned release that predates parts of today's CLI. herdr gained
# 'completion' in 0.7.1 and '--skill' after 0.7.5, and publishes no SHA-256
# before 0.8.0. All three must degrade to a warning - a build that dies because
# an old version lacks an optional extra would make the 'version' option a trap.

set -e
source dev-container-features-test-lib

check "pinned legacy version installed" bash -c "herdr --version | grep -qx 'herdr 0.7.0'"

# Options left at their 'true' default, but unsupported by this release.
check "agent skill skipped, not fatal" bash -c "! test -e '${HOME}/.claude/skills/herdr/SKILL.md'"
check "completions skipped, not fatal" bash -c "
    ! test -e /usr/share/bash-completion/completions/herdr &&
    ! test -e /usr/local/share/zsh/site-functions/_herdr"

# configureDefaults does not depend on the herdr version, so it still applies.
check "config still generated" bash -c "grep -qx 'onboarding = false' '${HOME}/.config/herdr/config.toml'"

reportResults
