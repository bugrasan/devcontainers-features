## How it works

- Downloads the official [herdr](https://github.com/herdrdev/herdr) release asset (`herdr-linux-x86_64` / `herdr-linux-aarch64`) and installs it as `/usr/local/bin/herdr`. The Linux asset is a **bare executable**, not an archive, so there is nothing to unpack.
- `version: latest` (the default) is resolved at **build time** from upstream's release manifest, the same `latest.json` that `herdr update` reads. Pin an exact release (`"0.8.2"`, or `"v0.8.2"`) for reproducible builds.
- The download is **verified against upstream's published SHA-256**, read from that manifest. Releases before `0.8.0` publish no checksum: those install with a warning rather than failing, so the `version` option stays usable across upstream's history.
- No language runtime and no system libraries are needed: the Linux release binary is a statically linked (musl, static-PIE) Rust binary, so nothing has to be present in the image for it to run.
- The install script itself is `bash` and bootstraps its prerequisites (`curl`, `ca-certificates`) with `apt-get`, so it targets Debian- and Ubuntu-family base images, like the other Features in this repository. It does not run on Alpine.

## Why not upstream's `install.sh`

`curl -fsSL https://herdr.dev/install.sh | sh` is the documented install path, and this Feature deliberately does not use it:

- it always installs the newest release, which makes a pinned `version` impossible
- it installs into `$HOME/.local/bin`, which is per-user and not necessarily on `PATH`
- it requires `herdr.dev` to be reachable from the image build

This Feature keeps the one part worth keeping — the SHA-256 check — and reads the same manifest from `raw.githubusercontent.com`, so installing herdr itself only needs to reach GitHub. herdr-core is the exception: see below.

## Generated configuration

With `configureDefaults` (default `true`) the Feature writes `~/.config/herdr/config.toml` for the **remote user**, but only when no config file exists yet — your own config is never overwritten.

The generated file is deliberately **partial**. herdr loads its built-in defaults first and applies the file on top, so every key that is not listed keeps upstream's default, including keys added by future releases. It sets three:

| Key | Value | Why |
|-----|-------|-----|
| `onboarding` | `false` | A dev container is rebuilt from scratch, so herdr's first-run notification wizard would greet the user on every rebuild. |
| `update.version_check` | `false` | Stops the background "is there a newer herdr?" call to herdr.dev. `herdr update` cannot manage an install this Feature made anyway — rebuild the container, or bump the `version` option. |
| `update.manifest_check` | `false` | Stops the background agent-detection manifest fetch from herdr.dev. The manifest bundled with the pinned binary is the one that matches it. |

`update.channel` is deliberately left **unset**, so it keeps upstream's `stable` default.

Set `configureDefaults: false` to keep the Feature out of the user's home entirely and get herdr's own behaviour, background calls included. Print the full commented default config at any time with `herdr --default-config`.

## Agent skill

With `installSkill` (default `true`) the Feature writes herdr's agent skill to `~/.claude/skills/herdr/SKILL.md` for the remote user. The content comes from `herdr --skill`, so it is the copy bundled with the binary that was actually installed, not a version fetched separately.

The skill teaches a coding agent to **drive** herdr from inside a pane: split panes, run commands without stealing focus, read pane output, wait until a sibling agent is genuinely `idle` or `blocked`, and start helper agents beside itself.

Its first rule is a guardrail: if `HERDR_ENV=1` is not set, the agent must stop and say it is not running inside herdr. So the skill is inert unless the agent process itself was started in a herdr pane — installing it costs nothing when herdr is not in use.

```bash
herdr          # start or attach to the session
claude         # now HERDR_ENV=1 is set, and the skill applies
```

Set `installSkill: false` to skip it. See [Agent skill file](https://herdr.dev/docs/agent-skill/) upstream.

`herdr --skill` was added after 0.7.5. Pinning an older release warns and skips the skill rather than failing the build.

## Shell completions

With `installCompletions` (default `true`) the Feature writes the output of `herdr completion bash` and `herdr completion zsh` to two standard system-wide locations:

| Shell | Path |
|-------|------|
| bash | `/usr/share/bash-completion/completions/herdr` |
| zsh | `/usr/local/share/zsh/site-functions/_herdr` |

Both are picked up without editing any shell rc file: `bash-completion` lazy-loads by command name, and `/usr/local/share/zsh/site-functions` is on zsh's compiled-in `fpath`. bash completion additionally needs the `bash-completion` package, which the common devcontainer base images already provide.

`herdr completion` was added in 0.7.1. Pinning an older release warns and skips the completions rather than failing the build.

## herdr-core (`hc`)

With `installCore` (default `true`) the Feature also installs [herdr-core](https://github.com/herdrdev/herdr-core), the headless core whose CLI is `hc`. It runs programs and coding agents in terminals that stay alive after the viewer leaves, and lets agents start, message, and wait on other agents. It draws no UI; herdr is the separate TUI.

- Installed as `/usr/local/bin/herdr-core`, plus an `hc` symlink, but only when no other `hc` exists, matching upstream's installer (some window managers ship an `hc`).
- `coreVersion: latest` (the default) resolves at build time; pin an exact release (`"0.1.21"` or `"v0.1.21"`) for reproducible builds. It is independent of herdr's `version`: the two products are versioned separately.
- Downloaded from `releases.herdr.dev`, the **only** place upstream publishes herdr-core builds; there are no GitHub release assets. The archive is verified against the SHA-256 in that release service's manifest, and the build fails if the manifest is unreachable, so the image build must be able to reach `releases.herdr.dev`.
- With `installSkill`, upstream's skill file ([`skills/herdr-core/SKILL.md`](https://github.com/herdrdev/herdr-core/blob/master/skills/herdr-core/SKILL.md), taken from the matching release tag) goes to `~/.claude/skills/herdr-core/SKILL.md`, next to herdr's own skill. It is a short pointer: it tells the agent to run `hc --skill`, which prints the full manual bundled with the installed binary. Unlike herdr's skill it is not inert outside a session: when `HC_TERMINAL_ID` is unset, it tells the agent to ask the user once whether to use `hc`. A missing skill file only warns.
- Nothing is started. The core starts on first use of `hc`, as the user who runs it. `hc` contacts `releases.herdr.dev` only on an explicit `hc update` or `hc machine add`, so no config is seeded. `hc update` would replace the image's binary; rebuild the container or bump `coreVersion` instead.

```bash
hc run --bg --name web npm run dev   # start a program that outlives this shell
hc ls                                # list live terminals
hc read web --lines 50               # read output without attaching
```

Set `installCore: false` to skip herdr-core and keep the build reaching GitHub only.

## Notes

- herdr is a **background server**, not a one-shot command. This Feature installs the binary and stops there — it starts nothing. Run `herdr` in your terminal to start or attach to a session; `ctrl+b q` detaches and `herdr` reattaches.
- Only linux `x86_64` and `aarch64` are published upstream; the install script fails with a clear message on any other architecture.
- herdr's TUI needs a real terminal. `herdr status`, `herdr --version`, `herdr --default-config`, and `herdr --skill` all run headlessly and are handy for scripting or debugging a container.
- Agent integrations (`herdr integration install claude`, `codex`, and the rest) are **not** installed by this Feature. Install the agent CLIs first, then run the integration command inside the container so herdr wires up against the versions actually present.
