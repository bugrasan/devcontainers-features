
# superfile (superfile)

Installs superfile ('spf'), a modern terminal file manager (TUI), from its official GitHub release. Optionally installs the tools superfile shells out to for previews/clipboard/zoxide, and seeds a container-friendly config for the remote user.

## Example Usage

```json
"features": {
    "ghcr.io/bugrasan/devcontainers-features/superfile:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | superfile release to install: 'latest' (resolved at build time) or an exact version like '1.6.0' (a leading 'v' is accepted too). See https://github.com/yorukot/superfile/releases. | string | latest |
| installPreviewTools | Install the tools superfile uses for rich previews: ffmpeg (video thumbnails), poppler-utils (PDF thumbnails via pdftoppm), exiftool (the 'metadata' plugin) and bat (syntax-highlighted code preview). Adds a few hundred MB to the image. When 'configureDefaults' is on, this also turns on 'metadata' and sets 'code_previewer = "bat"' in the generated config. | boolean | false |
| installClipboardTools | Install xdg-utils (xdg-open, for 'open with the default application'), xclip and wl-clipboard. These are mostly no-ops in a headless container but are small and stop superfile's --debug-info from reporting them as missing. | boolean | false |
| installZoxide | Install zoxide for smart directory jumping inside superfile. When 'configureDefaults' is on, this also sets 'zoxide_support = true' in the generated config. | boolean | false |
| configureDefaults | Write a small container-friendly ~/.config/superfile/config.toml for the remote user (only when no config file exists yet). Its most important effect is 'auto_check_update = false', so a throwaway dev container never phones home to the GitHub API on startup. Set to false to leave configuration entirely to superfile's own first-run defaults. | boolean | true |
| nerdfont | Value for superfile's 'nerdfont' setting in the generated config (ignored when configureDefaults is false). superfile renders Nerd Font glyphs by default; terminal fonts live on the HOST, so set this to false when the terminal attaching to the container does not use a Nerd Font-patched font, to avoid tofu boxes. | boolean | true |
| cdOnQuit | Enable superfile's 'cd on quit': sets 'cd_on_quit = true' in the generated config (requires configureDefaults) and installs upstream's spf() shell wrapper into the remote user's ~/.bashrc / ~/.zshrc, so leaving superfile changes the shell's directory. Off by default because the wrapper shadows the 'spf' command and edits the user's shell rc files. | boolean | false |
| createAlias | Also expose the binary as 'superfile' (a symlink to /usr/local/bin/spf). Upstream installs the command as 'spf' only; the symlink makes the more discoverable name work too. Set to false to install exactly what upstream does. | boolean | true |

## How it works

- Downloads the official [superfile](https://github.com/yorukot/superfile) release asset (`superfile-linux-v<version>-<arch>.tar.gz`, linux `amd64`/`arm64`) and installs the binary as `/usr/local/bin/spf` — the command name upstream uses. With `createAlias` (default `true`) a `superfile` symlink is added next to it, so both names work.
- `version: latest` (the default) is resolved at **build time** by following the `releases/latest` redirect, with the GitHub API as a fallback. Pin an exact release (`"1.6.0"`, or `"v1.6.0"`) for reproducible builds.
- No language runtime is needed: the release binary is a statically linked (`CGO_ENABLED=0`) Go binary.

## Generated configuration

With `configureDefaults` (default `true`) the Feature writes `~/.config/superfile/config.toml` for the **remote user**, but only when no config file exists yet — your own config is never overwritten.

The generated file is deliberately **partial**. superfile loads its built-in defaults first and applies the file on top, so every key that is not listed keeps upstream's default — including keys added by future superfile releases. It sets:

| Key | Value | Why |
|-----|-------|-----|
| `ignore_missing_fields` | `true` | Silences the "missing fields" warning a partial config would otherwise print on every start. |
| `auto_check_update` | `false` | Dev containers are disposable; the 24h version check against the GitHub API and its update nag are just noise. **This is the main reason the option exists.** |
| `nerdfont` | `nerdfont` option | See below. |
| `cd_on_quit` | `cdOnQuit` option | See below. |
| `metadata` | `true` only with `installPreviewTools` | Needs `exiftool`. |
| `code_previewer` | `"bat"` only with `installPreviewTools` | Needs `bat`. |
| `zoxide_support` | `true` only with `installZoxide` | Needs `zoxide`. |

Plugin toggles are only switched on when this Feature actually installed the tool they depend on, so the config never points at a binary that isn't there.

superfile still generates its own `hotkeys.toml` and `theme/` on first run, alongside the generated config. Set `configureDefaults: false` to keep the Feature out of the user's home entirely and get upstream's first-run behaviour (including the auto-update check).

## Nerd Font glyphs

superfile ships `nerdfont = true`, meaning it renders Nerd Font icons. The terminal font lives on the **host**, not in the container, so a terminal without a Nerd Font-patched font shows tofu boxes (`□`). Set `nerdfont: false` in that case:

```jsonc
"features": {
    "ghcr.io/bugrasan/devcontainers-features/superfile:1": {
        "nerdfont": false
    }
}
```

## cd on quit

A child process cannot change its parent shell's directory, so superfile writes its last directory to a file and relies on a shell wrapper to `cd` there afterwards. With `cdOnQuit: true` the Feature sets `cd_on_quit = true` and installs upstream's wrapper at `/usr/local/share/superfile/cd_on_quit.sh`, sourcing it from the remote user's `~/.bashrc` and `~/.zshrc` (idempotently, between marker comments).

It is **off by default** because it defines an `spf` shell function that shadows the command and it edits the user's shell rc files.

## Optional tools

superfile shells out to a handful of external programs and degrades gracefully when they are absent. Run `spf --debug-info` inside the container to see what it can currently find. None are installed by default, to keep the image small:

| Option | Installs | Enables |
|--------|----------|---------|
| `installPreviewTools` | `ffmpeg`, `poppler-utils`, `libimage-exiftool-perl`, `bat` | Video thumbnails, PDF thumbnails (`pdftoppm`), the detailed-metadata plugin, `bat` syntax highlighting. Adds a few hundred MB. |
| `installClipboardTools` | `xdg-utils`, `xclip`, `wl-clipboard` | "Open with the default application", yank to clipboard. Mostly no-ops in a headless container. |
| `installZoxide` | `zoxide` | Smart directory jumping inside superfile. |

Debian and Ubuntu package `bat` as `batcat` (the `bat` name belongs to `bacula-console-qt`), while superfile invokes `bat` — the Feature adds a `/usr/local/bin/bat` symlink so the code previewer works.

## Notes

- Upstream's `install.sh` is deliberately **not** used: it requires `sudo`, appends to shell rc files unconditionally, and always resolves the newest release through the rate-limited GitHub API, which makes a pinned `version` impossible.
- Only linux `amd64` and `arm64` are published upstream; the install script fails with a clear message on any other architecture.
- superfile's TUI needs a real terminal. `spf path-list` and `spf --debug-info` both run headlessly and are handy for scripting or debugging a container.


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/bugrasan/devcontainers-features/blob/main/src/superfile/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
