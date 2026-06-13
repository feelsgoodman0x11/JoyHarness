#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "LaunchAgent install is macOS-only." >&2
  exit 1
fi

LABEL="com.joyharness.agent"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PYTHON_BIN="$ROOT_DIR/.venv/bin/python"
if [[ ! -x "$PYTHON_BIN" ]]; then
  PYTHON_BIN="$(command -v python3)"
fi
JOYHARNESS_BIN="$ROOT_DIR/.venv/bin/joyharness"

if [[ -x "$JOYHARNESS_BIN" ]]; then
  PROGRAM_ARGS="    <string>$JOYHARNESS_BIN</string>"
else
  PROGRAM_ARGS="    <string>$PYTHON_BIN</string>
    <string>-m</string>
    <string>src</string>"
fi

LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
LOG_DIR="$HOME/Library/Logs/JoyHarness"
PLIST_PATH="$LAUNCH_AGENTS_DIR/$LABEL.plist"
USER_DOMAIN="gui/$(id -u)"

mkdir -p "$LAUNCH_AGENTS_DIR" "$LOG_DIR"

cat > "$PLIST_PATH" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$LABEL</string>

  <key>ProgramArguments</key>
  <array>
$PROGRAM_ARGS
  </array>

  <key>WorkingDirectory</key>
  <string>$ROOT_DIR</string>

  <key>RunAtLoad</key>
  <true/>

  <key>KeepAlive</key>
  <true/>

  <key>ThrottleInterval</key>
  <integer>5</integer>

  <key>LimitLoadToSessionType</key>
  <string>Aqua</string>

  <key>EnvironmentVariables</key>
  <dict>
    <key>PATH</key>
    <string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
    <key>PYTHONUNBUFFERED</key>
    <string>1</string>
  </dict>

  <key>StandardOutPath</key>
  <string>$LOG_DIR/stdout.log</string>

  <key>StandardErrorPath</key>
  <string>$LOG_DIR/stderr.log</string>
</dict>
</plist>
PLIST

if launchctl print "$USER_DOMAIN/$LABEL" >/dev/null 2>&1; then
  launchctl bootout "$USER_DOMAIN" "$PLIST_PATH" >/dev/null 2>&1 || true
fi

launchctl bootstrap "$USER_DOMAIN" "$PLIST_PATH"
launchctl enable "$USER_DOMAIN/$LABEL"
launchctl kickstart -k "$USER_DOMAIN/$LABEL"

echo "Installed and started $LABEL"
echo "Plist: $PLIST_PATH"
echo "Logs:  $LOG_DIR/stdout.log"
echo "       $LOG_DIR/stderr.log"
