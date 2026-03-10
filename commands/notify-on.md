Re-enable Slack notifications by setting `enabled: true` in the notify config file.

First, resolve the config file path by running: `echo "$HOME/.config/slack-notifications/notify.yaml"` — use the output as the absolute path for all file operations below.

Read the file, then:
- If the file does not exist, let the user know there is no config file to update.
- If `enabled: true` already exists, let the user know notifications are already enabled.
- If `enabled: false` exists, change it to `enabled: true`.
- If there is no `enabled` line, add `enabled: true` at the top of the file (after any leading comments).
