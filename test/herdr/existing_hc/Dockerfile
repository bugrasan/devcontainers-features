FROM mcr.microsoft.com/devcontainers/base:ubuntu

# Another tool already owns 'hc' (some window managers ship one). The Feature
# must install herdr-core under its own name and leave this 'hc' untouched.
RUN printf '#!/bin/sh\necho other-hc\n' > /usr/local/bin/hc && chmod 0755 /usr/local/bin/hc
