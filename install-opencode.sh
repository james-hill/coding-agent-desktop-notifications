#!/bin/bash
set -e

INSTALL_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_SRC="$INSTALL_DIR/opencode-plugin.ts"
DEST_DIR="$HOME/.config/opencode/plugins"

[ -f "$PLUGIN_SRC" ] || { echo "Error: opencode-plugin.ts not found"; exit 1; }

mkdir -p "$DEST_DIR"
cp "$PLUGIN_SRC" "$DEST_DIR/desktop-notifications.ts"

# Ensure package.json exists with the plugin dependency
PARENT_DIR="$(dirname "$DEST_DIR")"
PKG_FILE="$PARENT_DIR/package.json"
if [ ! -f "$PKG_FILE" ]; then
  cat > "$PKG_FILE" <<'PKGJSON'
{
  "dependencies": {
    "@opencode-ai/plugin": "latest"
  }
}
PKGJSON
  echo "Created $PKG_FILE with plugin dependency"
fi

CONFIG_SRC="$INSTALL_DIR/notify.yaml.template"
CONFIG_DEST="$HOME/.notify.yaml"
if [ ! -f "$CONFIG_DEST" ] && [ -f "$CONFIG_SRC" ]; then
  sed "s|__INSTALL_DIR__|$INSTALL_DIR|g" "$CONFIG_SRC" > "$CONFIG_DEST"
  echo "Config copied to $CONFIG_DEST"
fi

# Install slash commands
COMMANDS_SRC="$INSTALL_DIR/commands"
COMMANDS_DEST="$HOME/.config/opencode/commands"
if [ -d "$COMMANDS_SRC" ]; then
  mkdir -p "$COMMANDS_DEST"
  cp "$COMMANDS_SRC"/notify-*.md "$COMMANDS_DEST/"
  echo "Slash commands installed to $COMMANDS_DEST/"
fi

echo "OpenCode plugin installed to $DEST_DIR/desktop-notifications.ts"
