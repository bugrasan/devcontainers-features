# Architecture decisions

## AD-001: herdr – install only through upstream's official scripts

- **Status:** accepted (herdr Feature 2.0.0)
- **Context:** Feature 1.x downloaded the herdr TUI release asset itself and parsed upstream's release manifest to resolve versions and checksums. That code duplicated upstream's installer and had to track upstream's manifest format.
- **Decision:** the herdr Feature installs both products only with upstream's official install scripts, unchanged:
  - herdr TUI: `https://herdr.dev/install.sh`;
  - herdr-core: `https://releases.herdr.dev/core/install.sh`.

  Both scripts are pointed at `/usr/local/bin` through `HERDR_INSTALL_DIR` and `HC_INSTALL_DIR`.
- **Consequences:**
  - Version pinning exists only where a script supports it. herdr-core pins through `HC_VERSION` (`coreVersion`). The herdr TUI script cannot pin, so the `version` option was removed, which is why the Feature moved to 2.0.0.
  - Checksum verification is upstream's job.
  - The build must reach `herdr.dev`, `github.com`, `release-assets.githubusercontent.com`, `releases.herdr.dev`, and `raw.githubusercontent.com`.

## AD-002: herdr – install herdr-core fresh, even when it exists

- **Status:** accepted, implemented as a workaround ([TD-001](tech-debt.md#td-001-herdr--delete-herdr-core-before-running-upstreams-installer))
- **Context:** upstream's herdr-core installer updates an existing install in place. Inside an image build, that refuses older versions and starts a root core whose state lands in the image.
- **Decision:** the Feature deletes `/usr/local/bin/herdr-core` before running the installer, so every build takes the fresh-install path.
- **Consequences:**
  - A pinned `coreVersion` always wins, including downgrades.
  - No core runs and no core state is written during the build.
  - The Feature depends on the installer's "binary exists" check staying the switch between the two paths. If upstream changes that, revisit TD-001.
