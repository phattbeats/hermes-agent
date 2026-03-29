# ============================================================================
# Hermes Agent — Unraid / Docker
# Multi-stage build: amd64 + arm64
# Uses node:22-slim as base (officially multi-arch) + uv for Python
# ============================================================================

# ── Stage 1: Builder ────────────────────────────────────────────────────────
FROM node:22-slim AS builder

WORKDIR /app

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    python3.11 \
    python3.11-dev \
    python3-pip \
    libffi-dev \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install uv (fast Python package manager)
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.local/bin:$PATH"

# Copy Hermes source
COPY . /app/hermes
WORKDIR /app/hermes

# Install Python dependencies — all extras (messaging, cron, voice, MCP, etc.)
RUN uv venv /app/venv --python 3.11 && \
    uv pip install --python /app/venv/bin/python -e ".[all]"

# Node dependencies (browser tools, WhatsApp bridge)
RUN npm install --silent

# Install Playwright Chromium + system deps for browser automation
RUN npx playwright install --with-deps chromium

# ── Stage 2: Runtime ───────────────────────────────────────────────────────
FROM node:22-slim AS runtime

LABEL maintainer="PHATT TECH <brandon@phatt.tech>"
LABEL description="Hermes Agent — Nous Research AI agent, Unraid-optimized Docker image"
LABEL version="0.5.0"

# Install runtime tools (Python only needed for hermes CLI entry point)
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3.11 \
    python3.11-venv \
    curl \
    ripgrep \
    ffmpeg \
    git \
    sqlite3 \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Copy virtual environment + Node modules from builder
COPY --from=builder /app/venv /app/venv
COPY --from=builder /app/hermes /app/hermes
COPY --from=builder /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=builder /usr/local/bin/node /usr/local/bin/node
COPY --from=builder /usr/local/bin/npm /usr/local/bin/npm
COPY --from=builder /usr/local/bin/npx /usr/local/bin/npx

# Environment
ENV PATH="/app/venv/bin:/usr/local/bin:$PATH"
ENV HERMES_HOME="/data"
ENV PYTHONUNBUFFERED=1
ENV DEBIAN_FRONTEND=noninteractive

# Non-root user for security
RUN groupadd -r hermes && useradd -r -g hermes hermes && \
    mkdir -p /data/cron /data/sessions /data/logs /data/pairing \
             /data/hooks /data/image_cache /data/audio_cache \
             /data/memories /data/skills /data/whatsapp/session && \
    chown -R hermes:hermes /data

WORKDIR /app/hermes

# Expose ports
EXPOSE 4077 5177

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD python3 -c "import socket; s=socket.socket(); s.connect(('127.0.0.1',4077)); s.close()" || exit 1

# Switch to non-root
USER hermes

CMD ["python3", "-c", "print('Hermes Agent v0.5.0 ready. Run: docker exec <container> hermes setup')"]
