Re-enable desktop notifications by setting `enabled: true` in ~/.notify.yaml.

If ~/.notify.yaml does not exist, let the user know there is no config file to update.
If there is no `enabled` line, add `enabled: true` at the top of the file (after any leading comments).
If `enabled: false` exists, change it to `enabled: true`.
If `enabled: true` already exists, let the user know notifications are already enabled.
