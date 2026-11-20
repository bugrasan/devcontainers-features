## How it works

- Runs upstream's official installer, [`https://pi.dev/install.sh`](https://pi.dev/install.sh), unchanged and as the remote user. Pi always installs its latest release.
- Upstream's installer puts the `pi` launcher in `~/.pi/agent/bin`, which is not on `PATH`. The Feature links it as `/usr/local/bin/pi`, so every shell finds it. The launcher follows the link to find its install, so `pi update` keeps working.
- Requires Node.js >=22.19.0 and npm. Add a Feature that provides them (for example `ghcr.io/devcontainers/features/node`) before this one.
- The build must reach `pi.dev` and the npm registry.
- Running the Feature again on an image that already has it works: the Feature removes its own `/usr/local/bin/pi` link before the installer runs, then links it again.
