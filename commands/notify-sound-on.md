Enable notification sounds by setting `sound: true` in the notify config file. Also set `enabled: true` if it is currently `false`, since wanting sound implies wanting notifications.

First, resolve the config file path by running: `echo "$HOME/.config/desktop-notifications/notify.yaml"` — use the output as the absolute path for all file operations below.

Read the file, change the `sound:` line from `false` to `true`, and write it back. If there is no sound line, add `sound: true` after the comment header. Also change `enabled: false` to `enabled: true` if present.
