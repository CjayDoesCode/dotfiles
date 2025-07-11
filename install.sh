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

declare -ar BASE_PACKAGES=(
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

declare -ar HYPRLAND_PACKAGES=(
  "hypridle"
  "hyprland"
  "hyprpaper"
  "hyprlock"
  "hyprpolkitagent"
  "xdg-desktop-portal-hyprland"
)

declare -ar FONT_PACKAGES=(
  "inter-font"
  "noto-fonts"
  "noto-fonts-cjk"
  "noto-fonts-emoji"
  "noto-fonts-extra"
  "ttf-nerd-fonts-symbols"
  "ttf-nerd-fonts-symbols-mono"
  "ttf-sourcecodepro-nerd"
)

declare -ar THEME_PACKAGES=(
  "capitaine-cursors"
  "orchis-theme"
  "tela-circle-icon-theme-standard"
)

# order is important
declare -ar OSU_PACKAGES=(
  "osu-mime"      # depency of osu-handler and osu-lazer-bin
  "osu-handler"   # optional dependency of osu-mime
  "osu-lazer-bin" # depends on osu-mime
)

readonly OTD_PACKAGE="opentabletdriver"

BUILD_DIRECTORY="$(mktemp --directory)"
readonly BUILD_DIRECTORY
cleanup() {
  rm --force --recursive "${BUILD_DIRECTORY}"
}
trap cleanup EXIT

declare -Ar GSETTINGS_VALUES=(
  ["color-scheme"]="prefer-dark"
  ["cursor-theme"]="capitaine-cursors-light"
  ["cursor-size"]="24"
  ["font-name"]="Inter 12"
  ["icon-theme"]="Tela-circle-dark"
  ["gtk-theme"]="Orchis-Dark-Compact"
)

readonly GREETD_SERVICE="greetd.service"
declare -ar USER_SERVICES=(
  "hypridle.service"
  "hyprpaper.service"
  "hyprpolkitagent.service"
  "mako.service"
  "waybar.service"
  "xdg-user-dirs-update.service"
)

readonly GITHUB_USERNAME="CjayDoesCode"

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
    cd "${BUILD_DIRECTORY}"
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
  "${BASE_PACKAGES[@]}" \
  "${HYPRLAND_PACKAGES[@]}" \
  "${FONT_PACKAGES[@]}" \
  "${THEME_PACKAGES[@]}"

printf "\nInstalling osu!(lazer)...\n"
if [[ ! "${install_osu}" =~ ^[nN]$ ]]; then
  for package in "${OSU_PACKAGES[@]}"; do
    install_aur_package "${package}"
  done
fi

printf "\nInstalling OpenTabletDriver...\n"
if [[ ! "${install_otd}" ]]; then
  install_aur_package "${OTD_PACKAGE}"
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
for key in "${!GSETTINGS_VALUES[@]}"; do
  gsettings set org.gnome.desktop.interface \
    "${key}" "${GSETTINGS_VALUES[${key}]}"
done

printf "\nEnabling services...\n"
sudo systemctl enable "${GREETD_SERVICE}"
systemctl --user enable "${USER_SERVICES[@]}"

printf "\nApplying dotfiles...\n"
chezmoi init --apply --force "${GITHUB_USERNAME}"

if [[ "${keep_chezmoi}" =~ ^[nN]$ ]]; then
  printf "\nRemoving chezmoi...\n"
  chezmoi purge --force
  sudo pacman -Rns --noconfirm chezmoi
fi

# ------------------------------------------------------------------------------
#   post-installation
# ------------------------------------------------------------------------------

printf "\nInstallation completed. Exiting...\n\n"
