#!/bin/bash

CONFIG_FILE="${AGENT_NOTIFY_CONFIG:-$HOME/.config/desktop-notifications/notify.yaml}"

# Defaults
ENABLED="true"
PORT="6789"
SOUND="true"
URL=""
PAYLOAD_TEMPLATE=""

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
      port) PORT="$value" ;;
      sound) SOUND="$value" ;;
      url) URL="$value" ;;
      payload) PAYLOAD_TEMPLATE="$value" ;;
    esac
  done < "$CONFIG_FILE"
fi

# Exit early if notifications are disabled
if [ "$ENABLED" = "false" ]; then
  exit 0
fi

# Env vars override config file
PORT="${AGENT_NOTIFY_PORT:-$PORT}"
SOUND="${AGENT_NOTIFY_SOUND:-$SOUND}"
URL="${AGENT_NOTIFY_URL:-${URL:-http://host.docker.internal:${PORT}/notify}}"

read_stdin() {
  if [ ! -t 0 ]; then
    local input
    input=$(timeout 1 cat 2>/dev/null || true)
    if [ -n "$input" ]; then
      echo "$input"
    fi
  fi
}

build_payload() {
  local title="$1"
  local message="$2"

  if [ -n "$PAYLOAD_TEMPLATE" ]; then
    echo "$PAYLOAD_TEMPLATE" \
      | sed "s|\${title}|$(echo "$title" | sed 's/[&/\]/\\&/g')|g" \
      | sed "s|\${message}|$(echo "$message" | sed 's/[&/\]/\\&/g')|g" \
      | sed "s|\${sound}|$SOUND|g"
  else
    printf '{"title":"%s","message":"%s","sound":%s}' \
      "$(echo "$title" | sed 's/"/\\"/g')" \
      "$(echo "$message" | sed 's/"/\\"/g')" \
      "$SOUND"
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
  message="$(basename "$project_dir")"

  local payload
  payload=$(build_payload "$title" "$message")

  curl -sf -X POST "$URL" \
    -H "Content-Type: application/json" \
    -d "$payload" >/dev/null 2>&1

  echo "Notification sent: ${title} - ${message}"
}

main "$@"
