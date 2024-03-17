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
