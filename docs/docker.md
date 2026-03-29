# Hermes Agent — Docker

Run Hermes Agent in a container without installing anything on your host.

All user data (config, API keys, sessions, skills, memories) lives in a single
directory mounted from the host at `/opt/data`. The image itself is stateless —
upgrade by pulling a new version without losing any configuration.

## Quick start

Create a data directory and start the container interactively:

```sh
mkdir -p ~/.hermes
docker run -it --rm \
  -v ~/.hermes:/opt/data \
  nousresearch/hermes-agent
```

First run drops you into the setup wizard. It writes your API keys to
`~/.hermes/.env`. You only need to do this once.

## Running in gateway mode

Once configured, run the gateway (Telegram, Discord, Slack, WhatsApp, etc.)
as a persistent background container:

```sh
docker run -d \
  --name hermes \
  --restart unless-stopped \
  -v ~/.hermes:/opt/data \
  nousresearch/hermes-agent gateway run
```

## Interactive CLI chat

Open a one-off chat session against your existing data directory:

```sh
docker run -it --rm \
  -v ~/.hermes:/opt/data \
  nousresearch/hermes-agent
```

Or send a single message:

```sh
docker run -it --rm \
  -v ~/.hermes:/opt/data \
  nousresearch/hermes-agent chat -q "What tools do you have?"
```

## Upgrading

Pull the latest image and recreate the container. Your data directory is
untouched:

```sh
docker pull nousresearch/hermes-agent:latest
docker rm -f hermes
docker run -d \
  --name hermes \
  --restart unless-stopped \
  -v ~/.hermes:/opt/data \
  nousresearch/hermes-agent gateway run
```

## Building from source

```sh
git clone https://github.com/NousResearch/hermes-agent.git
cd hermes-agent
docker build -t hermes-agent .
docker run -it --rm -v ~/.hermes:/opt/data hermes-agent
```

## Environment variables

Pass additional environment variables with `-e`:

```sh
docker run -it --rm \
  -v ~/.hermes:/opt/data \
  -e OPENROUTER_API_KEY=sk-or-... \
  nousresearch/hermes-agent
```

Or put them in `~/.hermes/.env` (auto-loaded by the entrypoint).

## What's in the image

- Python 3.11 with all Hermes dependencies (messaging, MCP, voice, etc.)
- Node.js 20 (for WhatsApp bridge and MCP servers)
- ripgrep (fast file search)
- ffmpeg (voice/TTS processing)
- git (for worktree mode and code operations)

Browser automation (Playwright/Chromium) is **not** included in the default
image to keep it small. Use Browserbase or `/browser connect` (CDP) for
browser tasks.
