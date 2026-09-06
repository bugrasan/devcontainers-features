FROM mcr.microsoft.com/devcontainers/base:ubuntu

# Pre-seed a herdr config the way a user or a team image would. The Feature
# must leave it exactly as it is: configureDefaults never overwrites.
USER vscode
RUN mkdir -p /home/vscode/.config/herdr \
    && printf '# hand-written, do not touch\nonboarding = true\n' \
        > /home/vscode/.config/herdr/config.toml
USER root
