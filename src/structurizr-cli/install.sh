#!/bin/bash
set -e

echo "Activating feature 'structurizr-cli'"

STRZR_VERSION=${VERSION:-"latest"}
echo "The provided version is: $STRZR_VERSION"
STRZR_MISSING_INSTALLED=0
strzr_install="/opt/structurizr-cli"
strzr_bin="${strzr_install}/structurizr.sh"
strzr_pkg="structurizr-cli.zip"


# The 'install.sh' entrypoint script is always executed as the root user.
#
# These following environment variables are passed in by the dev container CLI.
# These may be useful in instances where the context of the final 
# remoteUser or containerUser is useful.
# For more details, see https://containers.dev/implementors/features#user-env-var
# echo "The effective dev container remoteUser is '$_REMOTE_USER'"
# echo "The effective dev container remoteUser's home directory is '$_REMOTE_USER_HOME'"

# echo "The effective dev container containerUser is '$_CONTAINER_USER'"
# echo "The effective dev container containerUser's home directory is '$_CONTAINER_USER_HOME'"


# taken from deno-devcontainers-feature
# Checks if packages are installed and installs them if not
check_packages() {
	if ! dpkg -s "$@" >/dev/null 2>&1; then
		if [ "$(find /var/lib/apt/lists/* | wc -l)" = "0" ]; then
			echo "Running apt-get update..."
			apt-get update -y
		fi
		apt-get -y install --no-install-recommends "$@"
        STRZR_MISSING_INSTALLED=1
        apt-get clean
	fi
}
# make sure we have curl
check_packages ca-certificates curl

# FIXME: check java version >= 17


if [ "${STRZR_VERSION}" == "latest" ]; then
	strzr_uri="https://github.com/structurizr/cli/releases/latest/download/${strzr_pkg}"
else
	strzr_uri="https://github.com/structurizr/cli/releases/download/v${STRZR_VERSION}/${strzr_pkg}"
fi


curl --fail --location --progress-bar --output "${strzr_pkg}" "$strzr_uri"
unzip -d "$bin_dir" -o "${strzr_pkg}"
#chmod +x "$exe"
rm "${strzr_pkg}"

if [ $STRZR_MISSING_INSTALLED -eq 1 ]; then
    echo "cleaning from installed packages"
    apt-get remove -y ca-certificates curl
fi

echo "The structurizr-cli has been installed to $strzr_install"
echo "You can run it with $strzr_bin"
