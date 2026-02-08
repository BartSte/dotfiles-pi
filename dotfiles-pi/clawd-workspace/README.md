# Clawdbot workspace (tracked)

This directory is the tracked source of truth for the live Clawdbot workspace.
It is symlinked to:

- `/home/barts/clawd -> /home/barts/dotfiles-pi/clawd-workspace`

## What to edit here
- `AGENTS.md`, `SOUL.md`, `TOOLS.md`, `HEARTBEAT.md`, `USER.md`, etc.

## What is intentionally excluded
See `.gitignore` for local-only data:
- `memory/`, `tmp/`, `canvas/`, `.clawdbot/`, logs

## Secrets & config hydration
Clawdbot config is templated + hydrated from `rbw` by:

```
~/dotfiles-pi/clawdbot/main
```

That script renders `~/.clawdbot/clawdbot.json` from the template and injects
secrets from `rbw`.

## When config changes
1) Edit files here (or in `/home/barts/clawd` — it’s the same)
2) Run `dotu` to commit/push dotfiles
3) If `clawdbot.json.template` or credentials change, run:
   `~/dotfiles-pi/clawdbot/main`
4) Restart Clawdbot if needed
