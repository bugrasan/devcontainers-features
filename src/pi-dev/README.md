
# pi-dev (pi-dev)

Installs the Pi coding agent CLI via the official pi.dev installer. Requires Node.js >=22.19.0 and npm.

## Example Usage

```json
"features": {
    "ghcr.io/bugrasan/devcontainers-features/pi-dev:1": {}
}
```



## How it works

- Runs upstream's official installer, [`https://pi.dev/install.sh`](https://pi.dev/install.sh), unchanged and as the remote user. Pi always installs its latest release.
- Upstream installs the `pi` launcher to `~/.pi/agent/bin/pi` and does **not** add that directory to `PATH`. Add it yourself, for example in `devcontainer.json`: `"remoteEnv": { "PATH": "${containerEnv:PATH}:/home/vscode/.pi/agent/bin" }` (use your remote user's home).
- Requires Node.js >=22.19.0 and npm. Add a Feature that provides them (for example `ghcr.io/devcontainers/features/node`) before this one.
- The build must reach `pi.dev` and the npm registry.


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/bugrasan/devcontainers-features/blob/main/src/pi-dev/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
