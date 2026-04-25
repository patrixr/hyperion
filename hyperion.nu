#!/usr/bin/env nu
# hyperion.nu
# EndeavourOS Community Edition — Hyperion
# Main entry point for Hyperion installation
#
# Usage:
#   nu hyperion.nu                    # Run as regular user, will request sudo
#   sudo nu hyperion.nu               # Run as root (auto-detects user)
#   nu hyperion.nu username           # Specify target user explicitly (ISO mode)
#   nu hyperion.nu --force            # Overwrite existing user dot configs (niri, ghostty, noctalia)

def main [username?: string, --force] {
  # Determine the target username
  let target_user = if ($username != null) {
    $username
  } else if ($env | get --optional HYPERION_USER) != null {
    $env.HYPERION_USER
  } else if ($env | get --optional SUDO_USER) != null {
    $env.SUDO_USER
  } else {
    $env.USER
  }

  print $":: Hyperion CE — install/update for user: ($target_user)"

  # Check if we're running as root
  let is_root = (id -u | into int) == 0

  # Determine script directory
  let script_dir = $env.FILE_PWD

  if $is_root {
    # Already root, run install directly
    print ":: Running as root"
    with-env { HYPERION_USER: $target_user, HYPERION_FORCE: ($force | into string) } {
      nu ($script_dir | path join "install.nu")
    }
  } else {
    # Not root, need to elevate
    print ":: Requesting sudo access..."
    sudo nu -c $"cd ($script_dir); HYPERION_USER=($target_user) HYPERION_FORCE=($force) nu install.nu"
  }

  print ":: Hyperion CE complete. Log out and back in for all changes to take effect."
}
