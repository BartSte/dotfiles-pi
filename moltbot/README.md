# moltbot

Custom moltbot setup for Raspberry Pi.

⚠️ **Do not store secrets here.** This repo is public.
Store private data in rbw and load it at runtime.

## Files
- `clawdbot.json.template` — redacted config template
- `main` — non‑interactive setup
- `auth` — injects secrets from rbw into `~/.clawdbot/clawdbot.json`

## Required rbw entries
- `telegram_bot_token`
- `brave_search_api_token`
- `clawdbot_gateway_token`
