# devcontainers-features

[Dev Container Features](https://containers.dev/implementors/features/), published as OCI artifacts to `ghcr.io/bugrasan/devcontainers-features`.

## Usage

```json
"features": {
    "ghcr.io/bugrasan/devcontainers-features/<feature>:<tag>": {}
}
```

Each Feature's README lists its options.

## Published artifacts

Each Feature artifact holds `devcontainer-feature-<feature>.tgz`, a tarball of `src/<feature>/`.
The "Installs" column lists what the Feature puts into the container.

| Artifact | Tag | Installs |
|---|---|---|
| [`claude-code`](src/claude-code/README.md) | `1` | Claude Code CLI (`claude`) via its native installer; LSP plugins; sets `ENABLE_LSP_TOOL=1` |
| [`herdr`](src/herdr/README.md) | `2` | herdr TUI (`herdr`) and herdr-core (`hc`) via upstream's install scripts; config; bash/zsh completions; agent skills for Claude Code and GitHub Copilot CLI |
| [`otel-collector-contrib`](src/otel-collector-contrib/README.md) | `1` | OpenTelemetry Collector Contrib (`otelcol-contrib`) with a default OTLP to Azure Application Insights config; starts on container start |
| [`pi-dev`](src/pi-dev/README.md) | `1` | Pi coding agent CLI (`pi`) via the pi.dev installer; needs Node.js >=22.19.0 and npm |
| [`speckit`](src/speckit/README.md) | `1` | GitHub Spec Kit CLI (`specify`) via uv; needs Python 3.11+ and uv |
| [`structurizr-cli`](src/structurizr-cli/README.md) | `0` | Structurizr CLI (`structurizr.sh`) in `/opt/structurizr-cli`; optional JDK; needs JDK 17+ |
| [`superfile`](src/superfile/README.md) | `1` | superfile terminal file manager (`spf`); optional preview, clipboard, and zoxide tools; container-friendly config |
| [`twilio-cli`](src/twilio-cli/README.md) | `0` | Twilio CLI (`twilio`) from Twilio's apt repository |
| collection (`ghcr.io/bugrasan/devcontainers-features`) | `latest` | No Feature; `devcontainer-collection.json`, the metadata index of all Features |

## Maintainer notes

- Test a Feature: `devcontainer features test --features <feature> --base-image mcr.microsoft.com/devcontainers/base:ubuntu .`
- Release: a push to `main` that changes `src/**` runs the tests, publishes to ghcr.io, and commits the regenerated Feature READMEs
- herdr: upstream's TUI install script cannot pin a version; rebuild without cache to update
- Workaround TD-001 (herdr): `src/herdr/install.sh` deletes `/usr/local/bin/herdr-core` before upstream's installer runs
  - Why: with the binary present, the installer runs [`update --from`](https://github.com/herdrdev/herdr-core/blob/c7517808d64f06609e4ecf0db1757005373cc3a3/distribution/install.sh#L109-L111), which refuses an older `coreVersion` and leaves a root core's state in the image
  - Tests: `existing_core_older` and `existing_core_upgrade`
  - Upstream issue: none filed yet
  - Remove when upstream's installer offers a non-interactive fresh install
