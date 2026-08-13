#!/bin/bash

# exit on error
set -e

# variables provided by devcontainer-feature (option names are uppercased)
OTELCOL_VERSION="${VERSION:-"latest"}"
AUTO_START="${AUTOSTART:-"true"}"
GRPC_PORT="${GRPCPORT:-"4317"}"
HTTP_PORT="${HTTPPORT:-"4318"}"
CUSTOM_CONFIG_PATH="${CONFIGPATH:-""}"

# The 'install.sh' entrypoint script is always executed as the root user.
# For more details, see https://containers.dev/implementors/features#user-env-var
TARGET_USER="${_REMOTE_USER:-root}"

RELEASES_REPO="https://github.com/open-telemetry/opentelemetry-collector-releases"
INSTALL_DIR="/usr/local/bin"
SHARE_DIR="/usr/local/share/otel-collector-contrib"
DEFAULT_CONFIG="/etc/otelcol-contrib/config.yaml"

# Ensure curl exists - minimal base images (debian:latest, ubuntu:latest)
# don't ship it, unlike mcr.microsoft.com/devcontainers/base images.
if ! command -v curl >/dev/null 2>&1; then
    apt-get update -y
    apt-get -y install --no-install-recommends ca-certificates curl
fi

# Map machine architecture to the release asset naming
# (otelcol-contrib_<ver>_linux_<arch>.tar.gz). Only amd64/arm64 assets are
# published for linux by the opentelemetry-collector-releases project.
case "$(uname -m)" in
    x86_64) ARCH="amd64" ;;
    aarch64 | armv8*) ARCH="arm64" ;;
    *)
        echo "ERROR: unsupported architecture '$(uname -m)' - otelcol-contrib publishes linux_amd64 and linux_arm64 binaries only."
        exit 1
        ;;
esac

# Resolve 'latest' to a concrete version WITHOUT the GitHub REST API where
# possible: the releases/latest page redirects to .../releases/tag/v<X.Y.Z>,
# and following it with curl exposes the tag in the effective URL. This
# avoids the unauthenticated api.github.com rate limit (60 req/h per IP),
# which is easy to hit on shared CI runners. The API is kept as a fallback
# for environments that block the HTML endpoint but allow the API.
if [ "${OTELCOL_VERSION}" = "latest" ]; then
    tag="$(curl -fsSLI -o /dev/null -w '%{url_effective}' "${RELEASES_REPO}/releases/latest" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+$' || true)"
    if [ -z "${tag}" ]; then
        echo "Falling back to the GitHub API to resolve the latest release..."
        tag="$(curl -fsSL "https://api.github.com/repos/open-telemetry/opentelemetry-collector-releases/releases/latest" | grep -oE '"tag_name":\s*"v[0-9]+\.[0-9]+\.[0-9]+"' | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' || true)"
    fi
    if [ -z "${tag}" ]; then
        echo "ERROR: could not resolve the latest otelcol-contrib release. Pin an exact version via the 'version' option instead."
        exit 1
    fi
    OTELCOL_VERSION="${tag#v}"
fi

echo "Installing otelcol-contrib ${OTELCOL_VERSION} (linux/${ARCH})..."

tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT
curl -fsSL -o "${tmpdir}/otelcol-contrib.tar.gz" \
    "${RELEASES_REPO}/releases/download/v${OTELCOL_VERSION}/otelcol-contrib_${OTELCOL_VERSION}_linux_${ARCH}.tar.gz"
tar -xzf "${tmpdir}/otelcol-contrib.tar.gz" -C "${tmpdir}" otelcol-contrib
install -m 0755 "${tmpdir}/otelcol-contrib" "${INSTALL_DIR}/otelcol-contrib"

