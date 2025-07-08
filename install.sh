#!/usr/bin/env bash

set -euo pipefail

if [[ "${EUID}" -eq 0 ]]; then
  printf "\nThis script must not be run as root.\n\n" >&2
  exit 1
fi

# ------------------------------------------------------------------------------
#   variables
# ------------------------------------------------------------------------------

packages=(
  "bottom"
  "chezmoi"
  "fastfetch"
  "firefox"
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

# hyprland packages
packages+=(
  "hypridle"
  "hyprland"
  "hyprpaper"
  "hyprlock"
  "hyprpolkitagent"
  "xdg-desktop-portal-hyprland"
)

# font packages
packages+=(
  "inter-font"
  "noto-fonts"
  "noto-fonts-cjk"
  "noto-fonts-emoji"
  "noto-fonts-extra"
  "ttf-nerd-fonts-symbols"
  "ttf-nerd-fonts-symbols-mono"
  "ttf-sourcecodepro-nerd"
)

# theme packages
packages+=(
  "capitaine-cursors"
  "orchis-theme"
  "tela-circle-icon-theme-standard"
)

github_username="CjayDoesCode"

declare -A gsettings_values=(
  ["color-scheme"]="prefer-dark"
  ["cursor-theme"]="capitaine-cursors-light"
  ["cursor-size"]="24"
  ["font-name"]="Inter 12"
  ["icon-theme"]="Tela-circle-dark"
  ["gtk-theme"]="Orchis-Dark-Compact"
)

services=(
  "hypridle"
  "hyprpaper"
  "hyprpolkitagent"
  "mako"
  "waybar"
  "xdg-user-dirs-update"
)

# ------------------------------------------------------------------------------
#   user input
# ------------------------------------------------------------------------------

printf "\nInstall osu!(lazer)? [Y/n]: " && read -r install_osu
printf "\nKeep chezmoi? [Y/n]: " && read -r keep_chezmoi
printf "\nReboot after installation? [Y/n]: " && read -r reboot

# ------------------------------------------------------------------------------
#   Installation
# ------------------------------------------------------------------------------

printf "\nInstalling packages...\n"
sudo pacman -Syu --noconfirm --needed "${packages[@]}"

printf "\nInstalling dotfiles...\n"
chezmoi init --apply --force "${github_username}"

if [[ ! "${install_osu}" =~ ^[nN] ]]; then
  printf "\nInstalling osu!(lazer)...\n"
  target_directory="${HOME}/.local/bin"
  url="https://github.com/ppy/osu/releases/latest/download/osu.AppImage"
  mkdir --parents "${target_directory}"
  curl --output "${target_directory}/osu" --location "${url}"
  chmod +x "${target_directory}/osu"
else
  target_directory="${HOME}/.local/share"
  rm --force "${target_directory}/applications/osu.desktop"
  rm --force "${target_directory}/icons/hicolor/128x128/apps/osu-logo.png"
  chezmoi forget --force "${target_directory}/applications"
  chezmoi forget --force "${target_directory}/icons"
fi

printf "\nConfiguring GTK...\n"
for key in "${!gsettings_values[@]}"; do
  gsettings set org.gnome.desktop.interface \
    "${key}" "${gsettings_values[${key}]}"
done

printf "\nEnabling services...\n"
systemctl --user enable "${services[@]}"

if [[ "${keep_chezmoi}" =~ ^[nN]$ ]]; then
  printf "\nRemoving chezmoi...\n"
  chezmoi purge --force
  sudo pacman -Rns --noconfirm chezmoi
fi

# ==============================================================================
#   post-installation
# ==============================================================================

printf "\nInstallation completed.\n\n"
[[ ! "${reboot}" =~ ^[nN]$ ]] && systemctl reboot
