# Coding Agent Slack Notifications

Slack notifications for AI coding agents. Get notified in Slack when your agent finishes a task, encounters an error, or needs your input.

Works with [Claude Code](https://docs.anthropic.com/en/docs/claude-code) and [OpenCode](https://opencode.ai).

## Prerequisites

A [Slack incoming webhook URL](https://api.slack.com/messaging/webhooks). Create one in your Slack workspace settings.

## Installation

```bash
git clone https://github.com/james-hill/coding-agent-slack-notifications.git
cd coding-agent-slack-notifications
```

### Claude Code

```bash
./install-claudecode.sh
```

This registers hooks in `~/.claude/settings.json` that fire on `Stop` and `Notification` events.

### OpenCode

```bash
./install-opencode.sh
```

This copies the TypeScript plugin to `~/.config/opencode/plugins/`. The plugin listens for `session.idle`, `session.error`, and `permission.asked` events.

Both installers copy `notify.yaml.template` to `~/.config/slack-notifications/notify.yaml` if it doesn't already exist. They also install slash commands so you can manage notifications from within your agent.

## Configuration

The easiest way to configure is with the `/notify-config` slash command from within your agent session:

```
/notify-config webhook_url https://hooks.slack.com/services/YOUR/WEBHOOK/URL
/notify-config debounce_seconds 5
/notify-config                   # show current values
```

You can also edit `~/.config/slack-notifications/notify.yaml` directly:

```yaml
enabled: true
webhook_url: https://hooks.slack.com/services/YOUR/WEBHOOK/URL
debounce_seconds: 10
```

| Key | Default | Description |
|---|---|---|
| `enabled` | `false` | Enable or disable notifications entirely |
| `webhook_url` | _(none)_ | Slack incoming webhook URL |
| `debounce_seconds` | `10` | Debounce window — waits this many seconds and only sends if no newer event occurs |

Environment variables override config file values. Set them in your shell profile (e.g. `~/.zshrc`) or in a `.env` file if you're using Docker Compose.

| Variable | Overrides |
|---|---|
| `SLACK_NOTIFICATIONS_WEBHOOK` | `webhook_url` |
| `SLACK_NOTIFICATIONS_DEBOUNCE_SECONDS` | `debounce_seconds` |

## Slash Commands

These are installed automatically and available inside your agent session:

| Command | Description |
|---|---|
| `/notify-on` | Enable notifications |
| `/notify-off` | Disable notifications |
| `/notify-config <key> <value>` | Update `webhook_url` or `debounce_seconds` |
| `/notify-config` | Show current config values |

## Files

| File | Description |
|---|---|
| `notify.py` | Shared notification script that posts to Slack |
| `notify.yaml.template` | Config template (copied to `~/.config/slack-notifications/notify.yaml` on install) |
| `install-claudecode.sh` | Installer for Claude Code hooks |
| `opencode-plugin.ts` | OpenCode plugin (TypeScript) |
| `install-opencode.sh` | Installer for OpenCode plugin |
| `commands/` | Slash command definitions installed for agent use |
