#!/usr/bin/env bash

# ------------------------------------------------------------------------------
#       constants
# ------------------------------------------------------------------------------

readonly BASE_PACKAGES=(
  'bottom'
  'chezmoi'
  'fastfetch'
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
  'rofi'
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

readonly AUR_PREREQUISITE='base-devel'

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

declare -Ar COLOR_CODES=(
  ['black']=30 ['red']=31 ['green']=32 ['yellow']=33
  ['blue']=34 ['magenta']=35 ['cyan']=36 ['white']=37
)

# ------------------------------------------------------------------------------
#       main function
# ------------------------------------------------------------------------------

main() {
  print '\n'

  # ----  variables  -----------------------------------------------------------

  local browser_package='firefox'

  while [[ "$#" -gt 0 ]]; do
    case "$1" in
    --browser)
      if [[ -n "$2" ]]; then
        browser_package="$2"
        shift 2
      else
        print_error 'missing argument.\n\n'
        return 1
      fi
      ;;
    *)
      print_error 'invalid option.\n\n'
      return 1
      ;;
    esac
  done

  local packages=(
    "${BASE_PACKAGES[@]}"
    "${FONT_PACKAGES[@]}"
    "${HYPRLAND_PACKAGES[@]}"
    "${THEME_PACKAGES[@]}"
    "${browser_package}"
  )

  local install_osu=''
  local install_otd=''

  local user_services=(
    'hypridle.service'
    'hyprpaper.service'
    'hyprpolkitagent.service'
    'mako.service'
    'waybar.service'
    'xdg-user-dirs-update.service'
  )

  local keep_chezmoi=''

  # ----  checks  --------------------------------------------------------------

  if ! is_arch_linux; then
    print_error 'this script only supports arch linux.\n\n'
    return 1
  fi

  if is_root; then
    print_error 'this script must not be run as root.\n\n'
    return 1
  fi

  if ! is_package_available "${browser_package}"; then
    print_error "'${browser_package}' not found.\n\n"
    return 1
  fi

  # ----  input  ---------------------------------------------------------------

  install_osu="$(confirm 'install osu!(lazer)?')"
  install_otd="$(confirm 'install opentabletdriver?')"

  [[ "${install_otd}" == 'true' ]] && user_services+=("${OTD_SERVICE}")

  keep_chezmoi="$(confirm 'keep chezmoi (dotfile manager)?')"

  confirm 'proceed with installation?' >/dev/null || return

  # ----  installation  --------------------------------------------------------

  print_info 'disabling password prompt...\n\n'
  if ! disable_password_prompt; then
    print_error 'failed to disable password prompt.\n\n'
    return 1
  fi

  print_info 'installing packages...\n\n'
  if ! install_packages "${packages[@]}"; then
    print_error 'failed to install packages.\n\n'
    return 1
  fi

  if [[ "${install_osu}" == 'true' ]]; then
    print_info 'installing osu!(lazer)...\n\n'
    if ! install_aur_packages "${OSU_PACKAGES[@]}"; then
      print_error 'failed to install osu!(lazer).\n\n'
      return 1
    fi
  fi

  if [[ "${install_otd}" == 'true' ]]; then
    print_info 'installing opentabletdriver...\n\n'
    if ! install_aur_packages "${OTD_PACKAGE}"; then
      print_error 'failed to install opentabletdriver.\n\n'
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

  print_info 'enabling user services...\n\n'
  if ! enable_user_services "${user_services[@]}"; then
    print_error 'failed to enable user services.\n\n'
    return 1
  fi

  print_info 'applying dotfiles...\n\n'
  if ! apply_dotfiles; then
    print_error 'failed to apply dotfiles.\n\n'
    return 1
  fi

  if [[ "${keep_chezmoi}" == 'false' ]]; then
    print_info 'removing chezmoi...\n\n'
    if ! remove_chezmoi; then
      print_error 'failed to remove chezmoi.\n\n'
      return 1
    fi
  fi

  print_info 'enabling password prompt...\n\n'
  if ! enable_password_prompt; then
    print_error 'failed to enable password prompt.\n\n'
    return 1
  fi

  print_info 'installation completed.\n\n'
}