# Generate the default config: OTLP receiver (gRPC + HTTP, localhost only -
# nothing needs to reach the collector from outside the container) -> batch
# processor -> azuremonitorexporter for all three signals. The connection
# string is resolved from the environment AT COLLECTOR STARTUP via the
# ${env:...} confmap syntax, so it is never baked into the image.
mkdir -p "$(dirname "${DEFAULT_CONFIG}")"
cat > "${DEFAULT_CONFIG}" <<EOF
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: localhost:${GRPC_PORT}
      http:
        endpoint: localhost:${HTTP_PORT}

processors:
  batch:

exporters:
  azuremonitor:
    connection_string: "\${env:APPLICATIONINSIGHTS_CONNECTION_STRING}"

service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [batch]
      exporters: [azuremonitor]
    metrics:
      receivers: [otlp]
      processors: [batch]
      exporters: [azuremonitor]
    logs:
      receivers: [otlp]
      processors: [batch]
      exporters: [azuremonitor]
EOF
# world-readable so the remote user can run the collector against it
chmod 0644 "${DEFAULT_CONFIG}"

# Effective config: a custom path (validated only at runtime - it may live in
# the workspace mount, which doesn't exist at build time) or the generated one.
if [ -n "${CUSTOM_CONFIG_PATH}" ]; then
    EFFECTIVE_CONFIG="${CUSTOM_CONFIG_PATH}"
else
    EFFECTIVE_CONFIG="${DEFAULT_CONFIG}"
fi

# Startup script wired as this Feature's postStartCommand. It runs on every
# container start AS THE REMOTE USER with remoteEnv applied, so the
# connection string may come from either containerEnv or remoteEnv. Install
# options are baked in here at build time.
mkdir -p "${SHARE_DIR}"
cat > "${SHARE_DIR}/start.sh" <<EOF
#!/bin/bash
# Auto-start hook for the otel-collector-contrib devcontainer Feature.
# Baked in at Feature install time:
AUTO_START="${AUTO_START}"
CONFIG="${EFFECTIVE_CONFIG}"
USING_DEFAULT_CONFIG="$([ -z "${CUSTOM_CONFIG_PATH}" ] && echo true || echo false)"

LOG_FILE="/tmp/otelcol-contrib.log"
PID_FILE="/tmp/otelcol-contrib.pid"

if [ "\${AUTO_START}" != "true" ]; then
    exit 0
fi

# postStartCommand fires on every container (re)start - don't stack instances
if [ -f "\${PID_FILE}" ] && kill -0 "\$(cat "\${PID_FILE}")" 2>/dev/null; then
    echo "otelcol-contrib already running (pid \$(cat "\${PID_FILE}"))."
    exit 0
fi

# The default config resolves \${env:APPLICATIONINSIGHTS_CONNECTION_STRING}
# at collector startup - without it the azuremonitorexporter cannot start,
# so skip (never fail the container start over missing telemetry).
if [ "\${USING_DEFAULT_CONFIG}" = "true" ] && [ -z "\${APPLICATIONINSIGHTS_CONNECTION_STRING}" ]; then
    echo "WARNING: APPLICATIONINSIGHTS_CONNECTION_STRING is not set - not starting otelcol-contrib." | tee -a "\${LOG_FILE}"
    echo "Provide it via containerEnv/remoteEnv (see the otel-collector-contrib Feature README) and restart the container, or run \${0} again." | tee -a "\${LOG_FILE}"
    exit 0
fi

if [ ! -f "\${CONFIG}" ]; then
    echo "WARNING: collector config '\${CONFIG}' not found - not starting otelcol-contrib." | tee -a "\${LOG_FILE}"
    exit 0
fi

echo "Starting otelcol-contrib with config \${CONFIG} (log: \${LOG_FILE})..."
nohup /usr/local/bin/otelcol-contrib --config "\${CONFIG}" >> "\${LOG_FILE}" 2>&1 &
echo \$! > "\${PID_FILE}"
EOF
chmod 0755 "${SHARE_DIR}/start.sh"

"${INSTALL_DIR}/otelcol-contrib" --version

echo "Done! autoStart=${AUTO_START}, config=${EFFECTIVE_CONFIG}, remote user=${TARGET_USER}."
