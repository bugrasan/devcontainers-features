#!/bin/bash

# exit on error
set -e

# variables provided by devcontainer-feature
TWILIO_CLI_VERSION="${VERSION:-"latest"}"
if [[ ! "${TWILIO_CLI_VERSION}" == "latest" ]]; then
	echo "Only 'latest' version is supported at the moment" && exit 1
fi

# The 'install.sh' entrypoint script is always executed as the root user.
# For more details, see https://containers.dev/implementors/features#user-env-var

# shellcheck source=library_scripts.sh
source ./library_scripts.sh

# nanolayer is a cli utility which keeps container layers as small as possible
# source code: https://github.com/devcontainers-contrib/nanolayer
# `ensure_nanolayer` is a bash function that will find any existing nanolayer installations,
# and if missing - will download a temporary copy that automatically get deleted at the end
# of the script
ensure_nanolayer nanolayer_location "v0.4.46"

# we need these packages to retrieve the apt key
$nanolayer_location \
	install \
	devcontainer-feature \
	"ghcr.io/devcontainers-contrib/features/apt-packages:1.0.4" \
	--option packages=ca-certificates,wget

# this is basically 1-to-1 from https://www.twilio.com/docs/twilio-cli/quickstart
wget -qO- https://twilio-cli-prod.s3.amazonaws.com/twilio_pub.asc \
  | apt-key add -
touch /etc/apt/sources.list.d/twilio.list
echo 'deb https://twilio-cli-prod.s3.amazonaws.com/apt/ /' \
  | sudo tee /etc/apt/sources.list.d/twilio.list
# sudo apt update
# sudo apt install -y twilio
$nanolayer_location \
	install \
	devcontainer-feature \
	"ghcr.io/devcontainers-contrib/features/apt-packages:1.0.4" \
	--option packages=twilio

# FIXME: add to default user vscode
# add autocomplete
printf "eval $(twilio autocomplete:script bash)" >> ~/.bashrc; source ~/.bashrc

echo 'Done!'
