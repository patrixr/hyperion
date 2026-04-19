#!/usr/bin/env nu
# Helper script to change user shell with GUI password prompt
# Usage: change-shell.nu <shell> <username>

def main [shell_name: string, username: string] {
  let shell_path = $"/usr/bin/($shell_name)"
  
  # Validate shell exists
  if not ($shell_path | path exists) {
    run-external "zenity" "--error" $"--text=Shell '($shell_name)' not found at ($shell_path)" "--width=300"
    exit 1
  }
  
  # Prompt for password
  let password = (run-external "zenity" "--password" "--title=Authentication Required" "--text=Enter your password to change shell:" "--width=300" | complete)
  
  if $password.exit_code != 0 or ($password.stdout | str trim | is-empty) {
    exit 1
  }
  
  let pwd = ($password.stdout | str trim)
  
  # Change shell using sudo
  let result = (
    $pwd 
    | printf "%s\n" $in 
    | run-external "sudo" "-S" "usermod" "-s" $shell_path $username 
    | complete
  )
  
  if $result.exit_code == 0 {
    run-external "zenity" "--info" $"--text=Shell changed to ($shell_name) successfully!\n\nLog out and back in for changes to take effect." "--width=350" "--timeout=5"
    exit 0
  } else {
    let error_msg = ($result.stderr | lines | where {|line| not ($line | str contains "password for") and not ($line | str contains "[sudo]")} | first | default "Unknown error")
    run-external "zenity" "--error" $"--text=Failed to change shell.\n\n($error_msg)" "--width=350"
    exit 1
  }
}
