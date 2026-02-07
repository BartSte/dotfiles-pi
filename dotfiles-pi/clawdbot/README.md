# Clawdbot config (redacted)

This module installs Clawdbot config files and hydrates secrets from `rbw`.

## Secrets expected in rbw
- `brave_search_api_token`
- `clawdbot_telegram_bot_token`
- `clawdbot_gateway_token`

## What is included
- `clawdbot.json` (template, secrets injected on install)
- `cron/jobs.json`
- `credentials/telegram-allowFrom.json`

## What is intentionally excluded
- Pairing/device identity files (e.g. `devices/paired.json`, `identity/device*.json`)
- Telegram pairing credentials

These can be re-created via the Clawdbot setup wizard / pairing flow.
