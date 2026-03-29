# ─────────────────────────────────────────────────────────────
# Hermes Agent — Docker image
# ─────────────────────────────────────────────────────────────
# Multi-stage build: builder installs everything, runtime is slim.
#
#   docker build -t hermes-agent .
#   docker run -it --rm -v ~/.hermes:/opt/data hermes-agent
#
# See docs/docker.md for full usage guide.
# ─────────────────────────────────────────────────────────────

# ── Stage 1: Builder ────────────────────────────────────────
FROM python:3.11-slim AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
        gcc python3-dev libffi-dev git curl \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js (needed for WhatsApp bridge, MCP servers, npm packages)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/hermes

# Install Python deps first (layer cache — only rebuilds when deps change)
COPY pyproject.toml setup.cfg* setup.py* ./
COPY agent/ agent/
COPY tools/ tools/
COPY hermes_cli/ hermes_cli/
COPY gateway/ gateway/
COPY cron/ cron/
COPY honcho_integration/ honcho_integration/
COPY acp_adapter/ acp_adapter/
COPY run_agent.py model_tools.py toolsets.py batch_runner.py cli.py \
     hermes_constants.py hermes_state.py hermes_time.py rl_cli.py \
     trajectory_compressor.py toolset_distributions.py utils.py ./

RUN python -m venv /opt/venv \
    && /opt/venv/bin/pip install --no-cache-dir -e ".[all]"

# Install npm dependencies (WhatsApp bridge, etc.)
COPY package.json package-lock.json* ./
RUN npm install --omit=dev 2>/dev/null || true

# ── Stage 2: Runtime ────────────────────────────────────────
FROM python:3.11-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
        ripgrep ffmpeg git curl \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js runtime (no build tools needed)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

# Copy venv and app from builder
COPY --from=builder /opt/venv /opt/venv
COPY --from=builder /opt/hermes /opt/hermes

WORKDIR /opt/hermes

# Put venv on PATH so `hermes` command is available
ENV PATH="/opt/venv/bin:$PATH" \
    VIRTUAL_ENV="/opt/venv" \
    HERMES_HOME="/opt/data" \
    PYTHONUNBUFFERED=1

# Copy supporting files
COPY skills/ skills/
COPY optional-skills/ optional-skills/
COPY docker/ docker/
COPY .env.example ./
COPY cli-config.yaml.example ./

RUN chmod +x /opt/hermes/docker/entrypoint.sh

VOLUME ["/opt/data"]
ENTRYPOINT ["/opt/hermes/docker/entrypoint.sh"]
