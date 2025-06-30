#!/usr/bin/env bash

set -euo pipefail

# ------------------------------------------------------------------------------
#   checks
# ------------------------------------------------------------------------------

if [[ "$(id -u)" -eq 0 ]]; then
  printf "\nThis script must not be executed with root privileges.\n\n"
  exit 1
fi

# ------------------------------------------------------------------------------
#   variables
# ------------------------------------------------------------------------------

pkgs=(
  "bottom"
  "chezmoi"
  "fastfetch"
  "firefox"
  "grim"
  "helix"
  "kitty"
  "rofi-wayland"
  "slurp"
  "uwsm"
  "waybar"
  "wl-clipboard"
  "xdg-desktop-portal-gtk"
  "xdg-user-dirs"
)

hyprland_pkgs=(
  "hyprland"
  "hyprpaper"
  "hyprpolkitagent"
  "xdg-desktop-portal-hyprland"
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

declare -A gsettings_values=(
  ["color-scheme"]="prefer-dark"
  ["cursor-theme"]="capitaine-cursors-light"
  ["cursor-size"]="24"
  ["font-name"]="Inter 12"
  ["icon-theme"]="Papirus-Dark"
  ["gtk-theme"]="Orchis-Dark-Compact"
)

github_username="CjayDoesCode"

# ------------------------------------------------------------------------------
#   user input
# ------------------------------------------------------------------------------

read -rp $'\n'"Install osu!(lazer)? [Y/n]: " install_osu
read -rp $'\n'"Keep chezmoi? [Y/n]: " keep_chezmoi
read -rp $'\n'"Reboot after installation? [Y/n]: " reboot

# ------------------------------------------------------------------------------
#   Installation
# ------------------------------------------------------------------------------

printf "\nInstalling packages...\n"
sudo pacman --sync --noconfirm --needed \
  "${pkgs[@]}" \
  "${hyprland_pkgs[@]}" \
  "${font_pkgs[@]}" \
  "${theme_pkgs[@]}"

printf "\nEnabling services...\n"
systemctl --user enable \
  hyprpaper.service \
  hyprpolkitagent.service \
  waybar.service \
  xdg-user-dirs-update.service

printf "\nConfiguring GTK...\n"
for key in "${!gsettings_values[@]}"; do
  gsettings set org.gnome.desktop.interface \
    "${key}" \
    "${gsettings_values["${key}"]}"
done

printf "\nInstalling dotfiles...\n"
chezmoi init --apply --force "${github_username}"

if [[ ! "${install_osu}" =~ ^[nN] ]]; then
  printf "\nInstalling osu!(lazer)...\n"
  mkdir --parents ~/Games/osu-lazer
  curl \
    --output ~/Games/osu-lazer/osu.AppImage \
    --location https://github.com/ppy/osu/releases/latest/download/osu.AppImage
else
  rm --force ~/.local/share/applications/osu-lazer.desktop
  rm --force ~/.local/share/icons/hicolor/24x24/osu-lazer-logo.png
  rmdir --ignore-fail-on-non-empty ~/.local/share/icons/hicolor/24x24
fi

if [[ "${keep_chezmoi}" =~ ^[nN]$ ]]; then
  printf "\nRemoving chezmoi...\n"
  chezmoi purge --force
  sudo pacman --remove --nosave --recursive --noconfirm chezmoi
fi

printf "\nInstallation completed.\n\n"
[[ ! "${reboot}" =~ ^[nN]$ ]] && reboot
