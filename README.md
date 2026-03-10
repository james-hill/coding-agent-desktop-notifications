# Coding Agent Desktop Notifications

Desktop notifications for AI coding agents. Capable of being used from within a container because of course you should be running your coding agent inside a sandbox container! Get notified when your agent finishes a task, encounters an error, or needs your input.

Works with [Claude Code](https://docs.anthropic.com/en/docs/claude-code) and [OpenCode](https://opencode.ai).

## Prerequisites

A notification bridge server running locally, such as [desktop-notifications-from-container](https://github.com/james-hill/desktop-notifications-from-container) or any HTTP server accepting POST requests.

By default the plugin sends JSON payloads to `http://localhost:6789/notify`:

```json
{
  "title": "Agent Stopped",
  "message": "Agent has finished and is waiting for input",
  "sound": true
}
```

## Installation

```bash
git clone https://github.com/james-hill/coding-agent-desktop-notifications.git
cd coding-agent-desktop-notifications
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

Both installers copy `notify.yaml.template` to `~/.config/desktop-notifications/notify.yaml` if it doesn't already exist. They also install slash commands so you can manage notifications from within your agent.

## Configuration

Edit `~/.config/desktop-notifications/notify.yaml`:

```yaml
enabled: true
port: 6789
sound: true
# url: http://localhost:6789/notify

# Custom JSON payload template.
# Available variables: ${title}, ${message}, ${sound}
# payload: '{"title":"${title}","message":"${message}","sound":${sound}}'
```

| Key | Default | Description |
|---|---|---|
| `enabled` | `true` | Enable or disable notifications entirely |
| `port` | `6789` | Port the bridge server is running on |
| `sound` | `true` | Enable notification sounds |
| `url` | `http://localhost:{port}/notify` | Full URL to POST notifications to (overrides port) |
| `payload` | _(built-in JSON)_ | Custom JSON template with `${title}`, `${message}`, `${sound}` substitution |

Environment variables (`AGENT_NOTIFY_PORT`, `AGENT_NOTIFY_URL`, `AGENT_NOTIFY_SOUND`, `AGENT_NOTIFY_CONFIG`) override the config file.

## Slash Commands

These are installed automatically and available inside your agent session:

| Command | Description |
|---|---|
| `/notify-settings` | Show current notification config |
| `/notify-off` | Disable notifications |
| `/notify-on` | Re-enable notifications |
| `/notify-sound-off` | Disable notification sounds |
| `/notify-sound-on` | Enable notification sounds |

## Files

| File | Description |
|---|---|
| `notify.sh` | Shared notification script that sends payloads to the bridge |
| `notify.yaml.template` | Config template (copied to `~/.config/desktop-notifications/notify.yaml` on install) |
| `install-claudecode.sh` | Installer for Claude Code hooks |
| `opencode-plugin.ts` | OpenCode plugin (TypeScript) |
| `install-opencode.sh` | Installer for OpenCode plugin |
| `commands/` | Slash command definitions installed for agent use |
