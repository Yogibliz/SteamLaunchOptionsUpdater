#!/bin/bash

# ---------------------------------------------------------
# CONFIGURATION
# ---------------------------------------------------------

# Path to steamapps library
LIBRARY_PATH="/run/media/Games/SteamLibrary/steamapps"
NEW_LAUNCH_OPTIONS="game-performance %command%"

# ---------------------------------------------------------
# SCRIPT
# ---------------------------------------------------------

# Define Steam Config Path
if [[ -d "$HOME/.local/share/Steam" ]]; then
  STEAMPATH="$HOME/.local/share/Steam"
# Can add path to flatpak version here, don't use it personally, no idea where it's at.
else
  echo "Error: Steam config folder not found."
  exit 1
fi

echo "Steam config path located: $STEAMPATH"

# Find localconfig.vdf
LOCALCONF_FIND=$(find "${STEAMPATH}/userdata"/*/config -type f -name "localconfig.vdf")
confs=($LOCALCONF_FIND)

if [[ ${#confs[@]} -eq 0 ]]; then
  echo "Error: No localconfig.vdf found."
  exit 1
elif [[ ${#confs[@]} -eq 1 ]]; then
  LOCALCONF=${confs[0]}
else
  echo "Multiple accounts found. Using the first one found:"
  LOCALCONF=${confs[0]}
fi

echo "Targeting Config: $LOCALCONF"

# Auto-Detect Installed Games
echo "Scanning library at: $LIBRARY_PATH"

if [[ ! -d "$LIBRARY_PATH" ]]; then
  echo "Error: Library path not found!"
  echo "Please edit LIBRARY_PATH to match Steam Library location."
  exit 1
fi

DETECTED_APPIDS=($(ls "$LIBRARY_PATH"/appmanifest_*.acf 2>/dev/null | sed -E 's/.*appmanifest_([0-9]+)\.acf/\1/'))

if [[ ${#DETECTED_APPIDS[@]} -eq 0 ]]; then
  echo "Error: No installed games found in $LIBRARY_PATH"
  exit 1
fi

echo "Found ${#DETECTED_APPIDS[@]} installed games."

# We check for the main steam process. If found, we enter a loop.
if pgrep -x "steam" >/dev/null; then
  echo "----------------------------------------------------------------"
  echo "WARNING: Steam is currently running!"
  echo "You MUST close Steam before running this update."
  echo "----------------------------------------------------------------"

  # Loop until 'steam' process is no longer found
  while pgrep -x "steam" >/dev/null; do
    read -p "Waiting... Please close Steam and press Enter to try again..."
    if pgrep -x "steam" >/dev/null; then
      echo -e "\033[0;31mSteam is STILL running.\033[0m"
    else
      echo -e "\033[0;32mSteam closed detected.\033[0m"
      sleep 1 # Give it a second to release file locks
    fi
  done
fi

# Run Python Script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "Launching Python worker..."

"$SCRIPT_DIR/venv/bin/python3" "$SCRIPT_DIR/update_launchops.py" "$LOCALCONF" "$NEW_LAUNCH_OPTIONS" "${DETECTED_APPIDS[@]}"

echo "Done."
