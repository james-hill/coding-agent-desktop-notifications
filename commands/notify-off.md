Disable desktop notifications by setting `enabled: false` in the notify config file.

The config file path is: `$HOME/.notify.yaml` (use the HOME environment variable to resolve the absolute path).

Read the file, then:
- If the file does not exist, let the user know there is no config file to update.
- If `enabled: false` already exists, let the user know notifications are already disabled.
- If `enabled: true` exists, change it to `enabled: false`.
- If there is no `enabled` line, add `enabled: false` at the top of the file (after any leading comments).
