FROM mcr.microsoft.com/devcontainers/base:ubuntu

# An image that already carries herdr-core 0.1.20 in /usr/local/bin, like a base
# image that ran this Feature before. Installed with upstream's own script,
# saved to a file first so a failed download fails this build.
RUN curl -fsSL https://releases.herdr.dev/core/install.sh -o /tmp/hc-install.sh \
    && HC_VERSION=0.1.20 HC_INSTALL_DIR=/usr/local/bin sh /tmp/hc-install.sh \
    && test -x /usr/local/bin/herdr-core \
    && rm /tmp/hc-install.sh
