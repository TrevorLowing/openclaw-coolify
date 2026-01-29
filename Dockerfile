FROM ubuntu:24.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install Core & Power Tools
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    build-essential \
    software-properties-common \
    python3 \
    python3-pip \
    jq \
    lsof \
    openssl \
    ca-certificates \
    golang-go \
    # Power Tools: ripgrep, fd, fzf, bat
    ripgrep fd-find fzf bat \
    && rm -rf /var/lib/apt/lists/*

# Install Cloudflare Tunnel (cloudflared)
RUN curl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb && \
    dpkg -i cloudflared.deb && \
    rm cloudflared.deb

# Install GitHub CLI (gh)
RUN mkdir -p -m 755 /etc/apt/keyrings && \
    wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null && \
    chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
    apt-get update && \
    apt-get install -y gh && \
    rm -rf /var/lib/apt/lists/*


# Install uv (Python tool manager)
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# Install Bun
RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="/root/.bun/bin:${PATH}"

# Install Node.js dependencies & Yarn & Vercel
RUN npm install -g yarn vercel && \
    npm install -g n && \
    n lts && \
    hash -r

# Install Python REPL
RUN pip3 install ipython --break-system-packages

# Add aliases for standard tool names (Ubuntu quirks)
RUN ln -s /usr/bin/fdfind /usr/bin/fd || true && \
    ln -s /usr/bin/batcat /usr/bin/bat || true

# Install Node.js (Latest LTS or specific version required by Moltbot)
# Using NodeSource for newer node versions
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g npm@latest

# Set up working directory
WORKDIR /app

# Run Moltbot install scripts
# 1. Stable install
ENV MOLT_BOT_BETA=false
RUN curl -fsSL https://molt.bot/install.sh | bash

# 2. Beta update
ENV MOLT_BOT_BETA=true
RUN curl -fsSL https://molt.bot/install.sh | bash -s -- --beta

# Install uv (requested by user for MiniMax CLI)
ENV UV_INSTALL_DIR="/usr/local/bin"
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# Create necessary directories and set permissions
# The install script might install to global node_modules or a specific location.
# Based on previous context, it seems to run a node app.
# We'll ensure the 'node' user exists and has permissions.

# Create a non-root user 'node' if it doesn't exist (Ubuntu image doesn't satisfy this by default)
RUN groupadd -r node && useradd -r -g node -m -s /bin/bash node

# Copy local scripts
COPY scripts/bootstrap.sh /app/scripts/bootstrap.sh
RUN chmod +x /app/scripts/bootstrap.sh

# Create configuration directories with correct permissions
RUN mkdir -p /home/node/.moltbot /home/node/molt && \
    chown -R node:node /home/node/.moltbot /home/node/molt /app

# Switch to non-root user
USER node
WORKDIR /app

# Expose the application port
EXPOSE 18789

# Set entrypoint
CMD ["bash", "/app/scripts/bootstrap.sh"]