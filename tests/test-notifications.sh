#!/bin/bash
# Test script for Slack notifications.
# Sends test events through notify.py to verify formatting and delivery.
#
# Usage:
#   ./test-notifications.sh              # run all tests
#   ./test-notifications.sh stop         # run a single test
#   ./test-notifications.sh --dry-run    # show payloads without sending

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NOTIFY="$SCRIPT_DIR/notify.py"
PROJECT_DIR="$SCRIPT_DIR"

DRY_RUN=false
FILTER=""

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    *) FILTER="$arg" ;;
  esac
done

# Temporarily enable notifications with zero debounce for testing
CONFIG="$HOME/.config/slack-notifications/notify.yaml"
if [ -f "$CONFIG" ]; then
  ORIG_CONFIG=$(cat "$CONFIG")
  trap 'echo "$ORIG_CONFIG" > "$CONFIG"; echo "Config restored."' EXIT
fi

enable_test_config() {
  if [ -f "$CONFIG" ]; then
    # Set enabled: true and debounce_seconds: 0 for instant delivery
    sed -i.bak 's/enabled: false/enabled: true/' "$CONFIG"
    if grep -q "debounce_seconds" "$CONFIG"; then
      sed -i.bak 's/debounce_seconds:.*/debounce_seconds: 0/' "$CONFIG"
    else
      echo "debounce_seconds: 0" >> "$CONFIG"
    fi
    rm -f "$CONFIG.bak"
  fi
}

send_test() {
  local name="$1"
  local title="$2"
  local json="$3"

  if [ -n "$FILTER" ] && [ "$FILTER" != "$name" ]; then
    return
  fi

  echo "--- $name ---"
  if [ "$DRY_RUN" = true ]; then
    echo "  Title: $title"
    echo "  Payload: $json"
    echo ""
    return
  fi

  if echo "$json" | python3 "$NOTIFY" "$title" 2>&1; then
    echo "  OK"
  else
    echo "  FAILED (exit $?)"
  fi
  echo ""
  sleep 1
}

enable_test_config

echo "Sending test notifications..."
echo ""

send_test "stop" "Claude Stopped" \
  "{\"hook_event_name\": \"Stop\", \"cwd\": \"$PROJECT_DIR\", \"last_assistant_message\": \"I finished refactoring the notification module and updated the tests.\"}"

send_test "notification" "Claude Notification" \
  "{\"hook_event_name\": \"Notification\", \"cwd\": \"$PROJECT_DIR\", \"message\": \"I need permission to run: rm -rf node_modules && npm install\"}"

send_test "unknown-event" "Agent Alert" \
  "{\"hook_event_name\": \"SomeNewEvent\", \"cwd\": \"$PROJECT_DIR\"}"

send_test "no-detail" "Claude Stopped" \
  "{\"hook_event_name\": \"Stop\", \"cwd\": \"$PROJECT_DIR\"}"

send_test "long-message" "Claude Stopped" \
  "{\"hook_event_name\": \"Stop\", \"cwd\": \"$PROJECT_DIR\", \"last_assistant_message\": \"$(python3 -c "print('This is a very long message that should be truncated. ' * 20)")\"}"

send_test "no-json" "Claude Stopped" \
  "not valid json"

send_test "cancel" "--cancel" \
  "{}"

echo "Done."
