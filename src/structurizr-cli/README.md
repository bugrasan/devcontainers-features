
# Structurizr-CLI (structurizr-cli)

This is devcontainers feature for [Structurizr-CLI](https://github.com/structurizr/cli) - a command line utility for Structurizr, designed to be used in conjunction with the Structurizr DSL.

## Example Usage

```json
"features": {
    "ghcr.io/bugrasan/devcontainers-features/structurizr-cli:0": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Select structurizr-cli release | string | latest |
| jdkInstall | Select whether to install JDK. | boolean | false |
| jdkVersion | Select or enter a JDK version to install; supported version >= 17. | string | latest |
| jdkDistro | Select or enter a JDK distribution to install. | string | open |

# NOTES

Structurizr-CLI requires java >= 17.
Therefore don't forget to add java feature, i.e.
```json
    "features": {
		"ghcr.io/devcontainers/features/java:1": {
			"version": "latest",
			"jdkDistro": "open",
		},
    }
```


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/bugrasan/devcontainers-features/blob/main/src/structurizr-cli/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
