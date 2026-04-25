use glue *

def conf-src [name: string] {
  $env.FILE_PWD | path join ("configs/" + $name)
}

def home-dir [] {
  let target_user = ($env | get --optional HYPERION_USER | default $env.USER)
  $"/home/($target_user)"
}

# Deploys a config folder to both the target user's ~/.config and /etc/skel/.config.
# Skel is always overwritten. The user's ~/.config is only written on first install
# unless HYPERION_FORCE=true is set, or --always-update is passed.
def dotconf [name: string, --always-update] {
  let folder = conf-src $name
  let force = (($env | get --optional HYPERION_FORCE | default "false") in ["true", true])

  # Always update skel
  let skel_dest = "/etc/skel/.config"
  mkdir $skel_dest
  cp -r $folder $skel_dest

  # Conditionally update user config
  let user_dest = (home-dir | path join ".config")
  let config_target = ($user_dest | path join $name)

  if (not $always_update) and ($config_target | path exists) and (not $force) {
    print $":: ⏭️  .config/($name) already exists — skipping \(use --force to override\)"
  } else {
    mkdir $user_dest
    cp -r $folder $user_dest
    print $":: ✔️ .config/($name)"
  }
}

group "📦 System Packages" {

  install nushell {
    let nu_path = (which nu | first | get path)
    let shells = (open /etc/shells)
    if not ($shells | str contains $nu_path) {
      run-external "tee" "-a" "/etc/shells" | $nu_path
    }
    let target_user = ($env | get --optional HYPERION_USER | default $env.USER)
    run-external "chsh" "-s" $nu_path $target_user
    print $":: ✔️ Default shell set to ($nu_path)"
  }

  install sddm {
    run-external "systemctl" "enable" "sddm"
    print ":: ✔️ SDDM enabled"
  }

  # For SDDM theme
  install qt6-svg
  install qt6-virtualkeyboard
  install qt6-multimedia-ffmpeg

  install niri
  install ghostty
  install nautilus
  install zsh
  install zenity

  add-chaotic-aur
  install noctalia-shell
}

group "📁 Configs" {
  dotconf niri
  dotconf noctalia
  dotconf ghostty
  dotconf hyperion --always-update
}

group "🎨 SDDM Theme" {
  # Deploy SDDM theme
  let theme_src = $env.FILE_PWD | path join "configs/sddm"
  let theme_dest = "/usr/share/sddm/themes/hyperion"

  mkdir $theme_dest

  for item in (ls $theme_src) {
      cp -r $item.name $theme_dest
  }
  print ":: ✔️ SDDM theme deployed to /usr/share/sddm/themes/hyperion"
  
  # Copy background images from images/ to theme backgrounds/
  let images_src = $env.FILE_PWD | path join "images"
  let backgrounds_dest = $theme_dest | path join "backgrounds"
  for file in (ls $images_src | where type == file and name =~ 'bg-.*\.(jpg|png)') {
    cp $file.name $backgrounds_dest
  }
  print ":: ✔️ Background images copied to SDDM theme"

  # Install fonts
  let fonts_src = $theme_dest | path join "fonts"
  for item in (ls $fonts_src) {
      cp -r $item.name "/usr/share/fonts/"
  }
  print ":: ✔️ SDDM theme fonts installed"

  # Configure SDDM to use the theme with environment variables
  let sddm_conf_dir = "/etc/sddm.conf.d"
  mkdir $sddm_conf_dir
  let sddm_config = "[General]\nInputMethod=qtvirtualkeyboard\nGreeterEnvironment=QML2_IMPORT_PATH=/usr/share/sddm/themes/hyperion/components/,QT_IM_MODULE=qtvirtualkeyboard,QML_XHR_ALLOW_FILE_READ=1\n\n[Theme]\nCurrent=hyperion\n"
  $sddm_config | save -f ($sddm_conf_dir | path join "hyperion.conf")
  print ":: ✔️ SDDM configured to use hyperion theme"
}

group "🖼️ Wallpapers" {
  let images_folder = $env.FILE_PWD | path join "images"
  let destinations = [
    (home-dir | path join "Pictures/Wallpapers")
    "/etc/skel/Pictures/Wallpapers"
  ]
  for dest in $destinations {
    mkdir $dest
    for file in (ls $images_folder | where type == file) {
      cp $file.name $dest
    }
  }
  print ":: ✔️ Wallpapers copied to user home and /etc/skel"

  # Create Noctalia wallpaper configuration for current user
  let cache_dir = (home-dir | path join ".cache/noctalia")
  mkdir $cache_dir

  let wallpaper_config = {
    defaultWallpaper: (home-dir | path join "Pictures/Wallpapers/bg-1.png"),
    usedRandomWallpapers: {},
    wallpapers: {}
  }

  $wallpaper_config | to json | save -f ($cache_dir | path join "wallpapers.json")
  print ":: ✔️ Noctalia wallpaper configuration created"

  # Create default user avatar
  let default_avatar = $images_folder | path join "default-avatar.png"
  let avatar_destinations = [
    (home-dir | path join ".face")
    "/etc/skel/.face"
  ]
  for dest in $avatar_destinations {
    cp $default_avatar $dest
  }
  print ":: ✔️ Default user avatar created"
}

group "🚀 Hyperion Welcome" {
  # Deploy desktop file
  let desktop_src = $env.FILE_PWD | path join "configs/hyperion/hyperion-welcome/io.tronica.hyperion-welcome.desktop"
  let destinations = [
    (home-dir | path join ".local/share/applications")
    "/etc/skel/.local/share/applications"
  ]
  for dest in $destinations {
    mkdir $dest
    cp $desktop_src $dest
  }
  print ":: ✔️ Hyperion Welcome desktop file installed"
}

group "🔑 Permissions" {
  let target_user = ($env | get --optional HYPERION_USER | default $env.USER)
  run-external "chown" "-R" $"($target_user):($target_user)" (home-dir)
  print $":: ✔️ Ownership of (home-dir) restored to ($target_user)"

  # Grant the sddm user just enough access to traverse the home directory
  # so it can read ~/.config/noctalia/settings.json and the avatar image.
  # We use a targeted ACL rather than chmod 711 to avoid opening traversal
  # to all other users on the system.
  run-external "setfacl" "-m" "u:sddm:x" (home-dir)
  print $":: ✔️ sddm granted home directory traversal via ACL"
}
