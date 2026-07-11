
# claude-code (claude-code)

Installs the Claude Code CLI (Anthropic's agentic coding tool) via its native installer.

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

## Updates

The Claude Code native installer auto-updates in the background, so this Feature
intentionally does **not** add an auto-update `postStartCommand` (unlike the
`copilot-cli` Feature, whose tarball install does not self-update). Manage
updates through Claude Code's own settings if needed (e.g. set
`DISABLE_AUTOUPDATER=1` to turn background updates off).


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/bugrasan/devcontainers-features/blob/main/src/claude-code/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
