# README

currently this repo contains the folling devcontainer features:
- 'structurizr-cli', see [Structurizr-CLI](https://docs.structurizr.com/cli)
- 'twilio-cli', see [Twilio CLI](https://www.twilio.com/docs/twilio-cli)
- 'claude-code', see [Claude Code](https://code.claude.com/docs/en/overview)
- 'pi-dev', see [Pi](https://pi.dev)
- 'speckit', see [GitHub Spec Kit](https://github.com/github/spec-kit)
- 'otel-collector-contrib', see [OpenTelemetry Collector Contrib](https://github.com/open-telemetry/opentelemetry-collector-contrib)


## structurizr-cli
```json
"features": {
    "ghcr.io/bugrasan/devcontainers-features/structurizr-cli:1": {}
}
```

## twilio-cli
```json
"features": {
    "ghcr.io/bugrasan/devcontainers-features/twilio-cli:0": {}
}
```

## claude-code
```json
"features": {
    "ghcr.io/bugrasan/devcontainers-features/claude-code:1": {}
}
```

## pi-dev
Requires Node.js >=22.19.0 and npm - add a Feature that provides them (e.g.
`ghcr.io/devcontainers/features/node`) before this one.
```json
"features": {
    "ghcr.io/bugrasan/devcontainers-features/pi-dev:1": {}
}
```

## otel-collector-contrib
Installs the OpenTelemetry Collector Contrib distribution (`otelcol-contrib`,
includes the `azuremonitorexporter`) with a default OTLP → Azure Application
Insights pipeline, auto-started on container start. Set the
`APPLICATIONINSIGHTS_CONNECTION_STRING` env var (via `remoteEnv`/`containerEnv`)
and enable VS Code's OTel agent telemetry settings - see the
[feature README](src/otel-collector-contrib/README.md) for the recommended
`github.copilot.chat.otel.*` settings and `containerEnv` wiring.
```json
"features": {
    "ghcr.io/bugrasan/devcontainers-features/otel-collector-contrib:1": {}
}
```

## speckit
Installs the `specify` CLI (Spec-Driven Development) via uv. Requires Python
3.11+ and uv to already be present - add the `python` and a `uv` Feature before
this one (both are already provided by the `devcontainer-base-ai` image).
```json
"features": {
    "ghcr.io/bugrasan/devcontainers-features/speckit:1": {}
}
```
