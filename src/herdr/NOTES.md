## How it works

The Feature runs upstream's official install scripts, unchanged:

| Product | Command | Script |
|---------|---------|--------|
| herdr TUI | `herdr` | [`https://herdr.dev/install.sh`](https://herdr.dev/install.sh), the command [herdr.dev/tui](https://herdr.dev/tui/) documents |
| herdr-core | `hc` | [`https://releases.herdr.dev/core/install.sh`](https://github.com/herdrdev/herdr-core/blob/master/distribution/install.sh) |

- Each script verifies its download against the SHA-256 in upstream's release manifest.
- Both scripts default to `~/.local/bin`. The Feature sets `HERDR_INSTALL_DIR` and `HC_INSTALL_DIR` to `/usr/local/bin` instead, so both commands are on `PATH` for every user.
- The scripts are downloaded to a file first and then run, so a failed download fails the build instead of running an empty script.
- The Feature's own `install.sh` is `bash` and bootstraps what the scripts need (`curl`, `ca-certificates`, and, for herdr-core, `tar` and `gzip`) with `apt-get`. It targets Debian- and Ubuntu-family base images, like the other Features in this repository. It does not run on Alpine.

### Versions

- **herdr TUI:** upstream's script always installs the latest release. It cannot pin a version, so neither can this Feature. Rebuild the image to update.
- **herdr-core:** upstream's script pins through `HC_VERSION`, which the `coreVersion` option sets. Use `latest` (the default) or an exact version such as `"0.1.21"` (`"v0.1.21"` works too).

### Network

The image build needs to reach:

| Host | Used for |
|------|----------|
| `herdr.dev` | the herdr TUI script and its release manifest |
| `github.com` | the herdr TUI binary (release assets) |
| `releases.herdr.dev` | the herdr-core script, manifest, and archive |
| `raw.githubusercontent.com` | the herdr-core agent skill |

## Choosing what to install

| Option | Default | Installs |
|--------|---------|----------|
| `installTui` | `true` | the herdr TUI, with its config and completions |
| `installCore` | `true` | herdr-core, with an `hc` link |

Turning both off fails the build: a Feature that installs nothing is a misconfiguration. With `installTui: false`, the TUI-only options (`configureDefaults`, `installCompletions`, and `installTuiSkill`) do nothing.

## Generated configuration

With `installTui` and `configureDefaults` (default `true`) the Feature writes `~/.config/herdr/config.toml` for the **remote user**, but only when no config file exists yet. Your own config is never overwritten.

The generated file is deliberately **partial**. herdr loads its built-in defaults first and applies the file on top, so every key that is not listed keeps upstream's default, including keys added by future releases. It sets three:

| Key | Value | Why |
|-----|-------|-----|
| `onboarding` | `false` | A dev container is rebuilt from scratch, so herdr's first-run notification wizard would greet the user on every rebuild. |
| `update.version_check` | `false` | Stops the background "is there a newer herdr?" call to herdr.dev. `herdr update`, run as the remote user, cannot replace `/usr/local/bin/herdr` anyway; rebuild the container instead. |
| `update.manifest_check` | `false` | Stops the background agent-detection manifest fetch from herdr.dev. The manifest bundled with the installed binary is the one that matches it. |

`update.channel` is deliberately left **unset**, so it keeps upstream's `stable` default.

Set `configureDefaults: false` to keep the Feature out of the user's home entirely and get herdr's own behavior, background calls included. Print the full commented default config at any time with `herdr --default-config`.

## Agent skills

Two skills are available. Each is installed for every agent harness that is switched on.

| Skill | Option | Default | Source |
|-------|--------|---------|--------|
| `herdr` | `installTuiSkill` | `false` | `herdr --skill`, the copy bundled with the installed binary |
| `herdr-core` | `installCoreSkill` | `true` | upstream's [`skills/herdr-core/SKILL.md`](https://github.com/herdrdev/herdr-core/blob/master/skills/herdr-core/SKILL.md), taken from the installed version's tag |

| Harness | Option | Default | Path, for the remote user |
|---------|--------|---------|---------------------------|
| Claude Code | `skillClaudeCode` | `true` | `~/.claude/skills/<name>/SKILL.md` |
| GitHub Copilot CLI | `skillCopilot` | `true` | `~/.copilot/skills/<name>/SKILL.md` ([changelog](https://github.com/github/copilot-cli/blob/main/changelog.md)) |

The two skills behave differently when the agent is not running inside their tool:

- The `herdr` skill guards itself on `HERDR_ENV=1`. Outside a herdr pane the agent stops and says it is not running inside herdr, so the skill stays inert.
- The `herdr-core` skill is **not** inert. It matches sub-agent and background-task work, and when `HC_TERMINAL_ID` is unset it tells the agent to ask the user once per session whether to use `hc`. It is a short pointer: it tells the agent to run `hc --skill`, which prints the full manual bundled with the installed binary.

`hc --skill` itself prints that manual without the frontmatter agents need to load a skill, which is why the Feature installs upstream's skill file instead.

## Shell completions

With `installTui` and `installCompletions` (default `true`) the Feature writes the output of `herdr completion bash` and `herdr completion zsh` to two standard system-wide locations:

| Shell | Path |
|-------|------|
| bash | `/usr/share/bash-completion/completions/herdr` |
| zsh | `/usr/local/share/zsh/site-functions/_herdr` |

Both are picked up without editing any shell rc file: `bash-completion` lazy-loads by command name, and `/usr/local/share/zsh/site-functions` is on zsh's compiled-in `fpath`. bash completion additionally needs the `bash-completion` package, which the common devcontainer base images already provide.

## herdr-core (`hc`)

[herdr-core](https://github.com/herdrdev/herdr-core) runs programs and coding agents in terminals that stay alive after the viewer leaves, and lets agents start, message, and wait on other agents. It draws no UI; the herdr TUI is the separate terminal app.

- Upstream's script installs `herdr-core` plus an `hc` link, but only when no other `hc` exists (some window managers ship one).
- Nothing is started. The core starts on first use of `hc`, as the user who runs it.
- `hc` contacts `releases.herdr.dev` only on an explicit `hc update` or `hc machine add`, so no config is seeded. Rebuild the container, or bump `coreVersion`, instead of running `hc update`.

```bash
hc run --bg --name web npm run dev   # start a program that outlives this shell
hc ls                                # list live terminals
hc read web --lines 50               # read output without attaching
```

## Notes

- herdr is a **background server**, not a one-shot command. This Feature installs the binary and stops there; it starts nothing. Run `herdr` in your terminal to start or attach to a session; `ctrl+b q` detaches and `herdr` reattaches.
- Upstream publishes Linux builds for `x86_64` and `aarch64` only; both scripts fail with their own message on any other architecture.
- herdr's TUI needs a real terminal. `herdr status`, `herdr --version`, `herdr --default-config`, and `herdr --skill` all run headlessly and are handy for scripting or debugging a container.
- Agent integrations (`herdr integration install claude`, `codex`, and the rest) are **not** installed by this Feature. Install the agent CLIs first, then run the integration command inside the container so herdr wires up against the versions actually present.
