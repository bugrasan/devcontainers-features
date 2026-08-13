
# otel-collector-contrib (otel-collector-contrib)

Installs the OpenTelemetry Collector Contrib distribution (includes the azuremonitorexporter) and optionally auto-starts it on container start, so OTLP telemetry (e.g. VS Code / Copilot Chat agent telemetry) can be forwarded to Azure Application Insights.

## Example Usage

```json
"features": {
    "ghcr.io/bugrasan/devcontainers-features/otel-collector-contrib:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Version of the otelcol-contrib release to install: 'latest' or an exact version like '0.158.0' (see https://github.com/open-telemetry/opentelemetry-collector-releases/releases). | string | latest |
| autoStart | Start the collector in the background on every container start (via a Feature-contributed postStartCommand, run as the remote user). Startup is skipped with a warning when APPLICATIONINSIGHTS_CONNECTION_STRING is not set and the default config is in use. Set to false to only install the binary. | boolean | true |
| grpcPort | Port the OTLP gRPC receiver listens on (localhost only) in the generated default config. Ignored when configPath is set. | string | 4317 |
| httpPort | Port the OTLP HTTP receiver listens on (localhost only) in the generated default config. Ignored when configPath is set. | string | 4318 |
| configPath | Absolute path (inside the container) to a custom collector config file to use instead of the generated default at /etc/otelcol-contrib/config.yaml. The file only needs to exist at container runtime (e.g. a workspace-mounted path), not at build time. | string | - |

## How it works

- Downloads the [`otelcol-contrib`](https://github.com/open-telemetry/opentelemetry-collector-releases) release binary (linux `amd64`/`arm64`) to `/usr/local/bin/otelcol-contrib`. The contrib distribution ships with the [`azuremonitorexporter`](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/exporter/azuremonitorexporter) built in.
- Generates a default config at `/etc/otelcol-contrib/config.yaml`: OTLP receiver (gRPC on `localhost:4317`, HTTP on `localhost:4318`) → `batch` processor → `azuremonitor` exporter, for traces, metrics and logs.
- With `autoStart` (default `true`), a Feature-contributed `postStartCommand` (`/usr/local/share/otel-collector-contrib/start.sh`) starts the collector in the background on every container start, **as the remote user**. It logs to `/tmp/otelcol-contrib.log` and is idempotent across restarts.

## Providing the Application Insights connection string

The default config resolves `${env:APPLICATIONINSIGHTS_CONNECTION_STRING}` when the collector starts — the secret is never baked into the image. If the variable is unset, startup is **skipped with a warning** (the container still starts fine). Supply it in the consuming `devcontainer.json` via either:

```jsonc
// from the host machine's environment (local VS Code)
"remoteEnv": {
    "APPLICATIONINSIGHTS_CONNECTION_STRING": "${localEnv:APPLICATIONINSIGHTS_CONNECTION_STRING}"
}
```

or

```jsonc
"containerEnv": {
    "APPLICATIONINSIGHTS_CONNECTION_STRING": "${localEnv:APPLICATIONINSIGHTS_CONNECTION_STRING}"
}
```

Both work with the auto-start hook (`postStartCommand` runs with `remoteEnv` applied). Alternatives: a `runArgs: ["--env-file", ".devcontainer/.env"]` file (keep it out of git), or [Codespaces/dev container secrets](https://docs.github.com/en/codespaces/managing-your-codespaces/managing-your-account-specific-secrets-for-github-codespaces). After setting the variable, rebuild/restart the container — or run `/usr/local/share/otel-collector-contrib/start.sh` manually.

## Wiring up VS Code / Copilot Chat agent telemetry

VS Code can export agent traces, metrics and events via OpenTelemetry (see [Monitor agent usage with OpenTelemetry](https://code.visualstudio.com/docs/agents/guides/monitoring-agents)). OTel emission is **off by default** in VS Code; this Feature deliberately does not force it on. Enable it in the consuming `devcontainer.json` with the recommended settings:

```jsonc
"customizations": {
    "vscode": {
        "settings": {
            "github.copilot.chat.otel.enabled": true,
            "github.copilot.chat.otel.exporterType": "otlp-http",
            "github.copilot.chat.otel.otlpEndpoint": "http://localhost:4318"
            // optional, captures full prompt/response content:
            // "github.copilot.chat.otel.captureContent": true
        }
    }
}
```

Use `"otlp-grpc"` + `"http://localhost:4317"` if you prefer gRPC. Adjust the port if you changed `httpPort`/`grpcPort`.

Equivalent environment variables (take precedence over settings) can be set via `containerEnv` instead — this Feature does **not** set them by default:

```jsonc
"containerEnv": {
    "COPILOT_OTEL_ENABLED": "true",
    "OTEL_EXPORTER_OTLP_ENDPOINT": "http://localhost:4318",
    "OTEL_EXPORTER_OTLP_PROTOCOL": "http/protobuf"
}
```

## Customizing

- `grpcPort` / `httpPort` change the listen ports in the generated config (localhost only).
- `configPath` points the auto-start hook at your own collector config instead of the generated one (e.g. a workspace-mounted file — it only needs to exist at runtime). Validate it with `otelcol-contrib validate --config <path>`.
- `autoStart: false` installs the binary and config only; start it yourself with `/usr/local/share/otel-collector-contrib/start.sh` or `otelcol-contrib --config /etc/otelcol-contrib/config.yaml`.

## Troubleshooting

- Collector log: `/tmp/otelcol-contrib.log`; pid file: `/tmp/otelcol-contrib.pid`.
- Smoke-test the OTLP HTTP endpoint: `curl -s -o /dev/null -w "%{http_code}" -X POST -H 'Content-Type: application/json' -d '{"resourceSpans":[]}' http://localhost:4318/v1/traces` → `200`.


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/bugrasan/devcontainers-features/blob/main/src/otel-collector-contrib/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
