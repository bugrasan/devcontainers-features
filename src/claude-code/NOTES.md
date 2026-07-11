## Updates

The Claude Code native installer auto-updates in the background, so this Feature
intentionally does **not** add an auto-update `postStartCommand` (unlike the
`copilot-cli` Feature, whose tarball install does not self-update). Manage
updates through Claude Code's own settings if needed (e.g. set
`DISABLE_AUTOUPDATER=1` to turn background updates off).
