#!/bin/bash
set -e

INSTALL_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_SRC="$INSTALL_DIR/opencode-plugin.ts"
GLOBAL_DIR="$HOME/.config/opencode/plugins"

[ -f "$PLUGIN_SRC" ] || { echo "Error: opencode-plugin.ts not found"; exit 1; }

# Determine install location: project-level or global
if [ "$1" = "--global" ]; then
  DEST_DIR="$GLOBAL_DIR"
else
  DEST_DIR=".opencode/plugins"
fi

mkdir -p "$DEST_DIR"
cp "$PLUGIN_SRC" "$DEST_DIR/bridge-notify.ts"

CONFIG_SRC="$INSTALL_DIR/notify.yaml.template"
CONFIG_DEST="$HOME/.notify.yaml"
if [ ! -f "$CONFIG_DEST" ] && [ -f "$CONFIG_SRC" ]; then
  sed "s|__INSTALL_DIR__|$INSTALL_DIR|g" "$CONFIG_SRC" > "$CONFIG_DEST"
  echo "Config copied to $CONFIG_DEST"
fi

# Install slash commands
COMMANDS_SRC="$INSTALL_DIR/commands"
if [ "$1" = "--global" ]; then
  COMMANDS_DEST="$HOME/.config/opencode/commands"
else
  COMMANDS_DEST=".opencode/commands"
fi
if [ -d "$COMMANDS_SRC" ]; then
  mkdir -p "$COMMANDS_DEST"
  cp "$COMMANDS_SRC"/notify-*.md "$COMMANDS_DEST/"
  echo "Slash commands installed to $COMMANDS_DEST/"
fi

echo "OpenCode plugin installed to $DEST_DIR/bridge-notify.ts"
