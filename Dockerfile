FROM ubuntu:22.04

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    wget \
    git \
    sudo \
    ca-certificates \
    unzip \
    openssh-client \
    gnupg \
    lsb-release \
    iptables \
    xz-utils \
    fuse-overlayfs \
    nano \
    && rm -rf /var/lib/apt/lists/*

# Create coder user with passwordless sudo + docker access
RUN useradd -m -s /bin/bash coder \
    && echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
    && groupadd docker \
    && usermod -aG docker coder

# Install Docker CLI
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
    > /etc/apt/sources.list.d/docker.list \
    && apt-get update && apt-get install -y --no-install-recommends \
    docker-ce-cli \
    docker-buildx-plugin \
    docker-compose-plugin \
    && rm -rf /var/lib/apt/lists/*

# Install Docker daemon binary (for Docker-in-Docker)
ENV DIND_VERSION=27.3.1
RUN curl -fsSL "https://download.docker.com/linux/static/stable/$(uname -m)/docker-${DIND_VERSION}.tgz" \
    | tar -xzC /usr/local/bin --strip-components=1

# Install code-server
RUN curl -fsSL https://code-server.dev/install.sh | sh

# Install fnm for the coder user
USER coder
RUN curl -fsSL https://fnm.vercel.app/install | bash

ENV FNM_DIR="/home/coder/.local/share/fnm"
ENV PATH="$FNM_DIR:$PATH"

# Ensure fnm is initialized in every new terminal (bashrc + profile)
RUN cat >> /home/coder/.bashrc <<'DOTFNSH'
export FNM_DIR="/home/coder/.local/share/fnm"
export PATH="$FNM_DIR:$PATH"
eval "$(fnm env --shell bash)"
DOTFNSH
RUN cat >> /home/coder/.profile <<'DOTFNSH'
export FNM_DIR="/home/coder/.local/share/fnm"
export PATH="$FNM_DIR:$PATH"
eval "$(fnm env --shell bash)"
DOTFNSH

# Set VS Code defaults (dark theme, etc.)
COPY code-server-settings.json /tmp/code-server-settings.json
RUN mkdir -p /home/coder/.local/share/code-server/User && \
    cp /tmp/code-server-settings.json /home/coder/.local/share/code-server/User/settings.json && \
    chown -R coder:coder /home/coder/.local/share/code-server

USER root
RUN mkdir -p /home/coder/project && chown -R coder:coder /home/coder

USER coder
WORKDIR /home/coder/project
