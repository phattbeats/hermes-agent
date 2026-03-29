# ============================================================================
# Hermes Agent — Unraid / Docker
# Multi-stage build for amd64 + arm64
# ============================================================================
# Stage 1: Builder
# ============================================================================
FROM python:3.11-slim AS builder

WORKDIR /app

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    python3-dev \
    libffi-dev \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install uv (fast Python package manager)
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.local/bin:$PATH"

# Clone Hermes Agent (clone from local fork for layer caching in CI)
# In CI, this directory is bind-mounted from the checkout step
COPY . /app/hermes

WORKDIR /app/hermes

# Install Python dependencies — all extras including messaging, cron, voice, etc.
RUN uv venv /app/venv --python 3.11 && \
    uv pip install --python /app/venv/bin/python -e ".[all]"

# Install Node.js 22 (required for browser tools + WhatsApp bridge)
RUN curl -fsSL "https://nodejs.org/dist/v22.14.0/node-v22.14.0-linux-x64.tar.xz" | tar xJ -C /usr/local --strip-components=1

# Node dependencies (browser tools, WhatsApp)
RUN npm install --silent

# Install Playwright Chromium (browser automation)
RUN npx playwright install --with-deps chromium

# ============================================================================
# Stage 2: Runtime
# ============================================================================
FROM python:3.11-slim AS runtime

LABEL maintainer="Brandon Mechling <brandon@phatt.tech>"
LABEL description="Hermes Agent — Nous Research AI agent, Unraid-optimized Docker image"
LABEL version="0.5.0"

# Install runtime dependencies only
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ripgrep \
    ffmpeg \
    git \
    sqlite3 \
    && rm -rf /var/lib/apt/lists/*

# Copy virtual environment + Hermes source from builder
COPY --from=builder /app/venv /app/venv
COPY --from=builder /usr/local/bin/node /usr/local/bin/node
COPY --from=builder /usr/local/bin/npm /usr/local/bin/npm
COPY --from=builder /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=builder /app/hermes /app/hermes

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

# Healthcheck — ping the TCP broker port
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD python -c "import socket; s=socket.socket(); s.connect(('127.0.0.1',4077)); s.close()" || exit 1

# Switch to non-root
USER hermes

# Default: interactive shell (use `docker exec` to run hermes)
CMD ["python", "-c", "print('Hermes Agent v0.5.0 ready. Run: docker exec <container> hermes setup')"]
