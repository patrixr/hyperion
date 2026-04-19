use glue *

def conf-src [name: string] {
  $env.FILE_PWD | path join ("configs/" + $name)
}

def home-dir [] {
  let target_user = ($env | get --optional HYPERION_USER | default $env.USER)
  $"/home/($target_user)"
}

# Deploys a config folder to both the target user's ~/.config and /etc/skel/.config
def dotconf [name: string] {
  let folder = conf-src $name
  let destinations = [
    (home-dir | path join ".config")
    "/etc/skel/.config"
  ]
  for dest in $destinations {
    mkdir $dest
    cp -r $folder $dest
  }
  print $":: ✔️ .config/($name)"
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
  dotconf hyperion
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
  let sddm_config = "[General]\nInputMethod=qtvirtualkeyboard\nGreeterEnvironment=QML2_IMPORT_PATH=/usr/share/sddm/themes/hyperion/components/,QT_IM_MODULE=qtvirtualkeyboard\n\n[Theme]\nCurrent=hyperion\n"
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
}
