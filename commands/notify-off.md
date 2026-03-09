Disable desktop notifications by setting `enabled: false` in ~/.notify.yaml.

If ~/.notify.yaml does not exist, let the user know there is no config file to update.
If there is no `enabled` line, add `enabled: false` at the top of the file (after any leading comments).
If `enabled: true` exists, change it to `enabled: false`.
If `enabled: false` already exists, let the user know notifications are already disabled.