# ------------------------------------------------------------------------------
#       helper functions
# ------------------------------------------------------------------------------

is_arch_linux() {
  local line=''
  while read -r line; do
    [[ "${line}" == 'ID=arch' ]] && return 0
  done </etc/os-release

  return 1
}

is_root() {
  [[ "${EUID}" -eq 0 ]] || return 1
}

is_package_available() {
  local package="$1"

  local line=''
  while read -r line; do
    [[ "${line}" == "${package}" ]] && return 0
  done < <(pacman -Sqs "^${package}\$")

  return 1
}

is_package_installed() {
  local package="$1"

  local line=''
  while read -r line; do
    [[ "${line}" == "${package}" ]] && return 0
  done < <(pacman -Qqs "^${package}\$")

  return 1
}

download_build_files() {
  local package="$1"

  local build_files_directory=''
  local temporary_directory=''

  local curl_arguments=(
    '--location'
    '--output' "${package}.tar.gz"
    "https://aur.archlinux.org/cgit/aur.git/snapshot/${package}.tar.gz"
  )

  temporary_directory="$(mktemp --directory)" || return 1

  (
    cd "${temporary_directory}" || return 1

    local retries=0
    local max_retries=3
    local interval=5

    until curl "${curl_arguments[@]}" 2>/dev/null; do
      ((++retries > max_retries)) && return 1
      print_error 'failed to download file. retrying...\n\n'
      sleep "${interval}"
    done

    tar --extract --gzip --file "${package}.tar.gz" || return 1
  ) || return 1

  build_files_directory="${temporary_directory}/${package}"
  [[ ! -e "${build_files_directory}" ]] && return 1

  printf '%s' "${build_files_directory}"
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

# ------------------------------------------------------------------------------
#       input functions
# ------------------------------------------------------------------------------

scan() {
  local prompt="$1"
  local input=''

  print --color blue "${prompt}" >&2

  read -r input
  print '\n' >&2

  printf '%s' "${input}"
}

confirm() {
  local prompt="$1"
  local input=''

  while true; do
    input="$(scan "${prompt} [Y/n]: ")"

    if [[ -z "${input}" ]]; then
      printf 'true'
      return 0
    fi

    case "${input,,}" in
    y | yes)
      printf 'true'
      return 0
      ;;
    n | no)
      printf 'false'
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

disable_password_prompt() {
  local entry='Defaults:'"${USER}"' !authenticate'
  local config="/etc/sudoers.d/${USER}"

  # shellcheck disable=SC2064
  trap "sudo rm --force ${config}" EXIT || return 1
  printf '%s' "${entry}" | sudo tee "${config}" >/dev/null || return 1
  sudo chmod 0440 "/etc/sudoers.d/${USER}" || return 1
}

install_packages() {
  local packages=("$@")
  sudo pacman -S --noconfirm --needed "${packages[@]}" || return 1
}

install_aur_packages() {
  local packages=("$@")

  local build_files_directory=''
  local makepkg_options=(
    '--clean' '--force' '--install' '--rmdeps'
    '--syncdeps' '--noconfirm' '--needed'
  )

  if ! is_package_installed "${AUR_PREREQUISITE}" >/dev/null; then
    sudo pacman -S --noconfirm --needed "${AUR_PREREQUISITE}" || return 1
  fi

  local package=''
  for package in "${packages[@]}"; do
    build_files_directory="$(download_build_files "${package}")" || return 1
    (
      cd "${build_files_directory}" || return 1
      makepkg "${makepkg_options[@]}" || return 1
    ) || return 1
  done
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

enable_user_services() {
  local user_services=("$@")
  systemctl --user enable "${user_services[@]}" || return 1
}

apply_dotfiles() {
  chezmoi init --apply --force "${DOTFILES_REPOSITORY}" || return 1
}

remove_chezmoi() {
  chezmoi purge --force || return 1
  sudo pacman -Rns --noconfirm chezmoi || return 1
}

enable_password_prompt() {
  sudo rm --force "/etc/sudoers.d/${USER}" || return 1
  trap - EXIT || return 1
}

main "$@"
