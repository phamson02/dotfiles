#!/bin/bash

# Gnome keyring
gnome-keyring-daemon --start --components=pkcs11,secrets,ssh,gpg

# Swap Ctrl with Capslock
setxkbmap -option ctrl:swapcaps

# Start ibus
ibus