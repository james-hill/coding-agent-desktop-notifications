#!/bin/bash

CONFIG_FILE="${AGENT_NOTIFY_CONFIG:-$HOME/.config/slack-notifications/notify.yaml}"

# Defaults
ENABLED="true"
WEBHOOK_URL=""

# Parse simple YAML (flat key: value only)
if [ -f "$CONFIG_FILE" ]; then
  while IFS= read -r line; do
    # Skip comments and blank lines
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ -z "${line// }" ]] && continue

    key=$(echo "$line" | sed "s/^\([^:]*\):.*/\1/" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    value=$(echo "$line" | sed "s/^[^:]*:[[:space:]]*//" | sed "s/^['\"]//;s/['\"]$//")

    case "$key" in
      enabled) ENABLED="$value" ;;
      webhook_url) WEBHOOK_URL="$value" ;;
    esac
  done < "$CONFIG_FILE"
fi

# Exit early if notifications are disabled
if [ "$ENABLED" = "false" ]; then
  exit 0
fi

# Env var overrides config file
WEBHOOK_URL="${SLACK_NOTIFICATIONS_WEBHOOK:-$WEBHOOK_URL}"

if [ -z "$WEBHOOK_URL" ]; then
  echo "Error: No webhook URL configured" >&2
  exit 1
fi

read_stdin() {
  if [ ! -t 0 ]; then
    local input
    input=$(timeout 1 cat 2>/dev/null || true)
    if [ -n "$input" ]; then
      echo "$input"
    fi
  fi
}

main() {
  local stdin_data
  stdin_data=$(read_stdin)

  local title="${1:-Agent Needs Input}"

  # Use project directory name as the message
  local project_dir=""
  if [ -n "$stdin_data" ]; then
    project_dir=$(echo "$stdin_data" | grep -o '"cwd"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*: *"//;s/"$//')
  fi
  project_dir="${project_dir:-$PWD}"
  local project_name
  project_name="$(basename "$project_dir")"

  local payload
  payload=$(printf '{"text":"%s: %s","blocks":[{"type":"section","text":{"type":"mrkdwn","text":"*%s*\\n*Project:* %s"}}]}' \
    "$(echo "$title" | sed 's/"/\\"/g')" \
    "$(echo "$project_name" | sed 's/"/\\"/g')" \
    "$(echo "$title" | sed 's/"/\\"/g')" \
    "$(echo "$project_name" | sed 's/"/\\"/g')")

  curl -sf -X POST "$WEBHOOK_URL" \
    -H "Content-Type: application/json" \
    -d "$payload" >/dev/null 2>&1

  echo "Notification sent: ${title} - ${project_name}"
}

main "$@"
