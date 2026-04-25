#!/usr/bin/env bash
# install.sh
# EndeavourOS Community Edition — Hyperion
# User-facing entry point. Downloads and runs the appropriate release.
#
# Usage:
#   # Install latest stable release
#   curl -sL https://raw.githubusercontent.com/patrixr/hyperion/main/install.sh | sudo bash
#
#   # Install a specific version
#   curl -sL https://raw.githubusercontent.com/patrixr/hyperion/main/install.sh | sudo bash -s -- --version v0.1.1

set -euo pipefail

VERSION=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --version)
      VERSION="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1"
      echo "Usage: install.sh [--version <tag>]"
      exit 1
      ;;
  esac
done

# Resolve download URL
if [[ -z "$VERSION" ]]; then
  echo ":: Installing latest stable Hyperion release..."
  URL="https://github.com/patrixr/hyperion/releases/latest/download/hyperion.sh"
else
  echo ":: Installing Hyperion $VERSION..."
  URL="https://github.com/patrixr/hyperion/releases/download/$VERSION/hyperion.sh"
fi

# Download and run
TEMP=$(mktemp)
trap "rm -f $TEMP" EXIT

echo ":: Downloading from $URL..."
curl -fsSL "$URL" -o "$TEMP"
chmod +x "$TEMP"
bash "$TEMP"
