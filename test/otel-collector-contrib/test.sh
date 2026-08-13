#!/bin/bash

# This test file will be executed against an auto-generated devcontainer.json that
# includes the 'otel-collector-contrib' Feature with no options.
#
# For more information, see: https://github.com/devcontainers/cli/blob/main/docs/features/test.md
#
# This test can be run with the following command:
#
#    devcontainer features test \
#                   --features otel-collector-contrib \
#                   --remote-user root \
#                   --skip-scenarios   \
#                   --base-image mcr.microsoft.com/devcontainers/base:ubuntu \
#                   /path/to/this/repo

set -e

# Optional: Import test library bundled with the devcontainer CLI
# See https://github.com/devcontainers/cli/blob/HEAD/docs/features/test.md#dev-container-features-test-lib
# Provides the 'check' and 'reportResults' commands.
source dev-container-features-test-lib

# Feature-specific tests
# The 'check' command comes from the dev-container-features-test-lib. Syntax is...
# check <LABEL> <cmd> [args...]
check "otelcol-contrib is on PATH" bash -c "command -v otelcol-contrib"
check "otelcol-contrib --version" bash -c "otelcol-contrib --version"
check "default config generated" bash -c "test -f /etc/otelcol-contrib/config.yaml"
check "config references azuremonitor exporter" bash -c "grep -q 'azuremonitor:' /etc/otelcol-contrib/config.yaml"
check "start script installed and executable" bash -c "test -x /usr/local/share/otel-collector-contrib/start.sh"

# The generated config resolves ${env:APPLICATIONINSIGHTS_CONNECTION_STRING}
# at collector startup - validate it with a syntactically valid dummy value.
check "config validates" bash -c "APPLICATIONINSIGHTS_CONNECTION_STRING='InstrumentationKey=00000000-0000-0000-0000-000000000000;IngestionEndpoint=https://localhost:9999/' otelcol-contrib validate --config /etc/otelcol-contrib/config.yaml"

# Auto-start must skip gracefully (exit 0 + warning) when the connection
# string is not set, so a missing secret never breaks container startup.
check "start script skips without connection string" bash -c "unset APPLICATIONINSIGHTS_CONNECTION_STRING; /usr/local/share/otel-collector-contrib/start.sh | grep -q 'WARNING: APPLICATIONINSIGHTS_CONNECTION_STRING is not set'"

# End-to-end: start with a dummy connection string, confirm the process comes
# up, is idempotent, and the OTLP HTTP receiver answers on localhost:4318.
check "collector starts and serves OTLP/HTTP" bash -c "
    export APPLICATIONINSIGHTS_CONNECTION_STRING='InstrumentationKey=00000000-0000-0000-0000-000000000000;IngestionEndpoint=https://localhost:9999/'
    /usr/local/share/otel-collector-contrib/start.sh
    sleep 5
    kill -0 \"\$(cat /tmp/otelcol-contrib.pid)\"
    /usr/local/share/otel-collector-contrib/start.sh | grep -q 'already running'
    code=\$(curl -s -o /dev/null -w '%{http_code}' --noproxy '*' -X POST -H 'Content-Type: application/json' -d '{\"resourceSpans\":[]}' http://localhost:4318/v1/traces)
    [ \"\$code\" = '200' ]
"

# Report results
# If any of the checks above exited with a non-zero exit code, the test will fail.
reportResults
