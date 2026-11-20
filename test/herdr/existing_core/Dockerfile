FROM mcr.microsoft.com/devcontainers/base:ubuntu

# An image that already carries herdr-core in /usr/local/bin, like a base image
# that ran this Feature before. Installed with upstream's own script.
RUN curl -fsSL https://releases.herdr.dev/core/install.sh | HC_INSTALL_DIR=/usr/local/bin sh
