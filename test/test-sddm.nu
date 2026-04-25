#!/usr/bin/env nu
# test-sddm.nu
# Launches the SDDM greeter in test mode for visual theme development.
#
# Usage:
#   nu test/test-sddm.nu           # Test the installed theme
#   nu test/test-sddm.nu --local   # Test directly from the repo (no background images)

def main [--local] {
  let theme = if $local {
    $env.FILE_PWD | path join "../configs/sddm"
  } else {
    "/usr/share/sddm/themes/hyperion"
  }

  print $":: Testing SDDM theme at: ($theme)"

  with-env { QML_XHR_ALLOW_FILE_READ: "1" } {
    run-external "sddm-greeter-qt6" "--test-mode" "--theme" $theme
  }
}
