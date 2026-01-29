FROM node:lts-bookworm-slim

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install Core & Power Tools
# Note: Debian "slim" images are minimal. We need to install common tools.
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    wget \
    git \
    build-essential \
    software-properties-common \
    python3 \
    python3-pip \
    python3-venv \
    jq \
    lsof \
    openssl \
    ca-certificates \
    golang-go \
    gnupg \
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
ENV UV_INSTALL_DIR="/usr/local/bin"
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# Install Bun
# Note: Bun install script works better with unzip
RUN apt-get update && apt-get install -y unzip && rm -rf /var/lib/apt/lists/* && \
    curl -fsSL https://bun.sh/install | bash
ENV PATH="/root/.bun/bin:${PATH}"

# Install Vercel (Node & NPM are already provided by base image)
RUN npm install -g yarn vercel && \
    hash -r

# Install Python Tools (IPython)
# Use --break-system-packages because we are in a container/appliance
RUN pip3 install ipython --break-system-packages

# Add aliases for standard tool names (Debian/Ubuntu quirks)
RUN ln -s /usr/bin/fdfind /usr/bin/fd || true && \
    ln -s /usr/bin/batcat /usr/bin/bat || true

# Set up working directory
WORKDIR /app

# Run Moltbot install scripts
# 1. Stable install
ENV MOLT_BOT_BETA=false
RUN curl -fsSL https://molt.bot/install.sh | bash

# 2. Beta update
ENV MOLT_BOT_BETA=true
RUN curl -fsSL https://molt.bot/install.sh | bash -s -- --beta

# Create necessary directories and set permissions
# 'node' user already exists in the base image
RUN mkdir -p /home/node/.moltbot /home/node/molt && \
    chown -R node:node /home/node/.moltbot /home/node/molt /app

# Copy local scripts
COPY scripts/bootstrap.sh /app/scripts/bootstrap.sh
RUN chmod +x /app/scripts/bootstrap.sh

# Switch to non-root user
USER node
WORKDIR /app

# Expose the application port
EXPOSE 18789

# Set entrypoint
CMD ["bash", "/app/scripts/bootstrap.sh"]