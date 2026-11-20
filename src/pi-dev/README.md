
# pi-dev (pi-dev)

Installs the Pi coding agent CLI via the official pi.dev installer. Requires Node.js >=22.19.0 and npm.

## Example Usage

```json
"features": {
    "ghcr.io/bugrasan/devcontainers-features/pi-dev:2": {}
}
```



## How it works

- Runs upstream's official installer, [`https://pi.dev/install.sh`](https://pi.dev/install.sh), unchanged and as the remote user. Pi always installs its latest release.
- By default, upstream installs the `pi` launcher to `~/.pi/agent/bin/pi` and does **not** add that directory to `PATH`. (It uses `~/.local/bin` or a similar home directory instead when one is already on `PATH` during the build.) Add it yourself, for example in `devcontainer.json`: `"remoteEnv": { "PATH": "${containerEnv:PATH}:/home/vscode/.pi/agent/bin" }` (use your remote user's home).
- Requires Node.js >=22.19.0 and npm. Add a Feature that provides them (for example `ghcr.io/devcontainers/features/node`) before this one.
- The build must reach `pi.dev` and the npm registry.
- `su` passes the build environment to upstream's installer, so `PI_*` variables set in the image change its behavior.
- **Upgrading from pi-dev 1.0.2:** that version linked `/usr/local/bin/pi`. On an image built with it, remove that link first (`sudo rm /usr/local/bin/pi`): upstream's installer otherwise tries to put its launcher in `/usr/local/bin` and fails.


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/bugrasan/devcontainers-features/blob/main/src/pi-dev/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
