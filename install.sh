#!/usr/bin/env bash

# ------------------------------------------------------------------------------
#       constants
# ------------------------------------------------------------------------------

readonly BASE_PACKAGES=(
  'bottom'
  'chezmoi'
  'fastfetch'
  'firefox'
  'greetd'
  'greetd-tuigreet'
  'grim'
  'helix'
  'imagemagick'
  'kitty'
  'libnotify'
  'mako'
  'nm-connection-editor'
  'pavucontrol'
  'rofi-wayland'
  'slurp'
  'udiskie'
  'uwsm'
  'waybar'
  'wl-clipboard'
  'xdg-desktop-portal-gtk'
  'xdg-user-dirs'
)

readonly FONT_PACKAGES=(
  'inter-font'
  'noto-fonts'
  'noto-fonts-cjk'
  'noto-fonts-emoji'
  'noto-fonts-extra'
  'ttf-nerd-fonts-symbols'
  'ttf-nerd-fonts-symbols-mono'
  'ttf-sourcecodepro-nerd'
)

readonly HYPRLAND_PACKAGES=(
  'hypridle'
  'hyprland'
  'hyprlock'
  'hyprpaper'
  'hyprpolkitagent'
  'xdg-desktop-portal-hyprland'
)

readonly THEME_PACKAGES=(
  'capitaine-cursors'
  'orchis-theme'
  'tela-circle-icon-theme-standard'
)

readonly OSU_PACKAGES=('osu-mime' 'osu-handler' 'osu-lazer-bin')
readonly OTD_PACKAGE='opentabletdriver'
readonly OTD_SERVICE='opentabletdriver.service'

declare -Ar GSETTINGS_VALUES=(
  ['color-scheme']='prefer-dark'
  ['cursor-theme']='capitaine-cursors-light'
  ['cursor-size']=24
  ['font-name']='Inter 12'
  ['icon-theme']='Tela-circle-dark'
  ['gtk-theme']='Orchis-Dark-Compact'
)

readonly DOTFILES_REPOSITORY='https://github.com/CjayDoesCode/dotfiles.git'

# ------------------------------------------------------------------------------
#       main function
# ------------------------------------------------------------------------------

main() {
  print '\n'

  # ----  variables  -----------------------------------------------------------

  local packages=(
    "${BASE_PACKAGES[@]}"
    "${FONT_PACKAGES[@]}"
    "${HYPRLAND_PACKAGES[@]}"
    "${THEME_PACKAGES[@]}"
  )

  local install_osu=''
  local install_otd=''
  local keep_chezmoi=''

  local services=(
    'hypridle.service'
    'hyprpaper.service'
    'hyprpolkitagent.service'
    'mako.service'
    'waybar.service'
    'xdg-user-dirs-update.service'
  )

  # ----  checks  --------------------------------------------------------------

  if ! is_arch_linux; then
    print_error 'this script only supports Arch Linux.\n\n'
    exit 1
  fi

  if ! is_root; then
    print_error 'this script must not be run as root.\n\n'
    exit 1
  fi

  # ----  input  ---------------------------------------------------------------

  install_osu="$(confirm 'install osu!(lazer)?')"
  install_otd="$(confirm 'install OpenTabletDriver?')"
  keep_chezmoi="$(confirm 'install chezmoi (dotfile manager)?')"

  if [[ "${install_osu}" == 'true' || "${install_otd}" == 'true' ]]; then
    packages+=("base-devel")
  fi

  [[ ${install_otd} == 'true' ]] && services+=("${OTD_SERVICE}")

  # ----  installation  --------------------------------------------------------

  print_info 'installing packages...\n\n'
  if ! install_packages "${packages[@]}"; then
    print_error 'failed to install packages.\n\n'
    return 1
  fi

  if [[ "${install_osu}" == 'true' ]]; then
    print_info 'installing osu!(lazer)...\n\n'
    if ! install_osu; then
      print_error 'failed to install osu!(lazer).\n\n'
      return 1
    fi
  fi

  if [[ "${install_otd}" == 'true' ]]; then
    print_info 'installing OpenTabletDriver...\n\n'
    if ! install_otd; then
      print_error 'failed to install OpenTabletDriver.\n\n'
      return 1
    fi
  fi

  print_info 'configuring greetd...\n\n'
  if ! configure_greetd; then
    print_error 'failed to configure greetd.\n\n'
    return 1
  fi

  print_info 'configuring gtk...\n\n'
  if ! configure_gtk; then
    print_error 'failed to configure gtk.\n\n'
    return 1
  fi

  print_info 'enable services...\n\n'
  if ! enable_services "${services}"; then
    print_error 'failed to enable services\n\n'
    return 1
  fi

  print_info 'applying dotfiles...\n\n'
  if ! apply_dotfiles; then
    print_error 'failed to apply dotfiles\n\n'
    return 1
  fi

  if [[ "${keep_chezmoi}" == 'false' ]]; then
    print_info 'removing chezmoi...\n\n'
    if ! remove_chezmoi; then
      print_error 'failed to remove chezmoi.\n\n'
      return 1
    fi
  fi

  print_info 'installation completed.\n\n'
}

