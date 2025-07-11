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

build_directory="$(mktemp -d)"

declare -A gsettings_values=(
  ["color-scheme"]="prefer-dark"
  ["cursor-theme"]="capitaine-cursors-light"
  ["cursor-size"]="24"
  ["font-name"]="Inter 12"
  ["icon-theme"]="Tela-circle-dark"
  ["gtk-theme"]="Orchis-Dark-Compact"
)

github_username="CjayDoesCode"

# ------------------------------------------------------------------------------
#   user input
# ------------------------------------------------------------------------------

printf "\n"
printf "Install osu!(lazer)? [Y/n]: " && read -r install_osu
printf "Keep chezmoi? [Y/n]: " && read -r keep_chezmoi
printf "Reboot after installation? [Y/n]: " && read -r reboot

# ------------------------------------------------------------------------------
#   Installation
# ------------------------------------------------------------------------------

printf "\nInstalling packages...\n"
sudo pacman -Syu --noconfirm --needed \
  "${base_packages[@]}" \
  "${hyprland_packages[@]}" \
  "${font_packages[@]}" \
  "${theme_packages[@]}"

if [[ ! "${install_osu}" =~ ^[nN]$ ]]; then
  for pkg in "${osu_packages[@]}"; do
    git clone "https://aur.archlinux.org/${pkg}.git" "${build_directory}/${pkg}"
    (
      cd "${build_directory}/${pkg}"
      makepkg --clean --force --install --rmdeps --syncdeps --noconfirm --needed
    )
  done
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
sudo systemctl enable greetd.service
systemctl --user enable \
  hypridle.service \
  hyprpaper.service \
  hyprpolkitagent.service \
  mako.service \
  waybar.service \
  xdg-user-dirs-update.service

printf "\nApplying dotfiles...\n"
chezmoi init --force "${github_username}"
if [[ "${install_osu}" =~ ^[nN]$ ]]; then
  chezmoi forget --force \
    "${HOME}/.local/share/applications" \
    "${HOME}/.local/share/icons"
fi
chezmoi apply --force

if [[ "${keep_chezmoi}" =~ ^[nN]$ ]]; then
  printf "\nRemoving chezmoi...\n"
  chezmoi purge --force
  sudo pacman -Rns --noconfirm chezmoi
fi

# ------------------------------------------------------------------------------
#   post-installation
# ------------------------------------------------------------------------------

printf "\nInstallation completed.\n\n"
[[ ! "${reboot}" =~ ^[nN]$ ]] && systemctl reboot
