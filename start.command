#!/bin/bash
# JoyHarness macOS launcher
# Double-click this file to start JoyHarness.
cd "$(dirname "$0")"
if [ -x ".venv/bin/joyharness" ]; then
  exec ".venv/bin/joyharness" "$@"
fi

exec python3 -m src "$@"
