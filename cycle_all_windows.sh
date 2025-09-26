#!/bin/bash
# A script to cycle through all open windows across all workspaces in Hyprland.

# The script accepts one argument: "next" or "prev"
DIRECTION=$1

# Get a list of all window addresses in JSON format and parse them into a Bash array.
# The 'map(.address)' part ensures we only get the addresses.
WINDOWS=($(hyprctl clients -j | jq -r 'map(.address) | .[]'))
NUM_WINDOWS=${#WINDOWS[@]}

# Get the address of the currently active window.
ACTIVE_WINDOW=$(hyprctl activewindow -j | jq -r '.address')

# Find the index of the active window in our list.
for i in "${!WINDOWS[@]}"; do
    if [[ "${WINDOWS[$i]}" == "$ACTIVE_WINDOW" ]]; then
        ACTIVE_INDEX=$i
        break
    fi
done

# Calculate the index of the next or previous window.
# The modulo operator (%) ensures the index wraps around the array.
if [[ "$DIRECTION" == "next" ]]; then
    NEW_INDEX=$(( (ACTIVE_INDEX + 1) % NUM_WINDOWS ))
elif [[ "$DIRECTION" == "prev" ]]; then
    # The +NUM_WINDOWS is a trick to handle negative numbers correctly in Bash's modulo.
    NEW_INDEX=$(( (ACTIVE_INDEX - 1 + NUM_WINDOWS) % NUM_WINDOWS ))
else
    exit 1 # Exit if the argument is invalid
fi

# Get the address of the target window using the new index.
TARGET_WINDOW=${WINDOWS[$NEW_INDEX]}

# Use hyprctl to focus the target window.
# This will automatically switch to the correct workspace.
hyprctl dispatch focuswindow address:$TARGET_WINDOW

