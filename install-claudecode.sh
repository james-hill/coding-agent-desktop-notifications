#!/bin/bash
set -e

INSTALL_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$INSTALL_DIR/notify.sh"
SETTINGS="$HOME/.claude/settings.json"

[ -f "$SCRIPT" ] || { echo "Error: notify.sh not found"; exit 1; }

mkdir -p "$HOME/.claude"
[ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"

# Use python3 (available on macOS by default) to update JSON
python3 -c "
import json, sys

with open('$SETTINGS') as f:
    s = json.load(f)

s.setdefault('hooks', {})

def hook(args):
    return [{'matcher': '', 'hooks': [{'type': 'command', 'command': '\"$SCRIPT\" ' + args}]}]

s['hooks']['Stop'] = hook('\"Claude Stopped\"')
s['hooks']['Notification'] = hook('\"Claude Notification\"')

with open('$SETTINGS', 'w') as f:
    json.dump(s, f, indent=2)
    f.write('\n')
"

CONFIG_SRC="$INSTALL_DIR/notify.yaml.template"
CONFIG_DEST="$HOME/.config/desktop-notifications/notify.yaml"
if [ ! -f "$CONFIG_DEST" ] && [ -f "$CONFIG_SRC" ]; then
  mkdir -p "$(dirname "$CONFIG_DEST")"
  sed "s|__INSTALL_DIR__|$INSTALL_DIR|g" "$CONFIG_SRC" > "$CONFIG_DEST"
  echo "Config copied to $CONFIG_DEST"
fi

# Install slash commands
COMMANDS_SRC="$INSTALL_DIR/commands"
COMMANDS_DEST="$HOME/.claude/commands"
if [ -d "$COMMANDS_SRC" ]; then
  mkdir -p "$COMMANDS_DEST"
  cp "$COMMANDS_SRC"/notify-*.md "$COMMANDS_DEST/"
  echo "Slash commands installed to $COMMANDS_DEST/"
fi

echo "Claude Code hooks installed to $SETTINGS"
