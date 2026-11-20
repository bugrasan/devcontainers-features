# devcontainers-features

This repo publishes [Dev Container Features](https://containers.dev/implementors/features/) to the GitHub Container Registry at `ghcr.io/bugrasan/devcontainers-features`.

## Usage

```json
"features": {
    "ghcr.io/bugrasan/devcontainers-features/<feature>:<tag>": {}
}
```

## Published artifacts

Each Feature artifact holds `devcontainer-feature-<feature>.tgz`, a tarball of `src/<feature>/`.

| Artifact | Tag | Provides |
|---|---|---|
| [`claude-code`](src/claude-code/README.md) | `1` | Claude Code CLI (`claude`) via its native installer; language-server plugins for Python and TypeScript (servers not included); sets `ENABLE_LSP_TOOL=1` |
| [`herdr`](src/herdr/README.md) | `2` | herdr TUI (`herdr`) and herdr-core (`hc`) via upstream's install scripts; container-friendly config; bash/zsh completions; agent skills for Claude Code and GitHub Copilot CLI |
| [`otel-collector-contrib`](src/otel-collector-contrib/README.md) | `1` | OpenTelemetry Collector Contrib (`otelcol-contrib`) with a default config that forwards telemetry to Azure Application Insights; auto-starts when `APPLICATIONINSIGHTS_CONNECTION_STRING` is set |
| [`pi-dev`](src/pi-dev/README.md) | `1` | Pi coding agent CLI (`pi`) via the pi.dev installer; needs Node.js 22.19.0+ and npm |
| [`speckit`](src/speckit/README.md) | `1` | GitHub Spec Kit CLI (`specify`) via uv; needs Python 3.11+ and uv |
| [`structurizr-cli`](src/structurizr-cli/README.md) | `0` | Structurizr CLI (`structurizr.sh`) in `/opt/structurizr-cli`; needs JDK 17+, which the `jdkInstall` option can install |
| [`superfile`](src/superfile/README.md) | `1` | superfile terminal file manager (`spf`); optional preview, clipboard, and zoxide tools; container-friendly config |
| [`twilio-cli`](src/twilio-cli/README.md) | `0` | Twilio CLI (`twilio`) from Twilio's apt repository |
| collection (`ghcr.io/bugrasan/devcontainers-features`) | `latest` | `devcontainer-collection.json`, the metadata index of all Features |

## Maintainer notes

- Tests: `.github/workflows/test.yaml` holds the exact `devcontainer features test` command for each Feature
- Release: a push to `main` that changes `src/**`, or a manual run, runs the tests, publishes to ghcr.io, and commits the regenerated Feature READMEs
- Tech-debt workaround TD-001 (herdr): `src/herdr/install.sh` deletes `/usr/local/bin/herdr-core` before upstream's installer runs
  - Why: with the binary present, the installer runs [`update --from`](https://github.com/herdrdev/herdr-core/blob/c7517808d64f06609e4ecf0db1757005373cc3a3/distribution/install.sh#L109-L111)
  - That refuses an older `coreVersion` and starts herdr-core as root, whose state stays in the image
  - Tests: `existing_core_older` and `existing_core_upgrade`
  - Upstream issue: none yet
  - Remove when upstream's installer offers a non-interactive fresh install
