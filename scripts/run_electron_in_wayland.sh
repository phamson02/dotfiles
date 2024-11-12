#!/bin/bash

# Define the ozone flags to append
OZONE_FLAGS="--enable-features=UseOzonePlatform --enable-wayland-ime --ozone-platform=wayland --gtk-version=4"

# Define the list of applications
APPLICATIONS=(
  brave-browser
  microsoft-edge-dev
  code
  discord
  postman
)

# Ensure the local applications directory exists
mkdir -p ~/.local/share/applications

# Loop over each application in the list
for app in "${APPLICATIONS[@]}"; do
  # Construct the source and destination paths
  SRC_DESKTOP_FILE="/usr/share/applications/${app}.desktop"
  DEST_DESKTOP_FILE="$HOME/.local/share/applications/${app}.desktop"

  # Check if the source .desktop file exists
  if [ ! -f "$SRC_DESKTOP_FILE" ]; then
    echo "Error: ${SRC_DESKTOP_FILE} does not exist."
    exit 1  # Stop execution if the file is not found
  fi

  # Copy the .desktop file to the local directory
  cp "$SRC_DESKTOP_FILE" "$DEST_DESKTOP_FILE"

  # Append the ozone flags to the Exec line(s)
  sed -i "/^Exec=/ s/$/ $OZONE_FLAGS/" "$DEST_DESKTOP_FILE"

  echo "Updated ${DEST_DESKTOP_FILE}"
done

# Define the path to your .bashrc (symlink)
BASHRC="$HOME/.bashrc"

# Define the actual file that .bashrc points to
BASHRC_REAL="$(readlink -f "$BASHRC")"

# Define markers for the start and end of the functions block
START_MARKER="# Functions for running Electron apps with Ozone flags - START"
END_MARKER="# Functions for running Electron apps with Ozone flags - END"

# Function to append new functions
append_functions() {
  {
    echo ""
    echo "$START_MARKER"
    for app in "${APPLICATIONS[@]}"; do
      echo "${app}() {"
      echo "  command ${app} ${OZONE_FLAGS} \"\$@\""
      echo "}"
      echo ""
    done
    echo "$END_MARKER"
  } >> "$BASHRC_REAL"
}

# Function to add new functions without overwriting existing ones
add_new_functions() {
  local new_functions=""
  for app in "${APPLICATIONS[@]}"; do
    if ! echo "$existing_functions" | grep -q "^${app}$"; then
      echo "Adding function for ${app} to .bashrc"
      # Append the new function to new_functions with proper formatting
      new_functions+="${app}() {\n  command ${app} ${OZONE_FLAGS} \"\$@\"\n}\n\n"
    else
      echo "Function for ${app} already exists in .bashrc, skipping..."
    fi
  done

  if [ -n "$new_functions" ]; then
    # Use awk to handle multi-line insertion
    awk -v start="$START_MARKER" -v end="$END_MARKER" -v new_funcs="$new_functions" '
      $0 == start { print; printf("%s", new_funcs); next }
      { print }
    ' "$BASHRC_REAL" > "${BASHRC_REAL}.tmp" && mv "${BASHRC_REAL}.tmp" "$BASHRC_REAL"
    echo "New functions added successfully."
  else
    echo "No new functions to add."
  fi
}

# Main logic
if ! grep -qF "$START_MARKER" "$BASHRC_REAL"; then
  echo "Markers not found. Appending new functions block."
  append_functions
else
  echo "Markers found. Checking for existing functions."
  # Extract existing function names between markers
  existing_functions=$(sed -n "/$START_MARKER/,/$END_MARKER/{
    /^$START_MARKER$/d
    /^$END_MARKER$/d
    s/^\(.*\)() {$/\1/p
  }" "$BASHRC_REAL")

  add_new_functions
fi