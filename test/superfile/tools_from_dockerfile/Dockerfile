# Reproduces the situation this Feature's plugin detection exists for, and the
# one bugrasan/devcontainer-base-ai is actually in: the IMAGE installs
# superfile's optional tools itself, in its own Dockerfile, and the Feature is
# then layered on top with its install* options left off.
#
# Before plugin detection, that combination left metadata/zoxide_support off -
# the tools were present but unused, and the only way to switch them on was
# installPreviewTools, which would re-install a toolchain the image already had.
#
# bat is deliberately NOT installed here, so the scenario also proves detection
# is per-tool rather than all-or-nothing.
FROM mcr.microsoft.com/devcontainers/base:ubuntu

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        libimage-exiftool-perl \
        zoxide \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
