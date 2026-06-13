#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "LaunchAgent status is macOS-only." >&2
  exit 1
fi

LABEL="com.joyharness.agent"
USER_DOMAIN="gui/$(id -u)"
LOG_DIR="$HOME/Library/Logs/JoyHarness"

launchctl print "$USER_DOMAIN/$LABEL"
echo
echo "Logs:"
echo "  $LOG_DIR/stdout.log"
echo "  $LOG_DIR/stderr.log"
