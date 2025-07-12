#!/usr/bin/env bash

set -euo pipefail

# ------------------------------------------------------------------------------
#   checks
# ------------------------------------------------------------------------------

if ! grep --quiet "^ID=arch$" /etc/os-release; then
  printf "\nThis script only supports Arch Linux.\n\n" >&2
  exit 1
fi

if [[ "${EUID}" -eq 0 ]]; then
  printf "\nThis script must not be run as root.\n\n" >&2
  exit 1
fi

# ------------------------------------------------------------------------------
#   variables
# ------------------------------------------------------------------------------

base_packages=(
  "bottom"
  "chezmoi"
  "fastfetch"
  "firefox"
  "greetd"
  "greetd-tuigreet"
  "grim"
  "helix"
  "imagemagick"
  "kitty"
  "libnotify"
  "mako"
  "nm-connection-editor"
  "pavucontrol"
  "rofi-wayland"
  "slurp"
  "udiskie"
  "uwsm"
  "waybar"
  "wl-clipboard"
  "xdg-desktop-portal-gtk"
  "xdg-user-dirs"
)

hyprland_packages=(
  "hypridle"
  "hyprland"
  "hyprpaper"
  "hyprlock"
  "hyprpolkitagent"
  "xdg-desktop-portal-hyprland"
)

font_packages=(
  "inter-font"
  "noto-fonts"
  "noto-fonts-cjk"
  "noto-fonts-emoji"
  "noto-fonts-extra"
  "ttf-nerd-fonts-symbols"
  "ttf-nerd-fonts-symbols-mono"
  "ttf-sourcecodepro-nerd"
)

theme_packages=(
  "capitaine-cursors"
  "orchis-theme"
  "tela-circle-icon-theme-standard"
)

# order is important
osu_packages=(
  "osu-mime"      # depency of osu-handler and osu-lazer-bin
  "osu-handler"   # optional dependency of osu-mime
  "osu-lazer-bin" # depends on osu-mime
)

otd_package="opentabletdriver"
otd_service="opentabletdriver.service"

build_directory="$(mktemp --directory)"

declare -A gsettings_values=(
  ["color-scheme"]="prefer-dark"
  ["cursor-theme"]="capitaine-cursors-light"
  ["cursor-size"]="24"
  ["font-name"]="Inter 12"
  ["icon-theme"]="Tela-circle-dark"
  ["gtk-theme"]="Orchis-Dark-Compact"
)

greetd_service="greetd.service"
user_services=(
  "hypridle.service"
  "hyprpaper.service"
  "hyprpolkitagent.service"
  "mako.service"
  "waybar.service"
  "xdg-user-dirs-update.service"
)

github_username="CjayDoesCode"

# ------------------------------------------------------------------------------
#   functions
# ------------------------------------------------------------------------------

confirm() {
  local variable="$1"
  local prompt="$2"
  local input=""

  while true; do
    printf "%b [y/n]: " "${prompt}"
    read -r input
    case "${input,,}" in
    y | yes)
      declare -g "${variable}=true"
      break
      ;;
    n | no)
      declare -g "${variable}=false"
      break
      ;;
    *)
      printf "\nInvalid input. Try again.\n"
      ;;
    esac
  done
}

install_aur_package() {
  local package="$1"
  
  curl --output "${build_directory}/${package}.tar.gz" --location \
    "https://aur.archlinux.org/cgit/aur.git/snapshot/${package}.tar.gz"
  tar --extract --file "${build_directory}/${package}.tar.gz"
  
  pushd "${build_directory}/${package}"
  makepkg --clean --force --install --rmdeps --syncdeps --noconfirm --needed
  popd
}

# ------------------------------------------------------------------------------
#   cleanup
# ------------------------------------------------------------------------------

cleanup() {
  rm --force --recursive "${build_directory}"
}

trap cleanup EXIT

# ------------------------------------------------------------------------------
#   user input
# ------------------------------------------------------------------------------

install_osu=""
install_otd=""
keep_chezmoi=""

declare -A prompts=(
  ["install_osu"]="\nInstall osu!(lazer)?"
  ["install_otd"]="\nInstall OpenTabletDriver?"
  ["keep_chezmoi"]="\nKeep chezmoi (dotfile manager)?"
)

for variable in "${!prompts[@]}"; do
  confirm "${variable}" "${prompts[${variable}]}"
done

# ------------------------------------------------------------------------------
#   installation
# ------------------------------------------------------------------------------

printf "\nInstalling packages...\n"
sudo pacman -Syu --noconfirm --needed \
  "${base_packages[@]}" \
  "${hyprland_packages[@]}" \
  "${font_packages[@]}" \
  "${theme_packages[@]}"

if [[ "${install_osu}" == "true" || "${install_otd}" == "true" ]]; then
  if ! pacman -Qs "^base-devel$" >/dev/null; then
    pacman -S --noconfirm --needed base-devel
  fi

  printf "\nInstalling osu!(lazer)...\n"
  if [[ "${install_osu}" == "true" ]]; then
    for package in "${osu_packages[@]}"; do
      install_aur_package "${package}"
    done
  fi

  printf "\nInstalling OpenTabletDriver...\n"
  if [[ "${install_otd}" == "true" ]]; then
    install_aur_package "${otd_package}"
    user_services+=("${otd_service}")
  fi
fi

printf "\nConfiguring greetd...\n"
cat <<CONFIG | sudo tee /etc/greetd/config.toml >/dev/null
[terminal]
vt = 1

[default_session]
command = "tuigreet --cmd \\"sh -c 'exec -l \${SHELL}'\\""

[initial_session]
command = "sh -c 'exec -l \${SHELL}'"
user = "${USER}"
CONFIG

printf "\nConfiguring GTK...\n"
for key in "${!gsettings_values[@]}"; do
  gsettings set org.gnome.desktop.interface \
    "${key}" "${gsettings_values[${key}]}"
done

printf "\nEnabling services...\n"
sudo systemctl enable "${greetd_service}"
systemctl --user enable "${user_services[@]}"

printf "\nApplying dotfiles...\n"
chezmoi init --apply --force "${github_username}"

if [[ "${keep_chezmoi}" == "false" ]]; then
  printf "\nRemoving chezmoi...\n"
  chezmoi purge --force
  sudo pacman -Rns --noconfirm chezmoi
fi

printf "\nInstallation completed. Exiting...\n\n"
