Update a Slack notification config setting.

Usage: `/notify-config <key> <value>` where key is `webhook_url` or `debounce_seconds`.

First, resolve the config file path by running: `echo "$HOME/.config/slack-notifications/notify.yaml"` — use the output as the absolute path for all file operations below.

Read the file, then:
- If the file does not exist, let the user know there is no config file to update.
- If no key/value was provided, show the current config values (excluding comments).
- If the key is not `webhook_url` or `debounce_seconds`, let the user know it's not a valid setting.
- If the key is `webhook_url`, validate that the value starts with `https://hooks.slack.com/`. Reject it otherwise.
- If the key is `debounce_seconds`, validate that the value is a positive integer. Reject it otherwise.
- If a line matching `<key>: ...` exists, replace its value with the new value.
- If there is no line for the key, add `<key>: <value>` after the last non-comment, non-empty line.