# ------------------------------------------------------------------------------
#       input functions
# ------------------------------------------------------------------------------

# usage: scan [--password] prompt
scan() {
  local prompt=''
  local input=''

  local password='false'

  while [[ "$#" -gt 0 ]]; do
    case "$1" in
    --password)
      password='true'
      shift
      ;;
    *)
      prompt="$1"
      shift
      ;;
    esac
  done

  print --color blue "${prompt}" >&2

  if [[ "${password}" == 'true' ]]; then
    read -rs input
    print '\n\n' >&2
  else
    read -r input
    print '\n' >&2
  fi

  printf '%s' "${input}"
}

confirm() {
  local prompt="$1"
  local input=''

  while true; do
    input="$(scan "${prompt} [y/n]: ")"

    case "${input,,}" in
    y | yes)
      return 0
      ;;
    n | no)
      return 1
      ;;
    *)
      print_error 'invalid input. try again.\n\n'
      ;;
    esac
  done
}

# ------------------------------------------------------------------------------
#       install functions
# ------------------------------------------------------------------------------

install_packages() {
  local packages=("$@")
  print_info 'installing packages...'
  sudo pacman -Syu --noconfirm --needed "${packages[@]}" || return 1
}

install_aur_package() {
  local package="$1"

  local build_directory=''
  local previous_directory="${PWD}"

  local url="https://aur.archlinux.org/cgit/aur.git/snapshot/${package}.tar.gz"

  local makepkg_options=(
    '--clean' '--force' '--install' '--rmdeps'
    '--syncdeps' '--noconfirm' '--needed'
  )

  build_directory="$(mktemp --directory)" || return 1
  cd "${build_directory}" || return 1

  local retries=0
  local max_retries=3
  local interval=5

  until curl --location --output "${package}.tar.gz" "${url}" 2>/dev/null; do
    ((++retries > max_retries)) && return 1
    print_error 'failed to download file. retrying...\n\n'
    sleep "${interval}"
  done

  tar --extract --gzip --file "${package}.tar.gz" || return 1
  cd "${package}" || return 1

  makepkg "${makepkg_options[@]}" || return 1
  cd "${previous_directory}" || return 1

  rm --force "${build_directory}" || return 1
}

install_osu() {
  install_aur_package("${OSU_PACKAGES[@]}") || return 1
}

install_otd() {
  install_aur_package("${OTD_PACKAGE}") || return 1
}

configure_greetd() {
  cat <<-CONFIG | sudo tee /etc/greetd/config.toml >/dev/null || return 1
		[terminal]
		vt = 1

		[default_session]
		command = "tuigreet --cmd \\"sh -c 'exec -l \${SHELL}'\\""

		[initial_session]
		command = "sh -c 'exec -l \${SHELL}'"
		user = "${USER}"
	CONFIG

	sudo systemctl enable greetd.service || return 1
}

configure_gtk() {
  local schema='org.gnome.desktop.interface'
  local key=''

  for key in "${!GSETTINGS_VALUES[@]}"; do
    gsettings set "${schema}" "${key}" "${GSETTINGS_VALUES[${key}]}" || return 1
  done
}

enable_services() {
  local services=("$@")
  systemctl --user enable "${services[@]}" || return 1
}

apply_dotfiles() {
  chezmoi init --apply --force "${DOTFILES_REPOSITORY}" || return 1
}

remove_chezmoi() {
  chezmoi purge --force || return 1
  sudo pacman -Rns --noconfirm chezmoi || return 1
}

# ------------------------------------------------------------------------------
#       check functions
# ------------------------------------------------------------------------------

is_arch_linux() {
  grep --quiet '^ID=arch$' /etc/os-release || return 1
}

is_root() {
  [[ "${EUID}" -eq 0 ]] || return 1
}

# ------------------------------------------------------------------------------
#       output functions
# ------------------------------------------------------------------------------

# usage: print [--color color] message
print() {
  local message=''
  local color=''

  while [[ "$#" -gt 0 ]]; do
    case "$1" in
    --color)
      color="$2"
      shift 2
      ;;
    *)
      message="$1"
      shift
      ;;
    esac
  done

  if [[ -n "${color}" ]]; then
    local color_sequence="\\033[1;${COLOR_CODES[${color}]}m"
    local reset_sequence='\033[0m'
    printf '%b' "${color_sequence}${message}${reset_sequence}"
  else
    printf '%b' "${message}"
  fi
}

print_info() {
  local message="$1"
  print --color green "info: ${message}"
}

print_error() {
  local message="$1"
  print --color red "error: ${message}" >&2
}
