Disable Slack notifications by setting `enabled: false` in the notify config file.

First, resolve the config file path by running: `echo "$HOME/.config/slack-notifications/notify.yaml"` — use the output as the absolute path for all file operations below.

Read the file, then:
- If the file does not exist, let the user know there is no config file to update.
- If `enabled: false` already exists, let the user know notifications are already disabled.
- If `enabled: true` exists, change it to `enabled: false`.
- If there is no `enabled` line, add `enabled: false` at the top of the file (after any leading comments).
