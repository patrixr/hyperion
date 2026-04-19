#!/usr/bin/env bash
# hyperion.sh
# EndeavourOS Community Edition — Hyperion
# Manual install/update script for post-installation use
#
# Usage:
#   curl -sL https://raw.githubusercontent.com/patrixr/hyperion/main/hyperion.sh | bash
#   OR
#   git clone https://github.com/patrixr/hyperion.git && cd hyperion && ./hyperion.sh
#
# Can be run as regular user or with sudo.

set -euo pipefail

# Always clone from GitHub when piped, or check local when run from file
if [ -f "hyperion.nu" ]; then
    # Running from inside the hyperion directory
    echo ":: Using local Hyperion repo..."
    HYPERION_DIR="$(pwd)"
else
    # Need to clone the repo
    echo ":: Fetching latest Hyperion from GitHub..."
    TEMP_DIR=$(mktemp -d)
    trap "rm -rf $TEMP_DIR" EXIT
    git clone --depth=1 https://github.com/patrixr/hyperion.git "$TEMP_DIR/hyperion"
    HYPERION_DIR="$TEMP_DIR/hyperion"
fi

# Install nushell if needed
echo ":: Bootstrapping nushell..."
if [ "$EUID" -eq 0 ]; then
    pacman -S --needed --noconfirm nushell
else
    sudo pacman -S --needed --noconfirm nushell
fi

# Run the main nushell entry point
echo ":: Running Hyperion installer..."
nu "$HYPERION_DIR/hyperion.nu"
