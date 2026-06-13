#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "LaunchAgent uninstall is macOS-only." >&2
  exit 1
fi

LABEL="com.joyharness.agent"
PLIST_PATH="$HOME/Library/LaunchAgents/$LABEL.plist"
USER_DOMAIN="gui/$(id -u)"

if launchctl print "$USER_DOMAIN/$LABEL" >/dev/null 2>&1; then
  launchctl bootout "$USER_DOMAIN" "$PLIST_PATH" >/dev/null 2>&1 || true
fi

rm -f "$PLIST_PATH"

echo "Uninstalled $LABEL"
