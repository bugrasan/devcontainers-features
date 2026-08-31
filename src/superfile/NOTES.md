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
