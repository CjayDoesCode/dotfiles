#!/usr/bin/env bash

set -euo pipefail

# ------------------------------------------------------------------------------
#   variables
# ------------------------------------------------------------------------------

github_username="CjayDoesCode"

pkgs=(
  "bottom"
  "chezmoi"
  "fastfetch"
  "firefox"
  "grim"
  "helix"
  "hyprland"
  "hyprpaper"
  "hyprpolkitagent"
  "imagemagick"
  "kitty"
  "rofi-wayland"
  "slurp"
  "uwsm"
  "waybar"
  "wl-clipboard"
  "xdg-desktop-portal-gtk"
  "xdg-desktop-portal-hyprland"
  "xdg-user-dirs"
)

font_pkgs=(
  "adobe-source-code-pro-fonts"
  "inter-font"
  "noto-fonts"
  "noto-fonts-cjk"
  "noto-fonts-emoji"
  "noto-fonts-extra"
  "ttf-nerd-fonts-symbols"
  "ttf-nerd-fonts-symbols-mono"
  "ttf-sourcecodepro-nerd"
)

theme_pkgs=(
  "capitaine-cursors"
  "orchis-theme"
  "papirus-icon-theme"
)

pkgs+=("${font_pkgs[@]}" "${theme_pkgs[@]}")

# ------------------------------------------------------------------------------
#   checks
# ------------------------------------------------------------------------------

if [[ "$(id -u)" -eq 0 ]]; then
  echo "This script must not be executed with root privileges."
  exit 1
fi

# ------------------------------------------------------------------------------
#   Installation
# ------------------------------------------------------------------------------

sudo pacman -S --noconfirm --needed "${pkgs[@]}"

systemctl --user enable \
  hyprpaper.service \
  hyprpolkitagent.service \
  waybar.service \
  xdg-user-dirs-update.service

chezmoi init --apply "${github_username}"

read -rp $'\n'"Keep chezmoi? [Y/n]: " input
if [[ "${input}" =~ ^[nN]$ ]]; then
  chezmoi purge
  sudo pacman -Rns --noconfirm chezmoi
fi

read -rp $'\n'"Installation completed. Reboot now? [Y/n]: " input
[[ ! "${input}" =~ ^[nN]$ ]] && reboot
