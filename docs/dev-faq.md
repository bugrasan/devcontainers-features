# Developer FAQ

## How do I run a Feature's tests?

With the [dev container CLI](https://github.com/devcontainers/cli) and Docker:

```bash
devcontainer features test --features herdr --base-image mcr.microsoft.com/devcontainers/base:ubuntu .
```

This builds the default test (`test/<feature>/test.sh`) and every scenario in `test/<feature>/scenarios.json`. Each scenario runs the script of the same name.

## Why does the herdr Feature delete `/usr/local/bin/herdr-core` before installing it?

Upstream's herdr-core installer updates an existing install in place. In an image build, that refuses older versions and starts a root core whose state lands in the image. Deleting the binary first forces the fresh-install path. See [TD-001](tech-debt.md#td-001-herdr--delete-herdr-core-before-running-upstreams-installer).

## Why can't the herdr TUI version be pinned?

The herdr Feature installs only through upstream's official scripts ([AD-001](arch-decisions.md#ad-001-herdr--install-only-through-upstreams-official-scripts)). `https://herdr.dev/install.sh` always installs the latest release. To pick up a new release, rebuild the image without cache (`--no-cache`).

## Which hosts does the herdr Feature need at build time?

`herdr.dev`, `github.com`, `release-assets.githubusercontent.com`, `releases.herdr.dev`, and `raw.githubusercontent.com`. See the "Network" section in [`src/herdr/NOTES.md`](../src/herdr/NOTES.md).
