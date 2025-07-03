#!/usr/bin/env bash

set -euo pipefail

# ------------------------------------------------------------------------------
#   checks
# ------------------------------------------------------------------------------

if [[ "$EUID" -eq 0 ]]; then
  printf "\nThis script must not be run as root.\n\n"
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
  "hyprland"
  "hyprpaper"
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

printf "\n Install osu!(lazer)? [Y/n]: " && read -r install_osu
printf "\n Keep chezmoi? [Y/n]: " && read -r keep_chezmoi
printf "\n Reboot after installation? [Y/n]: " && read -r reboot

# ------------------------------------------------------------------------------
#   Installation
# ------------------------------------------------------------------------------

printf "\nInstalling packages...\n"
sudo pacman -Syu --noconfirm --needed "${packages[@]}"

printf "\nEnabling services...\n"
systemctl --user enable \
  hyprpaper.service \
  hyprpolkitagent.service \
  waybar.service \
  xdg-user-dirs-update.service

printf "\nConfiguring GTK...\n"
for key in "${!gsettings_values[@]}"; do
  gsettings set org.gnome.desktop.interface "$key" "${gsettings_values["$key"]}"
done

printf "\nInstalling dotfiles...\n"
chezmoi init --apply --force "$github_username"

if [[ ! "$install_osu" =~ ^[nN] ]]; then
  printf "\nInstalling osu!(lazer)...\n"
  mkdir --parents "$HOME/.local/bin"
  curl \
    --output "$HOME/.local/bin/osu" \
    --location https://github.com/ppy/osu/releases/latest/download/osu.AppImage
  chmod +x "$HOME/.local/bin/osu"
else
  rm --force "$HOME/.local/share/applications/osu.desktop"
  rm --force "$HOME/.local/share/icons/hicolor/128x128/apps/osu-logo.png"
  chezmoi forget --force "$HOME/.local"
fi

if [[ "${keep_chezmoi}" =~ ^[nN]$ ]]; then
  printf "\nRemoving chezmoi...\n"
  chezmoi purge --force
  sudo pacman -Rns --noconfirm chezmoi
fi

printf "\nInstallation completed.\n\n"
[[ ! "${reboot}" =~ ^[nN]$ ]] && shutdown -r now
