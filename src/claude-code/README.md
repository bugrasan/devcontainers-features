
# claude-code (claude-code)

Installs the Claude Code CLI (Anthropic's agentic coding tool) via its native installer, and optionally wires up LSP code-intelligence plugins.

## Example Usage

```json
"features": {
    "ghcr.io/bugrasan/devcontainers-features/claude-code:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Release channel or exact version to install: 'stable', 'latest', or a semver like '1.2.3'. | string | latest |
| lspPlugins | Space-separated Claude Code LSP plugins to install at user scope via 'claude plugin install' (e.g. 'pyright-lsp@claude-plugins-official'). Empty string skips plugin installation. NOTE: each plugin only wires the connection - the matching language-server binary (pyright-langserver, typescript-language-server, gopls, ...) must be installed separately and be on PATH for the plugin to activate. Pairs with the ENABLE_LSP_TOOL=1 containerEnv this Feature sets, which turns on Claude Code's LSP tool. | string | pyright-lsp@claude-plugins-official typescript-lsp@claude-plugins-official |
| lspMarketplaces | Space-separated GitHub repos (owner/repo) of Claude Code plugin marketplaces to register (via 'claude plugin marketplace add ... --scope user') before installing lspPlugins. Required because a fresh Claude Code install has no marketplaces registered. Must include the marketplace backing every entry in lspPlugins (e.g. 'anthropics/claude-plugins-official' provides the 'claude-plugins-official' marketplace). | string | anthropics/claude-plugins-official |

## LSP code intelligence

By default this Feature installs Claude Code LSP plugins at **user scope** (via
`claude plugin install`) and sets `ENABLE_LSP_TOOL=1`, so Claude Code can use
language servers (go-to-definition, find-references, hover, diagnostics) instead
of text search. The default `lspPlugins` set is:

- `pyright-lsp@claude-plugins-official` (Python)
- `typescript-lsp@claude-plugins-official` (TypeScript/JavaScript)

**A plugin only wires the connection.** The matching language-server binary must
be installed separately and be on `PATH` for the plugin to activate:

| Plugin | Required binary | Typical source |
|-----|-----|-----|
| `pyright-lsp` | `pyright-langserver` | `npm i -g pyright` |
| `typescript-lsp` | `typescript-language-server` | `npm i -g typescript-language-server` |

Add more via `lspPlugins` (e.g. `gopls-lsp@claude-plugins-official` once a Go
toolchain + `gopls` are on `PATH`).

A fresh Claude Code install has **no marketplaces registered**, so each
marketplace repo in `lspMarketplaces` (default `anthropics/claude-plugins-official`,
which provides the `claude-plugins-official` marketplace) is added via
`claude plugin marketplace add <owner/repo> --scope user` **before** the plugins
are installed. If you point `lspPlugins` at a plugin from another marketplace,
add that marketplace's repo to `lspMarketplaces` too.

Set `lspPlugins` to `""` to skip plugin installation, or override it with your
own space-separated list. Marketplace-add and plugin installs are non-fatal: a
missing binary or marketplace hiccup will not fail the build (check
`claude plugin list` and the Errors tab; `Executable not found in $PATH` means
the binary is missing).

## Updates

The Claude Code native installer auto-updates in the background, so this Feature
intentionally does **not** add an auto-update `postStartCommand` (unlike the
`copilot-cli` Feature, whose tarball install does not self-update). Manage
updates through Claude Code's own settings if needed (e.g. set
`DISABLE_AUTOUPDATER=1` to turn background updates off).


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/bugrasan/devcontainers-features/blob/main/src/claude-code/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
