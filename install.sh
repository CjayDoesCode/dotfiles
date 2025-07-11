#!/usr/bin/env bash

set -euo pipefail

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

build_directory="$(mktemp --directory)"
cleanup() {
  rm --force --recursive "${build_directory}"
}
trap cleanup EXIT

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
#   user input
# ------------------------------------------------------------------------------

printf "\nInstall osu!(lazer)? [Y/n]: " && read -r install_osu
if [[ "${install_osu}" =~ ^[nN]$ ]]; then
  printf "Install OpenTabletDriver? [Y/n]" && read -r install_otd
fi

printf "Keep chezmoi? [Y/n]: " && read -r keep_chezmoi

# ------------------------------------------------------------------------------
#   functions
# ------------------------------------------------------------------------------

install_aur_package() {
  local package="$1"
  (
    cd "${build_directory}"
    git clone "https://aur.archlinux.org/${package}.git"
    cd "${package}"
    makepkg --clean --force --install --rmdeps --syncdeps --noconfirm --needed
  )
}

# ------------------------------------------------------------------------------
#   installation
# ------------------------------------------------------------------------------

printf "\nInstalling packages...\n"
sudo pacman -Syu --noconfirm --needed \
  "${base_packages[@]}" \
  "${hyprland_packages[@]}" \
  "${font_packages[@]}" \
  "${theme_packages[@]}"

printf "\nInstalling osu!(lazer)...\n"
if [[ ! "${install_osu}" =~ ^[nN]$ ]]; then
  for package in "${osu_packages[@]}"; do
    install_aur_package "${package}"
  done
fi

printf "\nInstalling OpenTabletDriver...\n"
if [[ ! "${install_otd}" ]]; then
  install_aur_package "${otd_package}"
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

if [[ "${keep_chezmoi}" =~ ^[nN]$ ]]; then
  printf "\nRemoving chezmoi...\n"
  chezmoi purge --force
  sudo pacman -Rns --noconfirm chezmoi
fi

# ------------------------------------------------------------------------------
#   post-installation
# ------------------------------------------------------------------------------

printf "\nInstallation completed.\n\n"
