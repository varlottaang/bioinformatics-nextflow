FROM mcr.microsoft.com/devcontainers/base:jammy

# Keep image small — only install what the course needs
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    graphviz \
    tree \
    && rm -rf /var/lib/apt/lists/*

# Nextflow is installed in post-create.sh (requires Java, which is
# set up via the devcontainer feature after this image build)
