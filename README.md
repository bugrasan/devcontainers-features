# README

currently this repo contains the folling devcontainer features:
- 'structurizr-cli', see [Structurizr-CLI](https://docs.structurizr.com/cli)
- 'twilio-cli', see [Twilio CLI](https://www.twilio.com/docs/twilio-cli)
- 'claude-code', see [Claude Code](https://code.claude.com/docs/en/overview)
- 'pi-dev', see [Pi](https://pi.dev)
- 'speckit', see [GitHub Spec Kit](https://github.com/github/spec-kit)
- 'otel-collector-contrib', see [OpenTelemetry Collector Contrib](https://github.com/open-telemetry/opentelemetry-collector-contrib)
- 'superfile', see [superfile](https://github.com/yorukot/superfile)
- 'herdr', see [herdr](https://github.com/herdrdev/herdr)


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

## superfile
Installs [superfile](https://github.com/yorukot/superfile), a modern terminal
file manager, from its official GitHub release. The binary is installed under
upstream's command name `spf` (add a `superfile` symlink with
`createAlias`). By default it also writes a container-friendly
`~/.config/superfile/config.toml` for the remote user, whose main job is
turning off superfile's 24h auto-update check so a disposable container never
phones home; that config also defaults `nerdfont` to false, since the terminal
font lives on the host - see the [feature README](src/superfile/README.md) for
that, the optional preview/clipboard/zoxide tools and `cd_on_quit` support.
```json
"features": {
    "ghcr.io/bugrasan/devcontainers-features/superfile:1": {}
}
```

## herdr
Installs the [herdr](https://github.com/herdrdev/herdr) TUI (`herdr`) and
[herdr-core](https://github.com/herdrdev/herdr-core) (`hc`), the headless core
that keeps programs and agents running in terminals that outlive the viewer.
Both are installed with upstream's official install scripts, into
`/usr/local/bin`, and both are optional (`installTui`, `installCore`; turning
both off fails the build). The herdr TUI script always installs the latest
release; herdr-core can be pinned with `coreVersion`. By default it also seeds
a container-friendly `~/.config/herdr/config.toml`, adds bash/zsh completions,
and installs the herdr-core agent skill for Claude Code and GitHub Copilot CLI
(herdr's own skill is opt-in). The build must reach `herdr.dev`, `github.com`,
`releases.herdr.dev`, and `raw.githubusercontent.com`. Nothing is started; run
`herdr` to begin or reattach to a session. See the
[feature README](src/herdr/README.md) for the options.
```json
"features": {
    "ghcr.io/bugrasan/devcontainers-features/herdr:2": {}
}
```
