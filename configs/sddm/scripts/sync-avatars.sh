#!/bin/bash
# SDDM pre-greeter script to sync noctalia avatars to ~/.face
# Runs as root before login screen appears

# Sync avatars for all users with noctalia settings
for user_home in /home/*; do
    username=$(basename "$user_home")
    noctalia_settings="$user_home/.config/noctalia/settings.json"
    
    # Skip if noctalia settings don't exist
    [ -f "$noctalia_settings" ] || continue
    
    # Extract avatar path from noctalia settings
    avatar_path=$(grep -o '"avatarImage"[[:space:]]*:[[:space:]]*"[^"]*"' "$noctalia_settings" | sed 's/.*"\([^"]*\)"/\1/')
    
    # Skip if no avatar path or file doesn't exist
    [ -n "$avatar_path" ] || continue
    [ -f "$avatar_path" ] || continue
    
    # Create or update ~/.face symlink
    face_link="$user_home/.face"
    if [ -L "$face_link" ] || [ -f "$face_link" ]; then
        rm -f "$face_link"
    fi
    
    ln -s "$avatar_path" "$face_link"
    chown -h "$username:$username" "$face_link"
done
