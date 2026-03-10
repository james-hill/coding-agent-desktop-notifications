Re-enable desktop notifications by setting `enabled: true` in the notify config file.

The config file path is: `$HOME/.notify.yaml` (use the HOME environment variable to resolve the absolute path).

Read the file, then:
- If the file does not exist, let the user know there is no config file to update.
- If `enabled: true` already exists, let the user know notifications are already enabled.
- If `enabled: false` exists, change it to `enabled: true`.
- If there is no `enabled` line, add `enabled: true` at the top of the file (after any leading comments).
