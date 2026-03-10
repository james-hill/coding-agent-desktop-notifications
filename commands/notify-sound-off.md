Disable notification sounds by setting `sound: false` in the notify config file.

First, resolve the config file path by running: `echo "$HOME/.config/desktop-notifications/notify.yaml"` — use the output as the absolute path for all file operations below.

Read the file, change the `sound:` line from `true` to `false`, and write it back. If there is no sound line, add `sound: false` after the comment header.
