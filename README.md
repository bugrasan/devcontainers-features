# README

currently this repo contains the folling devcontainer features:
- 'structurizr-cli', see [Structurizr-CLI](https://docs.structurizr.com/cli)
- 'twilio-cli', see [Twilio CLI](https://www.twilio.com/docs/twilio-cli)
- 'claude-code', see [Claude Code](https://code.claude.com/docs/en/overview)
- 'pi-dev', see [Pi](https://pi.dev)


## structurizr-cli
```json
"features": {
    "ghcr.io/bugrasan/devcontainers-features/structurizr-cli:1": {}
}
```

## twilio-cli
```json
"features": {
    "ghcr.io/bugrasan/devcontainers-features/twilio-cli:0": {}
}
```

## claude-code
```json
"features": {
    "ghcr.io/bugrasan/devcontainers-features/claude-code:1": {}
}
```

## pi-dev
Requires Node.js >=22.19.0 and npm - add a Feature that provides them (e.g.
`ghcr.io/devcontainers/features/node`) before this one.
```json
"features": {
    "ghcr.io/bugrasan/devcontainers-features/pi-dev:1": {}
}
```
