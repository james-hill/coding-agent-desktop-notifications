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

This registers shell hooks in `~/.claude/settings.json` that fire on `Stop` and `Notification` events.

### OpenCode

```bash
# Install to current project
./install-opencode.sh

# Install globally
./install-opencode.sh --global
```

This copies the TypeScript plugin to `.opencode/plugins/` (project) or `~/.config/opencode/plugins/` (global). The plugin listens for `session.idle`, `session.error`, and `permission.asked` events.

Both installers copy `notify.yaml.template` to `~/.config/slack-notifications/notify.yaml` if it doesn't already exist. They also install slash commands so you can manage notifications from within your agent.

## Configuration

Edit `~/.config/slack-notifications/notify.yaml`:

```yaml
enabled: true
webhook_url: https://hooks.slack.com/services/YOUR/WEBHOOK/URL
```

| Key | Default | Description |
|---|---|---|
| `enabled` | `true` | Enable or disable notifications entirely |
| `webhook_url` | _(none)_ | Slack incoming webhook URL |

The environment variable `SLACK_NOTIFICATIONS_WEBHOOK` overrides the config file.

## Slash Commands

These are installed automatically and available inside your agent session:

| Command | Description |
|---|---|
| `/notify-off` | Disable notifications |
| `/notify-on` | Re-enable notifications |

## Files

| File | Description |
|---|---|
| `notify.sh` | Shared notification script that posts to Slack |
| `notify.yaml.template` | Config template (copied to `~/.config/slack-notifications/notify.yaml` on install) |
| `install-claudecode.sh` | Installer for Claude Code hooks |
| `opencode-plugin.ts` | OpenCode plugin (TypeScript) |
| `install-opencode.sh` | Installer for OpenCode plugin |
| `commands/` | Slash command definitions installed for agent use |
