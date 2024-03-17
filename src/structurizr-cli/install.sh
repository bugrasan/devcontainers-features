#!/bin/sh

# exit on error
set -e

# variables provided by devcontainer-feature
STRZR_VERSION="${VERSION:-"latest"}"
JDK_INSTALL="${JDKINSTALL:-"false"}"
JDK_DISTRO="${JDKDISTRO:-"open"}"
JDK_VERSION="${JDKVERSION:-"latest"}"

# variables
strzr_path="/opt/structurizr-cli"
strzr_bin="${strzr_path}/structurizr.sh"
strzr_pkg="structurizr-cli.zip"


# The 'install.sh' entrypoint script is always executed as the root user.
# For more details, see https://containers.dev/implementors/features#user-env-var

# shellcheck source=library_scripts.sh
source ./library_scripts.sh

# nanolayer is a cli utility which keeps container layers as small as possible
# source code: https://github.com/devcontainers-contrib/nanolayer
# `ensure_nanolayer` is a bash function that will find any existing nanolayer installations, 
# and if missing - will download a temporary copy that automatically get deleted at the end 
# of the script
ensure_nanolayer nanolayer_location "v0.4.29"

if [ "${JDK_INSTALL}" = "true" ]; then
	if [ "${JDK_VERSION}" = "latest" || $((JDK_VERSION)) >= 17 ]; then
		$nanolayer_location \
			install \
			devcontainer-feature \
			"ghcr.io/devcontainers/features/java:1.2.1" \
			--option jdkDistro="${JDK_DISTRO}" --option version="${JDK_VERSION}"
	else 
		echo "jdkVersion isn't supported; Structurizr-CLI supports JDK >= 17" && exit 1
	fi
fi

# we need these packages to retrieve & unpack `structurizr-cli`
$nanolayer_location \
	install \
	apt \
	ca-certificates,curl,unzip

if [ "${STRZR_VERSION}" = "latest" ]; then
	strzr_uri="https://github.com/structurizr/cli/releases/latest/download/${strzr_pkg}"
else
	strzr_uri="https://github.com/structurizr/cli/releases/download/v${STRZR_VERSION}/${strzr_pkg}"
fi

curl --fail --location --progress-bar --output "/tmp/${strzr_pkg}" "${strzr_uri}"
unzip -d "${strzr_path}" -o "/tmp/${strzr_pkg}"
rm "${strzr_pkg}"

echo "The structurizr-cli has been installed to '${strzr_path}' and can run it with '${strzr_bin}'"

echo 'Done!'