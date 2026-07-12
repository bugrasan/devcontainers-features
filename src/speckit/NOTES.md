## Prerequisites

This Feature installs the `specify` CLI with `uv tool install` and does **not**
install its runtime dependencies. Both must already be present:

- **uv** — used to install (and self-upgrade) the CLI.
- **Python 3.11+** — required by spec-kit.

On the pre-baked `devcontainer-base-ai` image both are already provided (uv from
the Dockerfile, Python from the `python` Feature). On other images make sure uv
and Python 3.11+ are on `PATH` first: Python via the `python` Feature, and uv
via your base image or Dockerfile (there is no first-party uv Feature).

```json
"features": {
    "ghcr.io/devcontainers/features/python:1": { "version": "3.12" },
    "ghcr.io/bugrasan/devcontainers-features/speckit:1": {}
}
```

The binary is installed under the remote user's `~/.local/bin` and symlinked to
`/usr/local/bin/specify`, so `specify` is on `PATH` for every shell.

> **FIXME:** once uv is available as its own Dev Container Feature, switch this
> Feature's `installsAfter` (ordering-only) to `dependsOn` so python + uv are
> declared as real, auto-installed dependencies.

## Auto-update (opt-in, currently disabled)

A copilot-cli-style startup self-upgrade is included but **commented out** in
both `install.sh` and `devcontainer-feature.json`. When enabled, installing with
`version: latest` writes `/etc/devcontainer-speckit/auto-update`, and a
`postStartCommand` runs `specify self upgrade` on each container start (which,
for a `uv tool` install, re-fetches the newest release even from a pinned tag).
Enable it by uncommenting both halves.
