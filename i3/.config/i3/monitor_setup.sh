#!/bin/bash

PRIMARY_MONITOR="eDP-1"
EXTERNAL_MONITOR="HDMI-1"

# Function to set DPI
set_dpi() {
    local dpi_value=$1
    echo "Xft.dpi: $dpi_value" | xrdb -merge
}

# Detect if the external monitor is connected
if xrandr | grep "$EXTERNAL_MONITOR connected"; then
    # External monitor is connected
    
    # Set DPI to 96 for dual-monitor setup
    set_dpi 180

    # Set the internal monitor to its native resolution
    xrandr --output "$PRIMARY_MONITOR" --mode 2880x1800 --pos 0x0

    # Configure external monitor (HDMI-1) with no scaling
    xrandr --output "$EXTERNAL_MONITOR" --right-of "$PRIMARY_MONITOR" --mode 1920x1080 --scale 1x1

    # Move workspaces to the appropriate monitors
    i3-msg "workspace 1; move workspace to output $PRIMARY_MONITOR"
    i3-msg "workspace 2; move workspace to output $EXTERNAL_MONITOR"
    i3-msg "workspace 3; move workspace to output $PRIMARY_MONITOR"

else
    # External monitor is not connected
    set_dpi 180

    # Set internal monitor to native resolution
    xrandr --output "$PRIMARY_MONITOR" --mode 2880x1800 --pos 0x0

    # Turn off external monitor
    xrandr --output "$EXTERNAL_MONITOR" --off

    # Move all workspaces back to the primary monitor
    for ws in {1..10}; do
        i3-msg "workspace $ws; move workspace to output $PRIMARY_MONITOR"
    done
fi

# Optionally, notify the user of the DPI change
notify-send "Display configuration updated" "DPI set to $(xrdb -query | grep Xft.dpi | awk '{print $2}')"
