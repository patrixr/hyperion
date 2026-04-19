#!/usr/bin/env nu

# Get the current user's shell
# Usage: get-user-shell.nu <username>

def main [username: string] {
  let shell_path = (grep $"^($username):" /etc/passwd | split column ":" | get column6 | first)
  let shell_name = ($shell_path | path basename)
  print $shell_name
}
