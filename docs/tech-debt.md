# Tech debt

Workarounds in this repository. Each one compensates for upstream behavior and should go once upstream changes. Upstream source links are permalinks to the commit that was checked.

## TD-001: herdr – delete herdr-core before running upstream's installer

- **Where:** [`src/herdr/install.sh`](../src/herdr/install.sh), the `rm -f "${INSTALL_DIR}/herdr-core"` line in the herdr-core section
- **Decision:** [AD-002](arch-decisions.md#ad-002-herdr--install-herdr-core-fresh-even-when-it-exists)
- **Upstream issue:** none filed yet
- **Tests:** scenarios in [`test/herdr/scenarios.json`](../test/herdr/scenarios.json):
  - `existing_core_older`: an older pinned version replaces a newer one;
  - `existing_core_upgrade`: an upgrade leaves no core state in the image.

### Problem

Upstream's herdr-core installer (`https://releases.herdr.dev/core/install.sh`, [`distribution/install.sh`](https://github.com/herdrdev/herdr-core/blob/c7517808d64f06609e4ecf0db1757005373cc3a3/distribution/install.sh#L109-L111)) checks whether `$HC_INSTALL_DIR/herdr-core` already exists. If it does, the installer runs `herdr-core update --from <new binary>` instead of copying the binary into place.

That update path ([`crates/herdr-core/src/cli/update.rs`](https://github.com/herdrdev/herdr-core/blob/c7517808d64f06609e4ecf0db1757005373cc3a3/crates/herdr-core/src/cli/update.rs#L53-L104)) is built for a live machine:

- it refuses a version older than the installed one unless `--force` is passed ([L75–L77](https://github.com/herdrdev/herdr-core/blob/c7517808d64f06609e4ecf0db1757005373cc3a3/crates/herdr-core/src/cli/update.rs#L75-L77)), and the installer passes no `--force`;
- after the swap it asks the core for its status ([L94](https://github.com/herdrdev/herdr-core/blob/c7517808d64f06609e4ecf0db1757005373cc3a3/crates/herdr-core/src/cli/update.rs#L94)), which starts a core when none is running ([`cli.rs` L221–L222](https://github.com/herdrdev/herdr-core/blob/c7517808d64f06609e4ecf0db1757005373cc3a3/crates/herdr-core/src/cli.rs#L221-L222)).

In an image build this means:

- an older `coreVersion` fails the build with "hc 0.1.20 is older than this hc 0.1.21";
- a root `herdr-core serve` is started during the build, and its state (`/root/.local/state/herdr-core/default/`: socket, lock, log, terminals) is written into the image layer.

This happens whenever the Feature runs on an image that already has herdr-core in `/usr/local/bin`, for example a base image that already ran this Feature. Both effects were reproduced in a throwaway container before the workaround was added.

### Workaround

Delete `/usr/local/bin/herdr-core` right before running upstream's installer. The installer then takes its fresh-install path, which copies the binary and starts nothing. An existing `hc` link is kept and resolves again once the new binary is in place.

### Remove when

Upstream's installer installs fresh when asked to, or stops starting a core and refusing downgrades during a non-interactive install. For example: an environment variable that forces the fresh path, or `--force` plus a no-restart mode for `update --from`.
