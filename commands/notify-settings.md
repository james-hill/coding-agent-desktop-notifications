Show current desktop notification settings from ~/.notify.yaml and explain the available options.

The config file is at ~/.notify.yaml. Read it and display:
- Whether notifications are enabled
- Current port and URL
- Whether sound is enabled
- Whether a custom payload template is set

Available settings:
- `enabled`: true/false to enable/disable notifications entirely (default: true)
- `port`: Port the bridge server runs on (default: 6789)
- `sound`: true/false to enable/disable notification sounds
- `url`: Full URL to POST to (overrides port)
- `payload`: Custom JSON template with ${title}, ${message}, ${sound} variables

Environment variables AGENT_NOTIFY_PORT, AGENT_NOTIFY_URL, AGENT_NOTIFY_SOUND, AGENT_NOTIFY_CONFIG override the file.
