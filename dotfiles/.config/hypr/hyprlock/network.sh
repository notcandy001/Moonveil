#!/bin/bash

# Set this variable to control the output
# Set to "true" to show SSID, "false" to show "Connected"
# show_ssid=false

# Read the wifi-mode alias from hyprlock.conf
show_ssid=$(grep -oP '^\$wifi-mode\s*=\s*\K\S+' ~/.config/hypr/hyprlock.conf)

# Check if the SSID was successfully extracted else fallback?!
if [ -z "$show_ssid" ]; then
  show_ssid=false
fi

# Check if any Ethernet connection is active
ethernet_connected=$(nmcli -t -f DEVICE,TYPE,STATE dev | grep -E 'ethernet:connected')

# If Ethernet
if [ -n "$ethernet_connected" ]; then
    echo "󰈀  Ethernet"
    exit 0
fi

# Get Wi-Fi connection status
wifi_status=$(nmcli -t -f WIFI g)

# Check if Wi-Fi is enabled
if [ "$wifi_status" != "enabled" ]; then
    echo "󰤮  Wi-Fi Off"
    exit 0
fi

# Get active Wi-Fi connection details
wifi_info=$(nmcli -t -f ACTIVE,SSID,SIGNAL dev wifi | grep '^yes')

# If no active connection, show "Disconnected"
if [ -z "$wifi_info" ]; then
    echo "󰤮  No Wi-Fi"
    exit 0
fi

# Extract SSID
ssid=$(echo "$wifi_info" | cut -d':' -f2)

# Extract signal strength
signal_strength=$(echo "$wifi_info" | cut -d':' -f3)

# Define Wi-Fi icons based on signal strength
wifi_icons=("󰤯" "󰤟" "󰤢" "󰤥" "󰤨") # From low to high signal

# Clamp signal strength between 0 and 100
signal_strength=$((signal_strength < 0 ? 0 : (signal_strength > 100 ? 100 : signal_strength)))

# Calculate the icon index based on signal strength
icon_index=$((signal_strength / 25))

# Get the corresponding icon
wifi_icon=${wifi_icons[$icon_index]}

# Output based on show_ssid variable
if [ "$show_ssid" = true ]; then
    echo "$wifi_icon  $ssid"
else
    echo "$wifi_icon  Connected"
fi
